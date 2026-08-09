package shapes;

import mis.MisParser;
import mis.MissionElement.MissionElementStaticShape;
import src.DtsObject;
import src.MarbleWorld;
import src.ResourceLoader;
import src.AudioManager;
import src.TimeState;

class HelpBubble extends DtsObject {
	var text:String;
	var triggerRadius:Float = 3;
	var displayOnce:Bool = false;

	var wasWithin:Bool = false;
	var hasBeenInOnce:Bool = false;
	var disabled:Bool = false;

	public function new(element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes_pq/gameplay/helpbubble.dts";
		this.isCollideable = true;
		this.useInstancing = true;
		this.identifier = "HelpBubble";

		this.text = element.fields.exists("text") ? element.fields.get("text")[0] : " ";
		if (element.fields.exists("triggerradius"))
			this.triggerRadius = MisParser.parseNumber(element.fields.get("triggerradius")[0]);
		if (element.fields.exists("displayonce"))
			this.displayOnce = MisParser.parseBoolean(element.fields.get("displayonce")[0]);
		if (element.fields.exists("disabled"))
			this.disabled = MisParser.parseBoolean(element.fields.get("disabled")[0]);
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load("sound/infotutorial.wav").entry.load(onFinish);
		});
	}

	public override function update(timeState:TimeState) {
		super.update(timeState);
		if (@:privateAccess !this.level._ready || disabled)
			return;

		var marble = this.level.marble;
		if (marble == null)
			return;

		var within = marble.getAbsPos().getPosition().distance(this.getAbsPos().getPosition()) < this.triggerRadius;
		if (within && !this.wasWithin) {
			if (!this.displayOnce || !this.hasBeenInOnce) {
				this.hasBeenInOnce = true;
				AudioManager.playSound(ResourceLoader.getResource("data/sound/infotutorial.wav", ResourceLoader.getAudio, this.soundResources));
				this.level.displayHelp(this.text, 5);
			}
		}
		this.wasWithin = within;
	}

	override function reset() {
		super.reset();
		this.wasWithin = false;
		this.hasBeenInOnce = false;
	}
}
