package triggers;

import src.TimeState;
import src.Marble;
import src.MarbleWorld;
import mis.MisParser;

/** Assigns a path to one or more named objects on marble-enter. Ported from PQ's
	`PathTrigger::onEnterTrigger` (`platinum/server/scripts/triggers.cs`, explicitly marked
	"UNFINISHED CODE" in the PQ source - reproduced as-is, bugs included, per the standing rule).

	`Object[i]`/`Path[i]` are 1-based indexed fields in script, but TorqueScript's dynamic-field
	pseudo-arrays are actually saved as plain numeric-suffixed field names (`Object1`, `Path1`,
	`Object2`, ...), not bracket syntax - confirmed against real mission files. Read until the
	first `Object<i>` that doesn't resolve to a real placed object. `InitialPosition<i>` is parsed
	by PQ but never actually used (the underlying `moveOnPath` only takes one parameter, so PQ's
	extra argument is silently discarded) - not wired to anything here either. If `Path<i>` is
	blank, PQ simply doesn't reassign its working `%path` variable, so it silently reuses whatever
	the *previous* index's path was - reproduced verbatim, not "fixed" to fall back to null. */
class PathTrigger extends Trigger {
	/** Gates `TriggerOnce` (defaults true - see the class doc). Snapshotted directly by
		`RewindFrame`/`RewindManager` (`pathTriggerStates`, filtered from `level.triggers`) - without
		this, rewinding to before this trigger ever fired would leave it stuck `true` from the
		forward-time playthrough, silently refusing to re-fire on a fresh walk-in. */
	public var triggered:Bool = false;

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		var triggerOnceField = this.element.fields.get("triggeronce");
		var triggerOnce = triggerOnceField == null || MisParser.parseBoolean(triggerOnceField[0]);
		if (triggerOnce && this.triggered)
			return;
		this.triggered = true;

		runObjectPathChain(this.element.fields, this.level);
	}

	override function reset() {
		super.reset();
		this.triggered = false;
	}

	/** Shared with `shapes.IceShard`'s `gotoTarget` feature (a per-mission script override in some
		PQ levels that bolts this exact `Object[i]`/`Path[i]` behavior onto ice shards too - see
		`IceShard.hx`), since it's the identical field convention/bug reproduced verbatim. */
	public static function runObjectPathChain(fields:Map<String, Array<String>>, level:MarbleWorld) {
		var path:String = null;
		var i = 1;
		while (true) {
			var objectField = fields.get("object" + i);
			var objectName = objectField != null ? objectField[0] : null;
			if (objectName == null || objectName == "")
				break;
			var target = level.namedGameObjects.get(objectName.toLowerCase());
			if (target == null)
				break;

			var pathField = fields.get("path" + i);
			var pathAtIndex = pathField != null ? pathField[0] : null;
			if (pathAtIndex != null && pathAtIndex != "")
				path = pathAtIndex;

			if (path != null)
				target.moveOnPath(path, level);

			i++;
		}
	}

	/** Every `Object[i]` this field set could eventually call `moveOnPath` on, without actually
		doing so - used by `MarbleWorld.start`'s pre-scan (see its doc comment) to pre-register these
		objects into `level.movingObjects` before any gameplay/rewind recording begins, so rewinding
		to before this trigger has ever fired doesn't desync `RewindFrame.pathFollowerStates`' array
		alignment against a `level.movingObjects` that only grew to include this object later. */
	public static function collectObjectTargets(fields:Map<String, Array<String>>, level:MarbleWorld):Array<src.GameObject> {
		var targets = [];
		var i = 1;
		while (true) {
			var objectField = fields.get("object" + i);
			var objectName = objectField != null ? objectField[0] : null;
			if (objectName == null || objectName == "")
				break;
			var target = level.namedGameObjects.get(objectName.toLowerCase());
			if (target == null)
				break;
			targets.push(target);
			i++;
		}
		return targets;
	}
}
