package src;

import h3d.Vector;
import h3d.Matrix;
import h3d.Quat;
import src.MarbleWorld;
import src.GameObject;
import src.PathNodeElement;
import src.PathNodeElement.PathNodeLiveTransform;
import src.Marble;

/** Position/rotation/scale snapshot at a point along the path - see `GameObjectPathFollower`'s
	`frameStartState`/`frameEndState`. Two independent instances must be alive at once (the frame's
	start and end), so unlike pure-scratch matrices this can't be pooled into a single static. */
@:structInit
class PathFollowerState {
	public var position:Vector;
	public var rotation:Quat;
	public var scale:Vector;
}

/** Rewind snapshot of a path follower's progress - see `RewindFrame`/`RewindManager`. */
@:structInit
class PathFollowerSaveState {
	public var pathPosition:Float;
	public var currentNode:String;
	public var prevNode:String;
	public var rngCursor:Int;
}

/** Walks a `PathNode` chain and drives a `GameObject`'s transform along it. Ported from PQ's
	`SceneObject::moveOnPath`/`updatePathPosition` (`platinum/server/scripts/moving.cs`) for the
	state machine/sequencing (accumulate elapsed time, loop node-to-node transitions within a
	single frame, branch-node RNG cursor that only advances on leaving a branching node), and from
	`hrt.prefab.props.PathNodeAnimator` for the underlying interpolation math (linear/quadratic-
	bezier/cubic-bezier position blend, rotation slerp-like blend, per-node smoothing curve).

	Two-phase like `PathedInterior`: `computeNextStep` runs once per frame (steps the state
	machine, computes the transform at the start and end of this frame), `advance` runs once per
	physics substep (blends between those two transforms proportionally to how much of the frame
	has elapsed) so collision stays correct at substep granularity. */
class GameObjectPathFollower {
	var obj:GameObject;
	var level:MarbleWorld;

	var currentNodeName:String;
	var prevNodeName:String;
	var pathPosition:Float = 0;
	var rngCursor:Int;
	var ended:Bool = false;

	var frameStartState:PathFollowerState;
	var frameEndState:PathFollowerState;
	var frameDuration:Float = 0;
	var substepAccum:Float = 0;

	public function new(obj:GameObject, firstNodeName:String, level:MarbleWorld) {
		this.obj = obj;
		this.level = level;
		this.currentNodeName = firstNodeName;
		this.prevNodeName = firstNodeName;
		this.rngCursor = Std.random(256);

		var s = evaluateTransform(this.currentNodeName, this.prevNodeName, 0);
		if (s != null) {
			this.frameStartState = s;
			this.frameEndState = s;
			applyState(s.position, s.rotation, s.scale);
		}
	}

	/** Snapshot used by rewind - see `RewindFrame`/`RewindManager`. */
	public function getState():PathFollowerSaveState {
		return {
			pathPosition: this.pathPosition,
			currentNode: this.currentNodeName,
			prevNode: this.prevNodeName,
			rngCursor: this.rngCursor
		};
	}

	public function setState(s:PathFollowerSaveState) {
		this.pathPosition = s.pathPosition;
		this.currentNodeName = s.currentNode;
		this.prevNodeName = s.prevNode;
		this.rngCursor = s.rngCursor;
		var state = evaluateTransform(this.currentNodeName, this.prevNodeName, this.pathPosition);
		if (state != null) {
			this.frameStartState = state;
			this.frameEndState = state;
			this.substepAccum = 0;
			this.frameDuration = 0;
			applyState(state.position, state.rotation, state.scale);
		}
	}

	public function reset() {
		this.pathPosition = 0;
		this.ended = false;
	}

	function getNode(name:String):PathNodeElement {
		return this.level.pathNodes.get(name);
	}

	function pickNextNode(node:PathNodeElement):String {
		if (node.branchNodes.length > 0) {
			var idx = this.rngCursor % node.branchNodes.length;
			return node.branchNodes[idx];
		}
		return node.nextNode;
	}

	function getPathTime(node:PathNodeElement):Float {
		if (node == null)
			return 0;
		if (node.speed > 0 && !node.isBezier) {
			var nextName = pickNextNode(node);
			var next = nextName != null && nextName != "" ? getNode(nextName) : null;
			if (next == null)
				return node.delay;
			var nodeT = this.level.resolvePathNodeTransform(node.name);
			var nextT = this.level.resolvePathNodeTransform(nextName);
			var distance = nextT.position.sub(nodeT.position).length();
			return node.delay + (distance / node.speed);
		}
		return node.delay + node.timeToNext;
	}

