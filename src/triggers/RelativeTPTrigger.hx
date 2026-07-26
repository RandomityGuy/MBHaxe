package triggers;

import src.Marble;
import src.TimeState;
import h3d.Vector;
import src.ResourceLoader;
import src.AudioManager;
import mis.MisParser;
import src.MarbleWorld;
import mis.MissionElement.MissionElementTrigger;

/** Ported from PQ's `RelativeTPTrigger` (`server/scripts/teleporter.cs`). Unlike `TeleportTrigger`,
	the destination is a fixed offset from the destination object's center - independent of where
	the marble actually entered the trigger volume:
	`diff = triggerCenter * -1 * TPScale` (componentwise), `pos = destCenter + diff + TPOffset`.
	The `delay` field is parsed for fidelity but deliberately unused - it's parsed in the real
	source's `onAdd` but never read anywhere in `onEnterTrigger`, so it has no actual effect there
	either. */
class RelativeTPTrigger extends Trigger {
	var destination:String;
	var silent:Bool = false;
	var tpScale:Vector = new Vector(1, 1, 1);
	var tpOffset:Vector = new Vector(0, 0, 0);

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);
		this.destination = element.destination;

		var silentField = element.fields.get("silent");
		this.silent = silentField != null && silentField[0] != "" && MisParser.parseBoolean(silentField[0]);

		var scaleField = element.fields.get("tpscale");
		if (scaleField != null && scaleField[0] != "")
			this.tpScale = MisParser.parseVector3(scaleField[0]);

		var offsetField = element.fields.get("tpoffset");
		if (offsetField != null && offsetField[0] != "") {
			this.tpOffset = MisParser.parseVector3(offsetField[0]);
			this.tpOffset.x = -this.tpOffset.x;
		}
	}

	override function init(onFinish:() -> Void) {
		ResourceLoader.load("sound/teleport.wav").entry.load(onFinish);
	}

	override function onMarbleEnter(marble:Marble, timeState:TimeState) {
		if (this.destination == null)
			return;

		var destCenter = this.resolveDestinationCenter();
		if (destCenter == null)
			return;

		var triggerCenter = this.collider.boundingBox.getCenter().toVector();

		var diff = new Vector(triggerCenter.x * -1 * this.tpScale.x, triggerCenter.y * -1 * this.tpScale.y, triggerCenter.z * -1 * this.tpScale.z);

		var pos = destCenter.add(diff).add(this.tpOffset);
		pos.w = 1;

		var marblePos = marble.collider.transform.getPosition();
		marblePos.load(marblePos.add(pos));

		marble.prevPos.load(marblePos);
		marble.setPosition(marblePos.x, marblePos.y, marblePos.z);
		var ct = marble.collider.transform.clone();
		ct.setPosition(marblePos);
		marble.collider.setTransform(ct);
		if (this.level.isRecording) {
			this.level.replay.recordMarbleStateFlags(false, false, true, false);
		}

		if (!this.silent && level.marble == marble && @:privateAccess !marble.isNetUpdate) {
			AudioManager.playSound(ResourceLoader.getResource("data/sound/teleport.wav", ResourceLoader.getAudio, this.soundResources));
		}
	}

	function resolveDestinationCenter():Vector {
		var destinationList = this.level.triggers.filter(x -> x is DestinationTrigger
			&& x.element._name.toLowerCase() == this.destination.toLowerCase());
		if (destinationList.length > 0)
			return destinationList[0].collider.boundingBox.getCenter().toVector();

		var named = this.level.namedObjects.get(this.destination);
		if (named != null && named.obj != null)
			return new Vector(named.obj.x, named.obj.y, named.obj.z);

		return null;
	}
}
