package rewind;

import src.MarbleWorld;
import h3d.Vector;
import net.Move;

@:publicFields
class InputRecorderFrame {
	var time:Float;
	var move:Move;
	var marbleAxes:Array<Vector>;
	var pos:Vector;
	var velocity:Vector;

	public function new() {}
}

class InputRecorder {
	var frames:Array<InputRecorderFrame>;
	var level:MarbleWorld;

	public function new(level:MarbleWorld) {
		frames = [];
		this.level = level;
	}

	public function recordInput(t:Float) {
		var frame = new InputRecorderFrame();
		frame.time = t;
		frame.move = level.marble.recordMove();
		frames.push(frame);
	}

	public function recordMarble() {
		frames[frames.length - 1].pos = @:privateAccess level.marble.newPos?.clone();
		frames[frames.length - 1].velocity = level.marble.velocity.clone();
	}

	public function recordAxis(axis:Array<Vector>) {
		frames[frames.length - 1].marbleAxes = axis.copy();
	}

	public function getMovesFrom(t:Float) {
		if (frames.length == 0)
			return [];
		var start = 0;
		var end = frames.length - 1;
		var mid = Std.int(frames.length / 2);
		while (end - start > 1) {
			mid = Std.int((start / 2) + (end / 2));
			if (frames[mid].time < t) {
				start = mid + 1;
			} else if (frames[mid].time > t) {
				end = mid - 1;
			} else {
				start = end = mid;
			}
		}

		return frames.slice(start - 1);
	}
}
