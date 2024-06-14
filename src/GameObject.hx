package src;

import src.TimeState;
import collision.CollisionInfo;
import h3d.scene.Object;
import src.Resource;
import h3d.mat.Texture;
import hxd.res.Sound;
import src.Marble;

class GameObject extends Object {
	public var identifier:String;
	public var currentOpacity:Float = 1;
	public var isCollideable:Bool = false;
	public var isBoundingBoxCollideable:Bool = false;
	public var enableCollideCallbacks:Bool = false;

	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

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
