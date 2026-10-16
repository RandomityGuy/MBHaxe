package src;

@:publicFields
class TimeState {
	var timeSinceLoad:Float;
	var currentAttemptTime:Float;
	var gameplayClock:Float;
	var dt:Float;
	var ticks:Int; // How many 32ms ticks have happened
	var subframe:Float;

	public function new() {}

	public function clone() {
		var n = new TimeState();
		n.timeSinceLoad = this.timeSinceLoad;
		n.currentAttemptTime = this.currentAttemptTime;
		n.gameplayClock = this.gameplayClock;
		n.dt = this.dt;
		n.ticks = ticks;
		n.subframe = subframe;
		return n;
	}

	public inline function load(o:TimeState) {
		this.timeSinceLoad = o.timeSinceLoad;
		this.currentAttemptTime = o.currentAttemptTime;
		this.gameplayClock = o.gameplayClock;
		this.dt = o.dt;
		this.ticks = o.ticks;
		this.subframe = o.subframe;
	}
}
