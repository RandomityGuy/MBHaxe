package shapes;

import collision.CollisionInfo;
import mis.MisParser;
import src.DtsObject;
import src.ResourceLoader;
import mis.MissionElement.MissionElementStaticShape;

class Checkpoint extends DtsObject {
	public var disableOOB = false;

	var element:MissionElementStaticShape;

	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes/pads/checkpad.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "Checkpoint";
		this.element = element;

		this.disableOOB = element.fields.exists('disableOob') ? MisParser.parseBoolean(element.fields['disableOob'][0]) : false;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/checkpoint.wav").entry.load(onFinish);
		});
	}

	public override function onMarbleContact(time:src.TimeState, ?contact:CollisionInfo) {
		this.level.saveCheckpointState({
			obj: this,
			elem: this.element
		}, null);
	}
}