	public function computeNextPathStep(dt:Float) {
		if (this.ended)
			return;

		this.frameStartState = evaluateTransform(this.currentNodeName, this.prevNodeName, this.pathPosition);

		this.pathPosition += dt;

		var node = getNode(this.currentNodeName);
		var segmentTime = getPathTime(node);

		while (node != null && this.pathPosition > segmentTime) {
			this.pathPosition -= segmentTime;

			var nextName = pickNextNode(node);
			var next = nextName != null && nextName != "" ? getNode(nextName) : null;

			if (node.isBranching())
				this.rngCursor = (this.rngCursor + 1) % 256;

			this.prevNodeName = this.currentNodeName;
			if (next == null || nextName == this.currentNodeName) {
				// Dead end / self-loop - stop advancing, matching moving.cs's break condition.
				this.ended = true;
				break;
			}
			this.currentNodeName = nextName;
			node = next;
			segmentTime = getPathTime(node);
		}

		this.frameEndState = evaluateTransform(this.currentNodeName, this.prevNodeName, this.pathPosition);
		this.frameDuration = dt;
		this.substepAccum = 0;
	}

	// Pure scratch - consumed and passed to `obj.setTransform` (which copies out of it) before
	// returning, so it's safe to share a single reusable instance across every substep/call.
	static var scratchApplyMat = new Matrix();
	static var scratchApplyRotMat = new Matrix();
	static var scratchBlendRot = new Quat();

	public function advancePath(timeStep:Float) {
		if (this.frameStartState == null || this.frameEndState == null)
			return;
		this.substepAccum += timeStep;
		var t = this.frameDuration > 0 ? hxd.Math.clamp(this.substepAccum / this.frameDuration, 0, 1) : 1;

		// Blend position/rotation/scale as separate components (not by decomposing a combined
		// scale*rotation Matrix back into a quaternion - Quat.initRotateMatrix assumes a pure
		// rotation matrix, so feeding it a matrix with scale baked in silently produces a wrong
		// rotation whenever scale != 1, which visibly skews the object away from its actual pivot).
		scratchBlendRot.slerp(this.frameStartState.rotation, this.frameEndState.rotation, t);
		var pos = lerpVector(this.frameStartState.position, this.frameEndState.position, t);
		var scale = lerpVector(this.frameStartState.scale, this.frameEndState.scale, t);

		applyState(pos, scratchBlendRot, scale);
	}

	function applyState(position:Vector, rotation:Quat, scale:Vector) {
		// position/rotation/scale here are world-space (see evaluateTransform) - setTransform
		// expects a transform local to the object's scene parent, so convert like
		// PathNodeAnimator.updateObjPosition does (`tform.multiply(tform, invTform)`).
		scratchApplyMat.initScale(scale.x, scale.y, scale.z);
		rotation.toMatrix(scratchApplyRotMat);
		scratchApplyMat.multiply3x4(scratchApplyMat, scratchApplyRotMat);
		scratchApplyMat.setPosition(position);
		// if (this.obj.parent != null)
		// 	scratchApplyMat.multiply(scratchApplyMat, this.obj.parent.getInvPos());
		this.obj.setTransform(scratchApplyMat);
	}

