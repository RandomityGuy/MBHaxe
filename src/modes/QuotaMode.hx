package modes;

import shapes.Gem;
import src.Marble;
import src.MarbleWorld;
import src.AudioManager;
import src.ResourceLoader;

class QuotaMode extends NullMode {
	var gemQuota:Int;

	public function new(level:MarbleWorld) {
		super(level);
		var field = level.mission.missionInfo.gemquota;
		this.gemQuota = field != null && field != "" ? Std.parseInt(field) : 0;
		level.gemsRequiredToFinish = this.gemQuota;
	}

	override function onMissionLoad() {
		@:privateAccess level.playGui.setQuotaCounterVisible(true);
		@:privateAccess level.playGui.formatQuotaCounter(level.totalGems);
		@:privateAccess level.playGui.formatGemCounter(level.gemCount, this.gemQuota);
	}

	override function canFinish(marble:Marble):Bool {
		return level.totalGems == 0 || level.gemCount >= this.gemQuota;
	}

	override function getFinishMessage(marble:Marble):String {
		if (level.totalGems > 0 && level.gemCount < this.gemQuota)
			return "You may not finish without reaching the gem quota!";
		else if (level.totalGems > 0 && level.gemCount == level.totalGems)
			return "Wha-? How?! You ACED the level! You Rock!";
		else
			return "Congratulations! You've finished!";
	}

	override function onGemPickup(marble:Marble, gem:Gem) {
		this.level.gemCount++;

		var remainingToQuota = this.gemQuota - this.level.gemCount;
		var remainingToAll = this.level.totalGems - this.level.gemCount;
		var message:String;
		if (remainingToQuota == 0) {
			message = "You've reached the gem quota, head for the finish!";
			AudioManager.playPitchedSound("gotAllDiamonds", @:privateAccess this.level.soundResources);
		} else if (remainingToQuota == 1) {
			message = "You picked up a gem! Only one gem to go!";
			AudioManager.playPitchedSound("gotDiamond", @:privateAccess this.level.soundResources);
		} else if (remainingToQuota > 1) {
			message = 'You picked up a gem! ${remainingToQuota} gems to go!';
			AudioManager.playPitchedSound("gotDiamond", @:privateAccess this.level.soundResources);
		} else if (this.level.gemCount == this.level.totalGems) {
			if (!Math.isFinite(this.level.mission.qualifyTime))
				message = "Wow, you got all the gems! Head for the finish!";
			else if (this.level.timeState.gameplayClock < this.level.mission.qualifyTime)
				message = "Wow, you got all the gems! Head for the finish before time runs out!";
			else
				message = "You got all the gems, but the time already ran out!";
			AudioManager.playPitchedSound("gotAllDiamonds", @:privateAccess this.level.soundResources);
		} else if (remainingToAll == 1) {
			message = "You picked up a gem! Only one more gem to reach 100%!";
			AudioManager.playPitchedSound("gotDiamond", @:privateAccess this.level.soundResources);
		} else {
			message = 'You picked up a gem! ${remainingToAll} gems more to reach 100%!';
			AudioManager.playPitchedSound("gotDiamond", @:privateAccess this.level.soundResources);
		}

		this.level.displayAlert(message);
		@:privateAccess this.level.playGui.formatGemCounter(this.level.gemCount, this.gemQuota);

		return true;
	}
}
