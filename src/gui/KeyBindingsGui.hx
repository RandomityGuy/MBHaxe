package gui;

import hxd.Key;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class KeyBindingsGui extends GuiImage {
	var innerCtrl:GuiControl;
	var btnListLeft:GuiXboxList;
	var btnListRight:GuiXboxList;

	public function new(pauseGui:Bool = false) {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 42 * Settings.uiScale, MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		function getConflictingBinding(bindingName:String, key:Int) {
			if (Settings.controlsSettings.forward == key && bindingName != "Move Forward")
				return "Move Forward";
			if (Settings.controlsSettings.backward == key && bindingName != "Move Backward")
				return "Move Backward";
			if (Settings.controlsSettings.left == key && bindingName != "Move Left")
				return "Move Left";
			if (Settings.controlsSettings.right == key && bindingName != "Move Right")
				return "Move Right";
			if (Settings.controlsSettings.camForward == key && bindingName != "Rotate Camera Up")
				return "Rotate Camera Up";
			if (Settings.controlsSettings.camBackward == key && bindingName != "Rotate Camera Down")
				return "Rotate Camera Down";
			if (Settings.controlsSettings.camLeft == key && bindingName != "Rotate Camera Left")
				return "Rotate Camera Left";
			if (Settings.controlsSettings.camRight == key && bindingName != "Rotate Camera Right")
				return "Rotate Camera Right";
			if (Settings.controlsSettings.jump == key && bindingName != "Jump")
				return "Jump";
			if (Settings.controlsSettings.powerup == key && bindingName != "Use PowerUp")
				return "Use PowerUp";
			if (Settings.controlsSettings.freelook == key && bindingName != "Free Look")
				return "Free Look";
			if (Settings.controlsSettings.rewind == key && bindingName != "Rewind")
				return "Rewind";

			return null;
		}

		function remapFunc(bindingName:String, bindingFunc:Int->Void, ctrl:GuiXboxListButton) {
			var remapDlg = new RemapDlg(bindingName);
			MarbleGame.canvas.pushDialog(remapDlg);
			remapDlg.remapCallback = (key) -> {
				MarbleGame.canvas.popDialog(remapDlg);

				if (key == Key.ESCAPE)
					return;

				var conflicting = getConflictingBinding(bindingName, key);
				if (conflicting == null) {
					ctrl.buttonText.text.text = '${bindingName}: ${Util.getKeyForButton2(key)}';
					bindingFunc(key);
				} else {
					var yesNoDlg = new MessageBoxYesNoDlg('"${Util.getKeyForButton2(key)}" is already bound to "${conflicting}"!<br/>Do you want to undo this mapping?',
						() -> {
						ctrl.buttonText.text.text = '${bindingName}: ${Util.getKeyForButton2(key)}';
						bindingFunc(key);
					}, () -> {});
					MarbleGame.canvas.pushDialog(yesNoDlg);
				}
			}
		}

		var scene2d = MarbleGame.canvas.scene2d;

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var subX = 640 - (scene2d.width - offsetX) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY) * 480 / scene2d.height;

		innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		innerCtrl.horizSizing = Width;
		innerCtrl.vertSizing = Height;
		this.addChild(innerCtrl);

		var coliseumfontdata = ResourceLoader.getFileEntry("data/font/ColiseumRR.fnt");
		var coliseumb = new BitmapFont(coliseumfontdata.entry);
		@:privateAccess coliseumb.loader = ResourceLoader.loader;
		var coliseum = coliseumb.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var rootTitle = new GuiText(coliseum);
		rootTitle.position = new Vector(100, 30);
		rootTitle.extent = new Vector(1120, 80);
		rootTitle.text.textColor = 0xFFFFFF;
		rootTitle.text.text = "KEY BINDINGS";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		btnListLeft = new GuiXboxList();
		btnListLeft.position = new Vector(70 - offsetX, 135);
		btnListLeft.horizSizing = Left;
		btnListLeft.extent = new Vector(502, 500);
		innerCtrl.addChild(btnListLeft);

		btnListRight = new GuiXboxList();
		btnListRight.position = new Vector(-400 - offsetX, 135);
		btnListRight.horizSizing = Left;
		btnListRight.extent = new Vector(502, 500);
		innerCtrl.addChild(btnListRight);

		var b1 = btnListRight.addButton(0, 'Move Forward: ${Util.getKeyForButton2(Settings.controlsSettings.forward)}', (e) -> {});
		b1.pressedAction = (e) -> {
			remapFunc("Move Forward", (key) -> Settings.controlsSettings.forward = key, b1);
		};

		var b2 = btnListRight.addButton(0, 'Move Backward: ${Util.getKeyForButton2(Settings.controlsSettings.backward)}', (e) -> {});
		b2.pressedAction = (e) -> {
			remapFunc("Move Backward", (key) -> Settings.controlsSettings.backward = key, b2);
		};
		var b3 = btnListRight.addButton(0, 'Move Left: ${Util.getKeyForButton2(Settings.controlsSettings.left)}', (e) -> {});
		b3.pressedAction = (e) -> {
			remapFunc("Move Left", (key) -> Settings.controlsSettings.left = key, b3);
		};
		var b4 = btnListRight.addButton(0, 'Move Right: ${Util.getKeyForButton2(Settings.controlsSettings.right)}', (e) -> {});
		b4.pressedAction = (e) -> {
			remapFunc("Move Right", (key) -> Settings.controlsSettings.right = key, b4);
		}
		var b5 = btnListRight.addButton(0, 'Jump: ${Util.getKeyForButton2(Settings.controlsSettings.jump)}', (e) -> {});
		b5.pressedAction = (e) -> {
			remapFunc("Jump", (key) -> Settings.controlsSettings.jump = key, b5);
		};
		var b6 = btnListRight.addButton(0, 'Blast: ${Util.getKeyForButton2(Settings.controlsSettings.blast)}', (e) -> {});
		b6.pressedAction = (e) -> {
			remapFunc("Blast", (key) -> Settings.controlsSettings.blast = key, b6);
		}
		var b7 = btnListLeft.addButton(0, 'Look Up: ${Util.getKeyForButton2(Settings.controlsSettings.camForward)}', (e) -> {});
		b7.pressedAction = (e) -> {
			remapFunc("Look Up", (key) -> Settings.controlsSettings.camForward = key, b7);
		}
		var b8 = btnListLeft.addButton(0, 'Look Down: ${Util.getKeyForButton2(Settings.controlsSettings.camBackward)}', (e) -> {});
		b8.pressedAction = (e) -> {
			remapFunc("Look Down", (key) -> Settings.controlsSettings.camBackward = key, b8);
		}
		var b9 = btnListLeft.addButton(0, 'Look Left: ${Util.getKeyForButton2(Settings.controlsSettings.camLeft)}', (e) -> {});
		b9.pressedAction = (e) -> {
			remapFunc("Look Left", (key) -> Settings.controlsSettings.camLeft = key, b9);
		}
		var b10 = btnListLeft.addButton(0, 'Look Right: ${Util.getKeyForButton2(Settings.controlsSettings.camRight)}', (e) -> {});
		b10.pressedAction = (e) -> {
			remapFunc("Look Right", (key) -> Settings.controlsSettings.camRight = key, b10);
		}
		var b11 = btnListLeft.addButton(0, 'Use Powerup: ${Util.getKeyForButton2(Settings.controlsSettings.powerup)}', (e) -> {});
		b11.pressedAction = (e) -> {
			remapFunc("Use Powerup", (key) -> Settings.controlsSettings.powerup = key, b11);
		}
		var b12 = btnListLeft.addButton(0, 'Rewind: ${Util.getKeyForButton2(Settings.controlsSettings.rewind)}', (e) -> {});
		b12.pressedAction = (e) -> {
			remapFunc("Rewind", (key) -> Settings.controlsSettings.rewind = key, b12);
		}

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Back", 160);
		backButton.position = new Vector(400, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = ["B"];
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		if (pauseGui)
			backButton.pressedAction = (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.canvas.pushDialog(new OptionsListGui(true));
			}
		else
			backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new OptionsListGui());
		bottomBar.addChild(backButton);
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		btnListLeft.position = new Vector(70 - offsetX, 135);
		btnListLeft.position = new Vector(-400 - offsetX, 135);

		super.onResize(width, height);
	}
}
