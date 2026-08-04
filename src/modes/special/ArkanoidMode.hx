package modes.special;

import shapes.FadePlatform;
import src.TimeState;
import modes.TwoDMode;

class ArkanoidMode extends TwoDMode {
	var bricks:Array<FadePlatform>;
	var finished:Bool = false;

	public override function onMissionLoad() {
		super.onMissionLoad();
		this.bricks = [
			for (o in this.level.dtsObjects) if (Std.isOfType(o, FadePlatform)) cast(o, FadePlatform)
		];
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