	function evaluateTransform(nodeName:String, prevNodeName:String, position:Float):PathFollowerState {
		var node = getNode(nodeName);
		if (node == null)
			return null;

		var nextName = pickNextNode(node);
		var next = nextName != null && nextName != "" ? getNode(nextName) : node;
		if (next == null)
			next = node;

		var nodeDelay = node.delay;
		var localT = 0.0;
		if (nodeDelay != 0 && position < nodeDelay) {
			localT = 0;
		} else {
			var p = position - nodeDelay;
			var segTime = getPathTime(node) - nodeDelay;
			localT = hxd.Math.clamp(segTime != 0 ? p / segTime : 1, 0, 1);
		}

		var adjustedT = getAdjustedProgress(node, localT);

		var nodeT = this.level.resolvePathNodeTransform(nodeName);
		var nextT = this.level.resolvePathNodeTransform(next.name);
		if (nodeT == null)
			return null;
		if (nextT == null)
			nextT = nodeT;

		// PQ's own Node_updatePath (interpolation.cpp) starts from the OBJECT's own current
		// transform and only overwrites the axes actually in use - `UsePosition`/`UseRotation`
		// false means that axis is left exactly as it already was (which for most objects is
		// their originally-placed transform, since nothing else touches it once path-following
		// takes over), NOT the guide node's own position/rotation (the node is just a gizmo,
		// its own transform is meaningless to an object that isn't using that axis).
		var basePos = new Vector(this.obj.x, this.obj.y, this.obj.z);
		var baseRot = this.obj.getRotationQuat();
		var baseScale = new Vector(this.obj.scaleX, this.obj.scaleY, this.obj.scaleZ);

		var pos = node.usePosition ? getPathPosition(node, nodeT, next, nextT, prevNodeName, adjustedT) : basePos;
		var rot = node.useRotation ? getPathRotation(node, nodeT, next, nextT, localT, adjustedT) : baseRot;
		var scale = node.useScale ? lerpVector(node.localScale, next.localScale, adjustedT) : baseScale;

		return {position: pos, rotation: rot, scale: scale};
	}

	// Pure scratch for the rotational-velocity computation below - all data extracted from these
	// (angle/axis) is copied into local floats/Vectors before the function returns.
	static var scratchStartMat = new Matrix();
	static var scratchEndMat = new Matrix();
	static var scratchMatSub = new Matrix();
	static var scratchVelQuat = new Quat();

	/** Per-contact-point velocity for marble collision response, ported from PQ's
		`getSurfaceVelocityForSceneObject` (`interpolation.cpp`) - unlike `PathedInterior`'s flat
		per-object velocity, PQ computes translational + rotational + scaling contributions at the
		exact contact point, since PathNode-driven objects can rotate/scale (a spinning or growing
		platform pushes a marble standing off-center differently than one at its pivot). Uses the
		*current* authoritative path state (`pathPosition`/`currentNodeName`), not the
		frame-start/frame-end blend used for rendering/collision-shape placement. */
	public function getSurfaceVelocity(point:Vector, marble:Marble, dt:Float):Vector {
		var node = getNode(this.currentNodeName);
		if (node == null)
			return new Vector();

		var nextName = pickNextNode(node);
		var next = nextName != null && nextName != "" ? getNode(nextName) : node;
		if (next == null || next == node)
			return new Vector();

		var delay = node.delay;
		var pathTime = getPathTime(node);
		var timeDelta = pathTime - delay;
		if (timeDelta == 0)
			return new Vector();

		var position = this.pathPosition + dt;
		var t:Float;
		if (delay != 0 && position < delay) {
			t = 0;
		} else {
			position -= delay;
			t = hxd.Math.clamp(position / Math.max(timeDelta, 0.001), 0, 1);
		}

		var easedT = getAdjustedProgress(node, t);
		var easeDeriv = getAdjustedProgressDeriv(node, t);

		var nodeT = this.level.resolvePathNodeTransform(node.name);
		var nextT = this.level.resolvePathNodeTransform(next.name);
		var center = this.obj.getAbsPos().getPosition();

		var transVel = new Vector();
		if (node.usePosition) {
			var pointList = getPointList(node, nodeT, next, nextT, this.prevNodeName);
			transVel = interpolateDeriv(pointList, easedT).multiply(easeDeriv / timeDelta);
		}

		var rotVel = new Vector();
		if (node.useRotation) {
			var tRot = node.reverseRotation ? 1.0 - t : t;
			nodeT.rotation.toMatrix(scratchStartMat);
			nextT.rotation.toMatrix(scratchEndMat);
			if (node.rotationOffset != null)
				scratchEndMat.multiply(scratchEndMat, node.rotationOffset);

			scratchMatSub.multiply(scratchEndMat, scratchStartMat.getInverse());
			var q = scratchVelQuat;
			q.initRotateMatrix(scratchMatSub);
			if (q.w > 1)
				q.normalize();
			var angle = 2 * Math.acos(q.w);
			var s = Math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z);
			var axis = s == 0 ? new Vector(1, 0, 0) : new Vector(q.x / s, q.y / s, q.z / s);

			angle /= timeDelta;
			if (node.reverseRotation)
				angle *= -1;
			angle *= getAdjustedProgressDeriv(node, tRot);
			angle *= node.rotationMultiplier;

			if (angle != 0) {
				var off = point.sub(center);
				var alongAxis = axis.multiply(off.dot(axis));
				var perp = off.sub(alongAxis);
				var offLen = perp.length();

				var dist = point.sub(marble.getAbsPos().getPosition()).length();
				var mult = hxd.Math.clamp(marble._radius / Math.max(dist, 0.001), 1, 2);

				var velDir = off.cross(axis);
				velDir.normalize();
				var speed = angle * offLen * mult;
				rotVel = velDir.multiply(-speed);
			}
		}

