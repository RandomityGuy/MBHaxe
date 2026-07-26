package src;

import h3d.Matrix;
import src.TimeState;
import collision.CollisionInfo;
import h3d.scene.Object;
import h3d.Vector;
import src.Resource;
import h3d.mat.Texture;
import hxd.res.Sound;
import src.Marble;
import mis.MissionElement.IPlaceableElement;
import src.IPathMover;
import src.GameObjectPathFollower;
import src.GameObjectParentFollower;
import src.MarbleWorld;

class GameObject extends Object implements IPathMover {
	public var identifier:String;

	public var currentOpacity:Float = 1;
	public var isCollideable:Bool = false;
	public var isBoundingBoxCollideable:Bool = false;
	public var enableCollideCallbacks:Bool = false;

	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	public var pathFollower:GameObjectPathFollower;
	public var parentFollower:GameObjectParentFollower;

	var pathInitialTransform:Matrix;
	var pathFirstNodeName:String;
	var pathLevel:MarbleWorld;

	/** True only when this object's `path` field placed it on a path from the start (always
		path-following for the whole mission) - as opposed to a `PathTrigger`/`gotoTarget` having
		called `moveOnPath` on it later. Distinguishes the two cases on a full mission restart (see
		`resetForRestart`): a `path`-field object should go back to the *start* of its path (it's
		always supposed to be on it), while a trigger-activated one should come fully OFF the path,
		back to its original placement, matching a level that just (re)loaded. */
	var pathFromField:Bool = false;

	/** Called once at construction (mirrors PQ's `SimGroup::findMovingObjects`/
		`findParentedObjects` at mission load, `platinum/server/scripts/moving.cs`): a `parent`
		field wins outright over a `path` field for this object's own behavior if both are somehow
		present, matching PQ never running both animators on one object at once. A parented object
		can still be the *target* other objects path-follow toward or parent onto, and the parent
		itself can independently be a path-follower - this exclusivity is purely about this
		object's own movement, not a restriction on the overall chain. */
	public function initPathAndParent(element:IPlaceableElement, level:MarbleWorld) {
		var parentField = element.fields.get("parent");
		if (parentField != null && parentField[0] != "") {
			this.parentFollower = new GameObjectParentFollower(this, element, level);
			level.registerParentedObject(this);
			return;
		}
		var pathField = element.fields.get("path");
		if (pathField != null && pathField[0] != "") {
			this.moveOnPath(pathField[0], level);
			this.pathFromField = true;
		}
	}

	/** Runtime-callable, mirrors `SceneObject::moveOnPath(%firstNode)` exactly - `PathTrigger`
		calls this directly to (re)assign a path at any time, not just at load time. */
	public function moveOnPath(firstNodeName:String, level:MarbleWorld) {
		if (this.pathInitialTransform == null) {
			this.pathInitialTransform = this.getTransform().clone();
			this.pathFirstNodeName = firstNodeName;
			this.pathLevel = level;
		}
		this.pathFollower = new GameObjectPathFollower(this, firstNodeName, level);
		level.registerMovingObject(this);
	}

	/** Resets back to the very first node this object was ever put on the path at (not just the
		start of whatever segment it's currently mid-way through) - rebuilds the follower fresh
		rather than trying to rewind its `currentNode`/`prevNode`/`rngCursor` in place, since that's
		exactly what constructing a new one from `pathFirstNodeName` already does correctly. */
	public function resetPath() {
		if (this.pathFollower == null || this.pathInitialTransform == null)
			return;
		this.setTransform(this.pathInitialTransform);
		this.pathFollower = new GameObjectPathFollower(this, this.pathFirstNodeName, this.pathLevel);
	}

	/** Fully removes this object from its path (as opposed to `resetPath`, which keeps it on the
		path but rewinds progress to the start) and snaps it back to its originally-placed transform
		- used by `RewindManager.applyFrame` when rewinding to before a `PathTrigger`/button ever
		called `moveOnPath` on this object in the first place, so it correctly un-triggers instead of
		staying stuck on the path it was only ever put on by forward gameplay. */
	public function deactivatePath() {
		if (this.pathFollower == null)
			return;
		if (this.pathInitialTransform != null) {
			this.setTransform(this.pathInitialTransform);
		}
		this.pathFollower = null;
	}

	public function computeNextPathStep(dt:Float) {
		if (pathFollower != null)
			pathFollower.computeNextPathStep(dt);
	}

	public function advancePath(timeStep:Float) {
		if (pathFollower != null)
			pathFollower.advancePath(timeStep);
	}

	public function advanceParent() {
		if (parentFollower != null)
			parentFollower.advance();
	}

	public function hasMover():Bool {
		return pathFollower != null || parentFollower != null;
	}

	/** Per-contact-point velocity for marble collision response, ported from PQ's
		`getSurfaceVelocityForSceneObject` (`interpolation.cpp`) - a parented object has no
		velocity of its own (it's a pure snap-to-parent), so PQ recurses to the parent's own
		surface velocity at the same point; a path-following object computes translational/
		rotational/scaling contributions at `point` (see `GameObjectPathFollower.getSurfaceVelocity`). */
	public function getSurfaceVelocity(point:Vector, marble:Marble, dt:Float):Vector {
		if (parentFollower != null && parentFollower.parentObject != null)
			return parentFollower.parentObject.getSurfaceVelocity(point, marble, dt);
		if (pathFollower != null)
			return pathFollower.getSurfaceVelocity(point, marble, dt);
		return new Vector();
	}

	public function onMarbleContact(marble:Marble, time:TimeState, ?contact:CollisionInfo) {}

	public function onMarbleInside(marble:Marble, time:TimeState) {}

	public function onMarbleEnter(marble:Marble, time:TimeState) {}

	public function onMarbleLeave(marble:Marble, time:TimeState) {}

	public function onLevelStart() {}

	public function reset() {
		if (this.pathFollower == null)
			return;
		if (this.pathFromField)
			this.resetPath();
		else
			this.deactivatePath();
	}

	public function dispose() {
		for (textureResource in textureResources) {
			textureResource.release();
		}
		for (audioResource in soundResources) {
			audioResource.release();
		}
	}
}
