package src;

import hxd.Key;
import h3d.Vector;
import mis.MisParser;
import mis.MissionElement;

class PlaytestPointManager {
	public var world:MarbleWorld;
	public var markers:Map<Int, PlaytestPoint> = new Map();
	public var sortedIndices:Array<Int> = [];
	public var currentCarouselIndex:Int = -1;

	public function new(world:MarbleWorld) {
		this.world = world;
	}

	public function clear() {
		markers.clear();
		sortedIndices = [];
		currentCarouselIndex = -1;
	}

	public function scanMission(simGroup:MissionElementSimGroup) {
		if (simGroup == null || simGroup.elements == null)
			return;

		for (element in simGroup.elements) {
			if (element._type == MissionElementType.ScriptObject) {
				var so:MissionElementScriptObject = cast element;
				var className = so.fields.exists("class") ? so.fields.get("class")[0] : "";
				if (className.toLowerCase() == "playtestpoint") {
					var marker = PlaytestPoint.fromScriptObject(so);
					markers.set(marker.index, marker);
				}
			} else if (element._type == MissionElementType.SimGroup) {
				scanMission(cast element);
			}
		}

		sortedIndices = [];
		for (idx in markers.keys()) {
			sortedIndices.push(idx);
		}
		sortedIndices.sort((a, b) -> a - b);
	}

	public function update(dt:Float) {
		if (sortedIndices.length == 0 || world == null || world.marble == null)
			return;

		// Check keys 1-9
		for (i in 1...10) {
			var numKey = Key.NUMBER_0 + i;
			var numpadKey = Key.NUMPAD_0 + i;

			if (isKeyPressedUnbound(numKey) || isKeyPressedUnbound(numpadKey)) {
				if (markers.exists(i)) {
					teleportToMarker(i);
					return;
				}
			}
		}

		// Check carousel keys: - (prev), +/= (next)
		if (isKeyPressedUnbound(Key.QWERTY_MINUS) || isKeyPressedUnbound(Key.NUMPAD_SUB)) {
			teleportPrev();
			return;
		}
		if (isKeyPressedUnbound(Key.QWERTY_EQUALS) || isKeyPressedUnbound(Key.NUMPAD_ADD)) {
			teleportNext();
			return;
		}
	}

	function isKeyPressedUnbound(keyCode:Int):Bool {
		if (keyCode == 0 || !Key.isPressed(keyCode))
			return false;

		// Ensure any configured control binding in Settings takes priority
		var cs = Settings.controlsSettings;
		if (cs != null) {
			for (field in Reflect.fields(cs)) {
				if (Reflect.field(cs, field) == keyCode)
					return false;
			}
		}

		return true;
	}

	public function teleportToMarker(index:Int) {
		var marker = markers.get(index);
		if (marker == null || world == null || world.marble == null)
			return;

		// Cancel ready/set/go
		world.clearSchedule();
		world.marble.mode = Play;
		if (world.timeState.currentAttemptTime < 3.5) {
			world.timeState.currentAttemptTime = 3.5;
		}
		
		world.cheatsUsed = true;

		// Update carousel index
		var foundIdx = sortedIndices.indexOf(index);
		if (foundIdx != -1) {
			currentCarouselIndex = foundIdx;
		}

		var upVector = new Vector(0, 0, 1);
		upVector.transform(marker.rotation.toMatrix());

		world.respawn(world.marble, marker.position, marker.rotation, upVector);
		world.displayAlert('Playtest Point #${index}');
	}

	public function teleportNext() {
		if (sortedIndices.length == 0)
			return;
		currentCarouselIndex = (currentCarouselIndex + 1) % sortedIndices.length;
		teleportToMarker(sortedIndices[currentCarouselIndex]);
	}

	public function teleportPrev() {
		if (sortedIndices.length == 0)
			return;
		currentCarouselIndex = (currentCarouselIndex - 1 + sortedIndices.length) % sortedIndices.length;
		teleportToMarker(sortedIndices[currentCarouselIndex]);
	}
}
