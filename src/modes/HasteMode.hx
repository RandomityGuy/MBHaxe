package modes;

import src.Marble;
import src.MarbleWorld;

/** Ported from PQ's `modes/haste.cs` - adds a minimum-speed precondition on top of whatever gem
	requirement is already in effect (inherits `NullMode.canFinish`'s gem check - which already
	respects `QuotaMode`'s override via `level.gemsRequiredToFinish` if that's also active - and
	ANDs a speed check on top), rather than replacing the finish condition outright the way Quota
	does. */
class HasteMode extends NullMode {
	var speedToQualify:Float;

	public function new(level:MarbleWorld) {
		super(level);
		var field = level.mission.missionInfo.speedtoqualify;
		this.speedToQualify = field != null && field != "" ? Std.parseFloat(field) : 0;
	}

	// `level.playGui` doesn't exist yet at construction time (`GameModeFactory.getGameMode` runs
	// before `MarbleWorld.initScene`/`postInit` create and initialize it) - register the HUD
	// threshold once it's actually safe to reach `level.playGui`.
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
