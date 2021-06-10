package shapes;

class TimeTravel extends PowerUp {
	var timeBonus:Float = 5;

	public function new() {
		super();
		this.dtsPath = "data/shapes/items/timetravel.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "TimeTravel";
		this.pickUpName = '${this.timeBonus} second Time Travel bonus';
		this.cooldownDuration = 1e8;
		this.useInstancing = true;
		this.autoUse = true;
	}

	public function pickUp():Bool {
		return true;
	}

	public function use(time:Float) {}
}