		var scaleVel = new Vector();
		if (node.useScale) {
			var startScale = node.localScale;
			var endScale = next.localScale;
			var scaleDelta = endScale.sub(startScale);
			var scaleRate = scaleDelta.multiply(easeDeriv / timeDelta);
			var off = point.sub(center);
			var currentScale = lerpVector(startScale, endScale, easedT);
			scaleVel = new Vector((scaleRate.x / Math.max(currentScale.x, 0.001)) * off.x, (scaleRate.y / Math.max(currentScale.y, 0.001)) * off.y,
				(scaleRate.z / Math.max(currentScale.z, 0.001)) * off.z);
		}

		return transVel.add(rotVel).add(scaleVel);
	}

	function getAdjustedProgress(node:PathNodeElement, t:Float):Float {
		if (node.smooth || (t <= 0.5 && node.smoothStart) || (t > 0.5 && node.smoothEnd))
			return -0.5 * Math.cos(t * Math.PI) + 0.5;
		return t;
	}

	/** Derivative (w.r.t. `t`) of `getAdjustedProgress`'s smoothing curve - used by
		`getSurfaceVelocity`'s chain rule, matching `Node_getAdjustedProgressDeriv`. */
	function getAdjustedProgressDeriv(node:PathNodeElement, t:Float):Float {
		if (node.smooth || (t <= 0.5 && node.smoothStart) || (t > 0.5 && node.smoothEnd))
			return 0.5 * Math.PI * Math.sin(t * Math.PI);
		return 1.0;
	}

	function getPathPosition(node:PathNodeElement, nodeT:PathNodeLiveTransform, next:PathNodeElement, nextT:PathNodeLiveTransform, prevNodeName:String,
			t:Float):Vector {
		var pointList = getPointList(node, nodeT, next, nextT, prevNodeName);
		return interpolate(pointList, t);
	}

	function getPointList(node:PathNodeElement, nodeT:PathNodeLiveTransform, next:PathNodeElement, nextT:PathNodeLiveTransform,
			prevNodeName:String):Array<Vector> {
		var startPos = nodeT.position;
		var endPos = nextT.position;

		var pointList = [startPos];

		var bezierHandle1Pos:Vector = null;
		if (node.isBezier && node.bezierHandle2 != null && node.bezierHandle2 != "") {
			var h = this.level.resolvePathNodeTransform(node.bezierHandle2);
			if (h != null)
				bezierHandle1Pos = h.position;
		}

		if (bezierHandle1Pos != null) {
			pointList.push(bezierHandle1Pos);
		} else if (node.isSpline) {
			var prevNode = prevNodeName != null ? getNode(prevNodeName) : null;
			if (prevNode != null && prevNode != node) {
				var prevT = this.level.resolvePathNodeTransform(prevNodeName);
				var time = getPathTime(node);
				var prevTime = getPathTime(prevNode);
				var dist = (startPos.distance(prevT.position) / 3.0) * (Math.max(time, 1) / Math.max(prevTime, 1));
				var sub = endPos.sub(prevT.position);
				sub.normalize();
				pointList.push(startPos.add(sub.multiply(dist)));
			}
		}

		var nextNextName = next.nextNode;
		var bezierHandle2Pos:Vector = null;
		if (next.isBezier && next.bezierHandle1 != null && next.bezierHandle1 != "") {
			var h = this.level.resolvePathNodeTransform(next.bezierHandle1);
			if (h != null)
				bezierHandle2Pos = h.position;
		}

		if (bezierHandle2Pos != null) {
			pointList.push(bezierHandle2Pos);
		} else if (next.isSpline && nextNextName != null && nextNextName != "") {
			var nextNextT = this.level.resolvePathNodeTransform(nextNextName);
			if (nextNextT != null) {
				var dist = endPos.distance(startPos) / 3.0;
				var sub = nextNextT.position.sub(startPos);
				sub.normalize();
				pointList.push(endPos.sub(sub.multiply(dist)));
			}
		}

		pointList.push(endPos);
		return pointList;
	}

	function getPathRotation(node:PathNodeElement, nodeT:PathNodeLiveTransform, next:PathNodeElement, nextT:PathNodeLiveTransform, t:Float,
			adjustedT:Float):Quat {
		if (next == node)
			return nodeT.rotation;

		var tt = node.reverseRotation ? 1.0 - t : t;
		var rot = rotInterpolate(nodeT.rotation, nextT.rotation, getAdjustedProgress(node, tt), node.rotationMultiplier);

		if (node.rotationOffset != null) {
			var rotMat = new Matrix();
			rot.toMatrix(rotMat);
			rotMat.multiply(rotMat, node.rotationOffset);
			var q = new Quat();
			q.initRotateMatrix(rotMat);
			return q;
		}
		return rot;
	}

	function rotInterpolate(rot1:Quat, rot2:Quat, t:Float, multiplier:Float = 1.0):Quat {
		var mat1 = new Matrix();
		var mat2 = new Matrix();
		rot1.toMatrix(mat1);
		rot2.toMatrix(mat2);

		var matSub = new Matrix();
		matSub.multiply(mat2, mat1.getInverse());

		var q = new Quat();
		q.initRotateMatrix(matSub);
		if (q.w > 1)
			q.normalize();
		var angle = 2 * Math.acos(q.w);
		angle *= t * multiplier;

		var s = Math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z);
		var x, y, z;
		if (s == 0.0) {
			x = 1.0;
			y = 0.0;
			z = 0.0;
		} else {
			x = q.x / s;
			y = q.y / s;
			z = q.z / s;
		}

		var retMat = new Matrix();
		retMat.initRotationAxis(new Vector(x, y, z), angle);
		retMat.multiply(retMat, mat1);
		var retQuat = new Quat();
		retQuat.initRotateMatrix(retMat);
		return retQuat;
	}

	function lerpVector(a:Vector, b:Vector, t:Float):Vector {
		return a.multiply(1 - t).add(b.multiply(t));
	}

	function interpolate(pointList:Array<Vector>, t:Float):Vector {
		if (pointList.length == 2)
			return lerpVector(pointList[0], pointList[1], t);
		if (pointList.length == 3)
			return quadraticBezier(pointList[0], pointList[1], pointList[2], t);
		if (pointList.length == 4)
			return cubicBezier(pointList[0], pointList[1], pointList[2], pointList[3], t);
		return pointList[0];
	}

	function quadraticBezier(p0:Vector, p1:Vector, p2:Vector, t:Float):Vector {
		return p0.multiply((1 - t) * (1 - t)).add(p1.multiply(t * 2 * (1 - t))).add(p2.multiply(t * t));
	}

	function cubicBezier(p0:Vector, p1:Vector, p2:Vector, p3:Vector, t:Float):Vector {
		return p0.multiply((1 - t) * (1 - t) * (1 - t))
			.add(p1.multiply(t * 3 * (1 - t) * (1 - t)))
			.add(p2.multiply(t * t * 3 * (1 - t)))
			.add(p3.multiply(t * t * t));
	}

	/** Derivative (w.r.t. `t`) of `interpolate` - used by `getSurfaceVelocity` (`VectorBezierDeriv`
		in PQ's `interpolation.cpp`). */
	function interpolateDeriv(pointList:Array<Vector>, t:Float):Vector {
		if (pointList.length == 2)
			return pointList[1].sub(pointList[0]);
		if (pointList.length == 3)
			return quadraticBezierDeriv(pointList[0], pointList[1], pointList[2], t);
		if (pointList.length == 4)
			return cubicBezierDeriv(pointList[0], pointList[1], pointList[2], pointList[3], t);
		return new Vector();
	}

	function quadraticBezierDeriv(p0:Vector, p1:Vector, p2:Vector, t:Float):Vector {
		return p1.sub(p0).multiply(2 * (1 - t)).add(p2.sub(p1).multiply(2 * t));
	}

	function cubicBezierDeriv(p0:Vector, p1:Vector, p2:Vector, p3:Vector, t:Float):Vector {
		return p1.sub(p0)
			.multiply(3 * (1 - t) * (1 - t))
			.add(p2.sub(p1).multiply(6 * (1 - t) * t))
			.add(p3.sub(p2).multiply(3 * t * t));
	}
}
