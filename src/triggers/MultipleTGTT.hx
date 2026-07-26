package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import src.PathedInterior;
import mis.MisParser;
import mis.MissionElement.MissionElementTrigger;

/** Ported from `data/missions_pq/expert/Polymorphism.mcs`'s `MultipleTGTT` datablock - a trigger
	coded specifically for that one mission, not a general PQ engine feature (per its own mission
	trivia text: "The Multiple Trigger GoTo Target was coded specially for this level"). It's
	functionally just `TriggerGotoTarget` (see `PathedInterior.hx`'s `MustChangeTrigger`) except it
	sets the same `TargetTime` on *several* named `PathedInterior`s at once instead of just its own
	parent - real source hardcodes exactly 9 target names (`plat1`..`plat9`) directly in
	`MultipleTGTT::onEnterTrigger`'s body, not via any indexed field convention on the trigger
	itself (its only custom field is `TargetTime`) - reproduced verbatim rather than inventing a
	generic multi-target field convention nothing else in PQ uses.

	Each `MultipleTGTT` instance in the mission is activated via a `PushButton_PQ`'s
	`triggerObject`/`objectMethod="onEnterTrigger()"` mechanism (already supported by
	`PushButton.triggerCallback`), not by the marble touching the trigger volume directly - though
	`onMarbleEnter` still works too, matching the real trigger's own callback. */
class MultipleTGTT extends Trigger {
	static final TARGET_NAMES = ["plat1", "plat2", "plat3", "plat4", "plat5", "plat6", "plat7", "plat8", "plat9"];

	// Ported from `MultipleTGTT::onAdd`'s `if (%trigger.TargetTime $= "") %trigger.TargetTime = 0;`
	// - a blank field normalizes to 0, not "unset"; `onEnterTrigger`'s own `$= ""` check is
	// therefore dead code (reproduced as an unreachable branch below, not removed).
	var targetTime:Float;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		var field = element.fields.get("targettime");
		this.targetTime = field != null && field[0] != "" ? MisParser.parseNumber(field[0]) / 1000 : 0;
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (this.targetTime < 0)
			return;
		for (name in TARGET_NAMES) {
			var target = this.level.namedGameObjects.get(name);
			if (target != null && (target is PathedInterior))
				(cast target : PathedInterior).setTargetTime(timeState, this.targetTime);
		}
	}
}
