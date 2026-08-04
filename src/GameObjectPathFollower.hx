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

/** An axis-angle rotation pair - see `GameObjectPathFollower.rotInterpolate`. Pure scratch (never
	escapes the function it's computed in), so instances are pooled into statics rather than
	allocated per call. */
@:structInit
class AxisAngle {
	public var axis:Vector;
	public var angle:Float;
}

/** Rewind snapshot of a path follower's progress - see `RewindFrame`/`RewindManager`. `active`
	replaces the old "the array slot itself is `null`" convention for "not currently on a path" -
	`RewindFrame.pathFollowerStates` now holds one always-non-null, reusable instance per mover
	(see [PQ Port Status](pq-port-status.md)'s rewind-optimization entry), so a mover coming on/off
	a path across frames doesn't need to allocate/discard the slot itself, just flip this flag. All
	fields default so a pooled instance can be constructed once with `new PathFollowerSaveState()`
	and filled in later via `fillState`. */
@:structInit
class PathFollowerSaveState {
	public var active:Bool = false;
	public var pathPosition:Float = 0;
	public var currentNode:String = "";
	public var prevNode:String = "";
	public var rngCursor:Int = 0;

	public function new() {}
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
		this.currentNodeName = firstNodeName.toLowerCase();
		this.prevNodeName = firstNodeName.toLowerCase();
		this.rngCursor = Std.random(256);

