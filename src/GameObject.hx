package src;

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

	/** Key used by `InstanceManager` to decide whether two objects share an instanced mesh
		batch. Must be unique per distinct geometry. Defaults to `identifier` if unset, but
		`identifier` is also used elsewhere as a coarser gameplay/material category tag (e.g.
		HUD powerup icon lookup, `== "Tornado"` material quirks) that deliberately stays the
		same across reskins with different meshes — so those two purposes can't share one
		field. `MarbleWorld.addDtsObject` sets this to `dtsPath` automatically. */
	public var instancingKey:String;

	public var currentOpacity:Float = 1;
	public var isCollideable:Bool = false;
	public var isBoundingBoxCollideable:Bool = false;
	public var enableCollideCallbacks:Bool = false;

	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	public var pathFollower:GameObjectPathFollower;
	public var parentFollower:GameObjectParentFollower;

	var pathInitialPosition:Vector;
	var pathInitialScale:Vector;

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
		if (pathField != null && pathField[0] != "")
			this.moveOnPath(pathField[0], level);
	}

	/** Runtime-callable, mirrors `SceneObject::moveOnPath(%firstNode)` exactly - `PathTrigger`
		calls this directly to (re)assign a path at any time, not just at load time. */
	public function moveOnPath(firstNodeName:String, level:MarbleWorld) {
		if (this.pathInitialPosition == null) {
			this.pathInitialPosition = this.getTransform().getPosition().clone();
			this.pathInitialScale = new Vector(this.scaleX, this.scaleY, this.scaleZ);
		}
		this.pathFollower = new GameObjectPathFollower(this, firstNodeName, level);
		level.registerMovingObject(this);
	}

	public function resetPath() {
		if (this.pathFollower == null || this.pathInitialPosition == null)
			return;
		this.setPosition(pathInitialPosition.x, pathInitialPosition.y, pathInitialPosition.z);
		this.scaleX = pathInitialScale.x;
		this.scaleY = pathInitialScale.y;
		this.scaleZ = pathInitialScale.z;
		this.pathFollower.reset();
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

	public function reset() {}

	public function dispose() {
		for (textureResource in textureResources) {
			textureResource.release();
		}
		for (audioResource in soundResources) {
			audioResource.release();
		}
	}
}
