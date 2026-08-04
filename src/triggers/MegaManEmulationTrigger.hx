package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import shapes.MegaManPlatform;
import mis.MissionElement.MissionElementTrigger;
import triggers.Trigger;

class MegaManEmulationTrigger extends Trigger {
	var startPlatformName:String;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		var f = element.fields.get("startplatform");
		this.startPlatformName = f != null ? f[0] : null;
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (this.startPlatformName == null)
			return;
		var obj = this.level.namedGameObjects.get(this.startPlatformName.toLowerCase());
		if (obj == null || !(obj is MegaManPlatform))
			return;
		var platform:MegaManPlatform = cast obj;
		platform.respondToCollision = true;
		platform.hasCollided = false;
		platform.show(timeState);
	}
}
