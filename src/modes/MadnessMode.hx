package modes;

import modes.GameMode.ScoreType;
import shapes.Gem;
import src.Marble;
import src.MarbleWorld;
import src.AudioManager;
import rewind.RewindableState;
import rewind.RewindManager;

@:publicFields
class MadnessState implements RewindableState {
	var gotAllGems:Bool;
	var score:Int;

	public function new() {}

	public function clone():RewindableState {
		var c = new MadnessState();
		c.gotAllGems = gotAllGems;
		c.score = score;
		return c;
	}

	public function getSize():Int {
		return 1 + 2; // gotAllGems + score
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeByte(gotAllGems ? 1 : 0);
		bw.writeInt16(score);
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		gotAllGems = br.readByte() != 0;
		score = br.readInt16();
	}
}

class MadnessMode extends NullMode {
	var gotAllGems:Bool = false;
	var score:Int = 0;

	override function getStartTime():Float {
		var field = level.mission.missionInfo.time;
		return field != null && field != "" && field != "0" ? Std.parseFloat(field) / 1000 : 300;
	}

	override function timeMultiplier():Float {
		return -1;
	}

	override function getScoreType():ScoreType {
		return this.gotAllGems ? Time : Score;
	}

	override function getFinishScore():{score:Float, type:ScoreType} {
		return this.gotAllGems ? {score: getStartTime() - level.finishTime.gameplayClock, type: Time} : {score: this.score, type: Score};
	}

	override function canFinish(marble:Marble):Bool {
		return true;
	}

	override function getFinishMessage(marble:Marble):String {
		return "Congratulations! You've finished!";
	}

	override function onRestart() {
		score = 0;
		@:privateAccess level.playGui.formatGemHuntCounter(score);
	}

	override function onTimeExpire() {
		if (level.finishTime != null)
			return;
		if (!level.isMultiplayer) {
			@:privateAccess level.touchFinish();
			return;
		}
	}

	override function onGemPickup(marble:Marble, gem:Gem) {
		var incr = 0;
		switch (gem.gemColor.toLowerCase()) {
			case "red.gem":
				incr = 1;
				@:privateAccess level.playGui.addMiddleMessage('+1', 0xFF6666);
			case "yellow.gem":
				incr = 2;
				@:privateAccess level.playGui.addMiddleMessage('+2', 0xFFFF66);
			case "blue.gem":
				incr = 5;
				@:privateAccess level.playGui.addMiddleMessage('+5', 0x6666FF);
			case "platinum.gem":
				incr = 10;
				@:privateAccess level.playGui.addMiddleMessage('+10', 0xdddddd);
		}
		this.level.gemCount++;
		this.score += incr;
		@:privateAccess level.playGui.formatGemHuntCounter(score);
		AudioManager.playPitchedSound("gotDiamond", @:privateAccess this.level.soundResources);

		if (this.level.gemCount >= this.level.totalGems) {
			this.gotAllGems = true;
			@:privateAccess this.level.touchFinish();
		}

		return true;
	}

	override function onOutOfBounds(marble:Marble):Bool {
		if (level.isMultiplayer)
			return false;
		this.gotAllGems = false;
		@:privateAccess level.touchFinish();
		return true;
	}

	override function getRewindState():RewindableState {
		var s = new MadnessState();
		s.gotAllGems = this.gotAllGems;
		s.score = this.score;
		return s;
	}

	override function applyRewindState(state:RewindableState) {
		var s:MadnessState = cast state;
		this.gotAllGems = s.gotAllGems;
		this.score = s.score;
		@:privateAccess level.playGui.formatGemHuntCounter(this.score);
	}

	override function constructRewindState():RewindableState {
		return new MadnessState();
	}
}
