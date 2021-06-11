package src;

@:publicFields
class TimeState {
	var timeSinceLoad:Float;
	var currentAttemptTime:Float;
	var gameplayClock:Float;
	var dt:Float;

	public function new() {}

	public function clone() {
		var n = new TimeState();
		n.timeSinceLoad = this.timeSinceLoad;
		n.currentAttemptTime = this.currentAttemptTime;
		n.gameplayClock = this.gameplayClock;
		n.dt = this.dt;
		return n;
	}
}
