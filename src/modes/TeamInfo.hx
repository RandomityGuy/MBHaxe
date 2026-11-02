package modes;

class TeamInfo {
	public static function getName(team:Int):String {
		return switch (team) {
			case 0: "Red";
			case 1: "Blue";
			default: "Team " + team;
		}
	}

	public static function getColor(team:Int):Int {
		return switch (team) {
			case 0: 0xFF4444;
			case 1: 0x4444FF;
			default: 0xCCCCCC;
		}
	}

	public static function lighten(color:Int, amount:Float):Int {
		var r = color >> 16 & 0xFF;
		var g = color >> 8 & 0xFF;
		var b = color & 0xFF;
		r = Std.int(r + (255 - r) * amount);
		g = Std.int(g + (255 - g) * amount);
		b = Std.int(b + (255 - b) * amount);
		return r << 16 | g << 8 | b;
	}

	public static function toHex(color:Int):String {
		return "#" + StringTools.hex(color, 6);
	}
}
