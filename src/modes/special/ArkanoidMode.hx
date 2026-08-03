package modes.special;

import shapes.FadePlatform;
import src.TimeState;
import modes.TwoDMode;

/** Ported from `Arkanoid.mcs`'s `package Arkanoid` block - every brick in `ArkanoidFPGroup` is a
	`FadePlatform` with `functionality = "fading"` (breaks a bit more per hit, never regenerates
	within an attempt), and real PQ's `StaticShape::hide` callback tallies them into
	`ArkanoidHiddenFPSet`, calling `endGameSetup()` (this engine's `MarbleWorld.touchFinish`) the
	instant every brick has been hidden. This mission has no other `FadePlatform`s outside that
	group, so checking every `FadePlatform` in the level for `currentOpacity == 0` (fully faded,
	matching `hide(true)`) is equivalent to real PQ's per-group tally without needing to track
	SimGroup membership at runtime.

	Extends `TwoDMode` (not `NullMode`) because the mission's own `gameMode = "2D"` field still
	applies alongside the `Arkanoid` special package - `GameModeFactory` special-cases activated
	packages before ever looking at that field, so this mode has to inherit the 2D behavior itself
	rather than relying on `CompositeMode` to combine them. */
class ArkanoidMode extends TwoDMode {
	var bricks:Array<FadePlatform>;
	var finished:Bool = false;

	public override function onMissionLoad() {
		super.onMissionLoad();
		this.bricks = [for (o in this.level.dtsObjects) if (Std.isOfType(o, FadePlatform)) cast(o, FadePlatform)];
	}

	public override function update(t:TimeState) {
		super.update(t);
		if (this.finished || this.bricks == null)
			return;
		for (brick in this.bricks)
			if (brick.currentOpacity != 0)
				return;
		this.finished = true;
		@:privateAccess this.level.touchFinish();
	}
}