		var s = evaluateTransform(this.currentNodeName, this.prevNodeName, 0);
		if (s != null) {
			this.frameStartState = s;
			this.frameEndState = s;
			applyState(s.position, s.rotation, s.scale);
		}
	}

	/** Snapshot used by rewind - see `RewindFrame`/`RewindManager`. Mutates a pooled instance in
		place (rather than allocating a fresh one every tick) since `RewindManager.recordFrame` keeps
		one persistent `PathFollowerSaveState` per mover. */
	public function fillState(s:PathFollowerSaveState) {
		s.active = true;
		s.pathPosition = this.pathPosition;
		s.currentNode = this.currentNodeName;
		s.prevNode = this.prevNodeName;
		s.rngCursor = this.rngCursor;
	}

	public function setState(s:PathFollowerSaveState) {
		this.pathPosition = s.pathPosition;
		this.currentNodeName = s.currentNode;
		this.prevNodeName = s.prevNode;
		this.rngCursor = s.rngCursor;
		// Re-derive the transform for the restored path position and collapse the frame blend, so the
		// object snaps straight to where the rewound-to state puts it instead of continuing to
		// interpolate toward a frame-end computed before the jump.
		var state = evaluateTransform(this.currentNodeName, this.prevNodeName, this.pathPosition);
		if (state != null) {
			this.frameStartState = state;
			this.frameEndState = state;
			this.substepAccum = 0;
			this.frameDuration = 0;
			applyState(state.position, state.rotation, state.scale);
		}
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
		pos.w = 1;
		scale.w = 1;

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
		// fix this weird shit
		pos.w = 1;
		scale.w = 1;

		return {position: pos, rotation: rot, scale: scale};
	}

	// Pure scratch for the rotational-velocity computation below - all data extracted from these
	// (angle/axis) is copied into local floats/Vectors before the function returns.
	static var scratchStartMat = new Matrix();
	static var scratchStartMatInv = new Matrix();
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
			// Reversed multiply order vs the C++ - see `rotInterpolate`'s doc comment for why
			// (Torque column-vector vs h3d row-vector convention).
			if (node.rotationOffset != null)
				scratchEndMat.multiply(node.rotationOffset, scratchEndMat);

			scratchStartMat.getInverse(scratchStartMatInv);
			scratchMatSub.multiply(scratchStartMatInv, scratchEndMat);
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
			// PQ computes `rotM * finalRotOffset` under Torque's column-vector (M*p) convention,
			// where that means "apply finalRotOffset first, then rotM". h3d.Matrix is row-vector
			// (p*M) - see `rotInterpolate`'s doc comment - so the equivalent composition needs the
			// arguments reversed.
			rotMat.multiply(node.rotationOffset, rotMat);
			var q = new Quat();
			q.initRotateMatrix(rotMat);
			return q;
		}
		return rot;
	}

	static var scratchRotMat1 = new Matrix();
	static var scratchRotMat1Inv = new Matrix();
	static var scratchRotMat2 = new Matrix();
	static var scratchRotMatSub = new Matrix();
	static var scratchRotDeltaMat = new Matrix();
	static var scratchRotComposedMat = new Matrix();
	static var scratchRotFinalMat = new Matrix();
	static var scratchRotExtractQuat = new Quat();
	static var scratchRotDelta:AxisAngle = {axis: new Vector(), angle: 0};
	static var scratchRotFinal:AxisAngle = {axis: new Vector(), angle: 0};

	/** Extracts an (axis, angle) pair from a rotation matrix via its quaternion, matching Torque's
		`AngAxisF(const MatrixF&)` constructor closely enough to reproduce `RotInterpolate`'s
		re-decomposition step (see `rotInterpolate`'s doc comment). Fills `out` in place.

		Known unresolved issue: a rotation of exactly 180 degrees has no unique axis (`R(a, 180) ==
		R(-a, 180)`), and which of the two `Quat.initRotateMatrix`'s Shepperd extraction picks isn't
		guaranteed to match the direction a node chain's neighboring segments are travelling in - this
		is the cause of a see-saw/reversal on node loops whose cumulative rotation passes through
		exactly 180 degrees (e.g. a 0/90/180-degree three-node chain). A per-segment sign correction
		was attempted and reverted - it fixed the ambiguous segment but flipped the direction of every
		other (unambiguous) segment too, so whatever's actually driving direction here isn't fully
		understood yet. Left as-is pending a real fix. */
	function axisAngleFromMatrix(mat:Matrix, out:AxisAngle) {
		var q = scratchRotExtractQuat;
		q.initRotateMatrix(mat);
		if (q.w > 1)
			q.normalize();
		var angle = 2 * Math.acos(q.w);
		var s = Math.sqrt(q.x * q.x + q.y * q.y + q.z * q.z);
		if (s == 0.0)
			out.axis.set(1, 0, 0);
		else
			out.axis.set(q.x / s, q.y / s, q.z / s);
		out.angle = angle;
	}

	/** Ported from PQ's `RotInterpolate` (`MathLib.h`). Bug-for-bug faithful: `RotInterpolate` itself
		scales the delta (rot1->rot2) angle by `t` and composes it onto rot1's matrix, but then
		RE-DECOMPOSES that absolute composed matrix into a fresh (axis, angle) pair - it's this
		fresh pair, not the original delta, that `RotationMultiplier` scales in
		`Node_getPathRotation`, and the result is rebuilt as a matrix from identity rather than
		composed onto rot1 again. Collapsing this into a single "scale delta angle by t*multiplier"
		step (as an earlier version of this port did) is NOT equivalent once multiplier != 1.

		Also critically: Torque's `MatrixF` is column-vector (`mulP` does `M*p`), where `X * Y`
		composed onto a point means "apply Y first, then X". `h3d.Matrix` is row-vector
		(`Matrix.hx`'s point-transform does `p*M`), where `multiply(A, B)` composed onto a point
		means "apply A first, then B" - the OPPOSITE order. For the same physical rotation,
		heapsMatrix == torqueMatrix transposed, and `(X*Y)^T == Y^T*X^T`, so every multiply() call
		here must take its arguments in the REVERSE order of the corresponding C++ expression, not
		the same order. Preserving the C++ argument order verbatim (as an earlier version of this
		port did) silently computes the wrong composed rotation whenever rot1/rot2 aren't about the
		same axis - this was the cause of reversed rotation direction on two-node setups where the
		nodes' rotations aren't about a common axis.

		Separately, a delta rotation of exactly 180 degrees has an ambiguous axis sign that has to be
		resolved against this engine's mirrored X axis rather than Torque's - see
		`axisAngleFromMatrix`'s doc comment. That ambiguity, not the multiply order above, is what
		caused the "rotates all the way around, then see-saws back" bug on node loops like 0/90/180. */
	function rotInterpolate(rot1:Quat, rot2:Quat, t:Float, multiplier:Float = 1.0):Quat {
		var mat1 = scratchRotMat1;
		var mat2 = scratchRotMat2;
		rot1.toMatrix(mat1);
		rot2.toMatrix(mat2);

		// C++: matSub = mat2 * inverse(mat1) -> reversed here: inverse(mat1) * mat2.
		var matSub = scratchRotMatSub;
		mat1.getInverse(scratchRotMat1Inv);
		matSub.multiply(scratchRotMat1Inv, mat2);

		var delta = scratchRotDelta;
		axisAngleFromMatrix(matSub, delta);

		delta.angle *= t;

		// C++: newMat = a.toMatrix() * mat1 -> reversed here: mat1 * a.toMatrix().
		var deltaMat = scratchRotDeltaMat;
		deltaMat.initRotationAxis(delta.axis, delta.angle);
		var composedMat = scratchRotComposedMat;
		composedMat.multiply(mat1, deltaMat);

		var finalAA = scratchRotFinal;
		axisAngleFromMatrix(composedMat, finalAA);
		finalAA.angle *= multiplier;

		var finalMat = scratchRotFinalMat;
		finalMat.initRotationAxis(finalAA.axis, finalAA.angle);
		// This Quat escapes into PathFollowerState (frameStartState/frameEndState), which needs two
		// independent live instances at once - must NOT be a pooled scratch, unlike everything above.
		var retQuat = new Quat();
		retQuat.initRotateMatrix(finalMat);
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
