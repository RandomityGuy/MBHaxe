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

	var pathFromField:Bool = false;

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

	public function moveOnPath(firstNodeName:String, level:MarbleWorld) {
		if (this.pathInitialTransform == null) {
			this.pathInitialTransform = this.getTransform().clone();
			this.pathFirstNodeName = firstNodeName;
			this.pathLevel = level;
		}
		this.pathFollower = new GameObjectPathFollower(this, firstNodeName, level);
		level.registerMovingObject(this);
	}

	public function resetPath() {
		if (this.pathFollower == null || this.pathInitialTransform == null)
			return;
		this.setTransform(this.pathInitialTransform);
		this.pathFollower = new GameObjectPathFollower(this, this.pathFirstNodeName, this.pathLevel);
	}

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
