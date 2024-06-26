package src;

import hxd.Pad;
import src.Console;
import src.Settings;

class Gamepad {
	public static var gamepad:Pad = Pad.createDummy();

	public static function init() {
		Pad.wait(onPad);
	}

	public static function onPad(pad:Pad) {
		Console.log("Gamepad found");
		pad.axisDeadZone = Settings.gamepadSettings.axisDeadzone;
		pad.onDisconnect = function() {
			Console.log("Gamepad disconnected");
			gamepad = Pad.createDummy();
		}
		gamepad = pad;
	}

	public static function getId(name:String) {
		switch (name) {
			case "start":
				return gamepad.config.start;
			case "ranalogY":
				return gamepad.config.ranalogY;
			case "ranalogX":
				return gamepad.config.ranalogX;
			case "ranalogClick":
				return gamepad.config.ranalogClick;
			case "dpadUp":
				return gamepad.config.dpadUp;
			case "dpadRight":
				return gamepad.config.dpadRight;
			case "dpadLeft":
				return gamepad.config.dpadLeft;
			case "dpadDown":
				return gamepad.config.dpadDown;
			case "back":
				return gamepad.config.back;
			case "analogY":
				return gamepad.config.analogY;
			case "analogX":
				return gamepad.config.analogX;
			case "analogClick":
				return gamepad.config.analogClick;
			case "Y":
				return gamepad.config.Y;
			case "X":
				return gamepad.config.X;
			case "RT":
				return gamepad.config.RT;
			case "RB":
				return gamepad.config.RB;
			case "LT":
				return gamepad.config.LT;
			case "LB":
				return gamepad.config.LB;
			case "B":
				return gamepad.config.B;
			case "A":
				return gamepad.config.A;
		}
		return -1;
	}

	public static function isDown(buttons:Array<String>) {
		for (button in buttons) {
			var buttonId = getId(button);
			if (buttonId < 0 || buttonId > gamepad.buttons.length)
				continue;
			if (gamepad.isDown(buttonId))
				return true;
		}
		return false;
	}

	public static function releaseKey(buttons:Array<String>) {
		for (button in buttons) {
			var buttonId = getId(button);
			if (buttonId < 0 || buttonId > gamepad.buttons.length)
				continue;
			@:privateAccess gamepad.buttons[buttonId] = false;
		}
	}

	public static function isPressed(buttons:Array<String>) {
		for (button in buttons) {
			var buttonId = getId(button);
			if (buttonId < 0 || buttonId > gamepad.buttons.length)
				continue;
			if (gamepad.isPressed(buttonId))
				return true;
		}
		return false;
	}

	public static function isReleased(buttons:Array<String>) {
		for (button in buttons) {
			var buttonId = getId(button);
			if (buttonId < 0 || buttonId > gamepad.buttons.length)
				continue;
			if (gamepad.isReleased(buttonId))
				return true;
		}
		return false;
	}

	public static function getAxis(axis:String) {
		switch (axis) {
			case "analogX":
				return gamepad.xAxis;
			case "analogY":
				return gamepad.yAxis;
			case "ranalogX":
				return gamepad.rxAxis;
			case "ranalogY":
				return gamepad.ryAxis;
		}
		return 0.0;
	}
}
