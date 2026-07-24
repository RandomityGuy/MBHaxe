package triggers;

/** Shared by `LapsCheckpoint`/`LapsCounterTrigger` - the checkpoint-activation fields `LapsMode`
	needs regardless of which of the two trigger types was actually hit. */
interface ILapsRespawnTrigger {
	var enableRespawning:Bool;
	var customSpawnPoint:Bool;
	var spawnPoint:String;
	var forceGravity:String;
}
