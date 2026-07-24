package rewind;

/** Ported from the `mbu-port` branch's game-mode rewind design - each `GameMode` that has actual
	per-tick state (`MadnessMode`, `ConsistencyMode`, `LapsMode`, `TwoDMode`, ...) supplies one of
	these via `GameMode.getRewindState()`/`constructRewindState()` rather than `RewindFrame` and
	`RewindManager` growing a flat field per mode regardless of which mode is actually active.

	Unlike the reference branch, this has no `apply(level)` method - `RewindManager.applyFrame`
	calls `level.gameMode.applyRewindState(rf.modeState)` directly (it already holds `level.gameMode`),
	and `CompositeMode.applyRewindState` delegates to its children by direct reference. Doing it that
	way instead of each state re-locating "its" mode via `GameModeFactory.findMode` (this port's
	`CompositeMode`, needed for multi-mode missions, has no equivalent in the reference branch)
	avoids a redundant tree walk on every single rewound frame. */
interface RewindableState {
	function clone():RewindableState;
	function getSize():Int;
	function serialize(rm:RewindManager, bw:haxe.io.BytesOutput):Void;
	function deserialize(rm:RewindManager, br:haxe.io.BytesInput):Void;
}
