package shapes;

import hxd.snd.effect.Spatialization;
import src.TimeState;
import collision.CollisionInfo;
import src.Util;
import src.DtsObject;
import h3d.Vector;
import src.ForceObject;
import src.ResourceLoader;
import src.AudioManager;
import src.MarbleWorld;
import src.Console;
import src.Marble;
import triggers.Trigger;
import mis.MissionElement.MissionElementStaticShape;

class PushButton extends DtsObject {
	var lastContactTime = -1e8;
	var element:MissionElementStaticShape;

	public function new(?element:MissionElementStaticShape) {
		super();
		this.element = element;
		var datablockLower = element != null ? element.datablock.toLowerCase() : "";
		this.dtsPath = switch (datablockLower) {
			case "pushbutton_pq": "data/shapes_pq/gameplay/pads/pushbuttonregular.dts";
			case "pushbuttonflat_pq": "data/shapes_pq/gameplay/pads/pushbuttonflat.dts";
			default: "data/shapes/buttons/pushbutton.dts";
		}
		this.isCollideable = true;
		this.isTSStatic = false;
		// Instancing batches by `identifier`, and the PQ variants use a different mesh - keep the
		// dtsPath in the identifier so they don't get batched with the vanilla mesh (or each other).
		this.identifier = "PushButton" + this.dtsPath;
		this.hasNonVisualSequences = true;
		this.enableCollideCallbacks = true;
	}

	public override function update(timeState:TimeState) {
		var currentCompletion = this.getCurrentCompletion(timeState);

		// Override the keyframe
		this.sequenceKeyframeOverride[0] = (currentCompletion * (this.dts.sequences[0].numKeyFrames - 1));
		super.update(timeState);
	}

	function getCurrentCompletion(timeState:TimeState) {
		var elapsed = timeState.timeSinceLoad - this.lastContactTime;
		var completion = Util.clamp(elapsed / this.dts.sequences[0].duration, 0, 1);
		if (elapsed > 5)
			completion = Util.clamp(1 - (elapsed - 5) / this.dts.sequences[0].duration, 0, 1);
		return completion;
	}

	override function onMarbleContact(marble:src.Marble, time:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, time, contact);
		if (time.timeSinceLoad - this.lastContactTime <= 0)
			return; // The trapdoor is queued to open, so don't do anything.
		var currentCompletion = this.getCurrentCompletion(time);

		if (currentCompletion == 0) {
			this.lastContactTime = time.timeSinceLoad;
			this.triggerCallback(marble, time);
		}

		// this.level.replay.recordMarbleContact(this);
	}

	/** Ported from PQ's `Button::triggerCallback` (`server/scripts/buttons.cs`) - a `PushButton`
		can be configured (via the mission editor's `TriggerObject[i]`/`ObjectMethod[i]` fields) to
		invoke a method on another named object when pressed. Only `onEnterTrigger()` is supported
		here (the vast majority of real usages target a `Trigger` this way; `onLeaveTrigger()` and
		arbitrary other method calls are out of scope).

		TorqueScript's dynamic-field pseudo-arrays are saved as plain numeric-suffixed field names,
		not bracket syntax, and index 0 has *no* suffix at all (`triggerObject`/`objectMethod` for
		index 0, `triggerObject2`/`objectMethod2` for index 2, etc.) - confirmed against real
		mission files. */
	function fieldAt(baseName:String, index:Int):String {
		var f = this.element.fields.get(index == 0 ? baseName : baseName + index);
		return f != null ? f[0] : null;
	}

	function triggerCallback(marble:Marble, timeState:TimeState) {
		if (this.element == null)
			return;

		// PQ's own index-advance has a bug (`%ct += !%ct + 1`) that permanently skips index 1:
		// 0 -> 2 -> 3 -> 4 -> ... - reproduced verbatim, not "fixed".
		var ct = 0;
		while (true) {
			var method = fieldAt("objectmethod", ct);
			if (method == null || method == "")
				break;

			var methodTrimmed = StringTools.trim(method).toLowerCase();
			// Skip the editor's unfilled template placeholder text.
			if (StringTools.contains(methodTrimmed, "dothis(")) {
				ct += ct == 0 ? 2 : 1;
				continue;
			}

			if (methodTrimmed == "onentertrigger()") {
				var targetName = fieldAt("triggerobject", ct);
				var target = targetName != null ? this.level.namedGameObjects.get(targetName) : null;
				if (target != null && (target is Trigger))
					(cast target : Trigger).onMarbleEnter(marble, timeState);
				else
					Console.error('PushButton: triggerObject "$targetName" not found or not a Trigger');
			}

			ct += ct == 0 ? 2 : 1;
		}
	}
}
