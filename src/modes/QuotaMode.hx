package modes;

import shapes.Gem;
import src.Marble;
import src.MarbleWorld;
import src.AudioManager;
import src.ResourceLoader;

/** Ported from PQ's `modes/quota.cs` - finishing only requires collecting `MissionInfo.gemquota`
	gems rather than every gem in the level (falls back to "no restriction" if the level has no
	gems at all, matching the source's `!($Game::GemCount && count < quota)` check). Sets
	`level.gemsRequiredToFinish` so other modes that only ever check "has the required number of
	gems been collected" (the base rule in `NullMode.canFinish`, inherited by e.g. `HasteMode`)
	automatically use the quota instead of the full gem count once Quota is active - no interface
	changes needed for that composition to work. */
class QuotaMode extends NullMode {
	var gemQuota:Int;

	public function new(level:MarbleWorld) {
		super(level);
		var field = level.mission.missionInfo.gemquota;
		this.gemQuota = field != null && field != "" ? Std.parseInt(field) : 0;
		level.gemsRequiredToFinish = this.gemQuota;
	}

	// `level.playGui` doesn't exist yet at construction time (`GameModeFactory.getGameMode` runs
	// before `MarbleWorld.initScene`/`postInit` create and initialize it), and `level.totalGems`
	// isn't finalized until the whole mission has loaded either - both are safe by `onMissionLoad`.
	override function onMissionLoad() {
		@:privateAccess level.playGui.setQuotaCounterVisible(true);
		@:privateAccess level.playGui.formatQuotaCounter(level.totalGems);
		@:privateAccess level.playGui.formatGemCounter(level.gemCount, this.gemQuota);
	}

	override function canFinish(marble:Marble):Bool {
		return level.totalGems == 0 || level.gemCount >= this.gemQuota;
	}

	/** Ported verbatim from `Mode_quota::getFinishMessage` - this isn't just a failure message,
		Quota also flavors the *success* message differently depending on whether every gem (not
		just the quota) was collected. */
	override function getFinishMessage(marble:Marble):String {
		if (level.totalGems > 0 && level.gemCount < this.gemQuota)
			return "You may not finish without reaching the gem quota!";
		else if (level.totalGems > 0 && level.gemCount == level.totalGems)
			return "Wha-? How?! You ACED the level! You Rock!";
		else
			return "Congratulations! You've finished!";
	}

	/** Ported verbatim from `Mode_quota::onFoundGem`'s branching (quota-remaining messaging, then
		total-remaining messaging once quota is already met but gems remain, then the 3-way "got
		everything" message depending on the mission's time limit). */
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
