package modes;

import src.Marble;
import src.MarbleWorld;

class HasteMode extends NullMode {
	var speedToQualify:Float;

	public function new(level:MarbleWorld) {
		super(level);
		var field = level.mission.missionInfo.speedtoqualify;
		this.speedToQualify = field != null && field != "" ? Std.parseFloat(field) : 0;
	}

	override function onMissionLoad() {
		@:privateAccess level.playGui.setHasteThreshold(this.speedToQualify);
	}

	override function canFinish(marble:Marble):Bool {
		return super.canFinish(marble) && marble.velocity.length() >= this.speedToQualify;
	}

	override function getFinishMessage(marble:Marble):String {
		if (marble.velocity.length() < this.speedToQualify)
			return "You may not finish without reaching the qualifying speed!";
		return super.getFinishMessage(marble);
	}
}
