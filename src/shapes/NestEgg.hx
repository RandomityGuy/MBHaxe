package shapes;

import src.Marble;
import src.Settings;
import mis.MissionElement.MissionElementItem;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.AudioManager;

/** PQ's NestEgg_PQ::onPickup forwards verbatim to EasterEgg::onPickup, and the client-side
	sound handler always plays the "easter"/"easterfound" pitched sounds regardless of egg type
	(the NestEggSfx/NestEggFoundSfx audio profiles are defined in PQ's source but never actually
	referenced anywhere - dead data) - so this reuses EasterEgg's mechanism/sounds exactly,
	just keyed per-skin since a single mission can have multiple distinctly-skinned nest eggs. */
class NestEgg extends PowerUp {
	static var skins = ["base", "black", "blue", "brown", "green", "orange", "purple", "red"];

	var skin:String;

	public function new(element:MissionElementItem) {
		super(element);
		this.dtsPath = "data/shapes_pq/gameplay/nestegg/nesteggnotrans.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "NestEgg";
		this.pickUpName = "Nest Egg";
		this.autoUse = true;
		this.cooldownDuration = 1e8;

		var skinField = element.fields.get("skin");
		this.skin = skinField != null && skins.contains(skinField[0]) ? skinField[0] : "base";
		this.skinOverride = this.skin;
	}

	function eggKey():String {
		return this.level.mission.path + "_nestegg_" + this.skin;
	}

	public function pickUp(marble:Marble):Bool {
		var found = Settings.easterEggs.exists(eggKey());
		if (!found) {
			Settings.easterEggs.set(eggKey(), this.level.timeState.currentAttemptTime);
			this.pickupSound = ResourceLoader.getResource(AudioManager.getPitchedSoundPath("easter"), ResourceLoader.getAudio, this.soundResources);
			this.customPickupMessage = "You found a Nest Egg!";
		} else {
			this.pickupSound = ResourceLoader.getResource(AudioManager.getPitchedSoundPath("easterfound"), ResourceLoader.getAudio, this.soundResources);
			this.customPickupMessage = "You already found this Nest Egg.";
		}

		return true;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			var worker = new ResourceLoaderWorker(onFinish);
			AudioManager.preloadPitchedSound("easter", worker);
			AudioManager.preloadPitchedSound("easterfound", worker);
			worker.run();
		});
	}

	public function use(marble:Marble, timeState:src.TimeState) {
		return true;
	}
}
