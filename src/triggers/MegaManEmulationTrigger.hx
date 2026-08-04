package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import shapes.MegaManPlatform;
import mis.MissionElement.MissionElementTrigger;
import triggers.Trigger;

/** Ported from `Vice.mcs`/`Versa.mcs`'s `MegaManEmulationTrigger` - kicks off a `MegaManPlatform`
	chain from its `startPlatform` field. Real PQ's own comment on `onEnterTrigger` admits this has
	no "once per round" gating (re-entering the trigger restarts the whole chain from platform 1
	every time, even mid-sequence) - reproduced as-is per the standing rule against silently fixing
	source bugs/quirks when porting. */
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
		if (obj == null || !Std.isOfType(obj, MegaManPlatform))
			return;
		var platform:MegaManPlatform = cast obj;
		platform.respondToCollision = true;
		platform.hasCollided = false;
		platform.show(timeState);
	}
}
