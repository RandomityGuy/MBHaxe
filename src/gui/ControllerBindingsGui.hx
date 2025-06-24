package gui;

import src.Gamepad;
import gui.GuiControl.MouseState;
import hxd.Key;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;

class ControllerBindingsGui extends GuiImage {
	var innerCtrl:GuiControl;
	var btnListLeft:GuiXboxList;
	var btnListRight:GuiXboxList;

	var selectedColumn = 0;
	var _prevMousePosition:Vector;

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

		function getConflictingBinding(bindingName:String, key:String) {
			// For menu bindings, it's independent of the game stuff
			if (["Menu OK", "Menu Back", "Menu Alt 1", "Menu Alt 2"].indexOf(bindingName) != -1) {
				if (Settings.gamepadSettings.ok == key && bindingName != "Menu OK")
					return "Menu OK";
				if (Settings.gamepadSettings.back == key && bindingName != "Menu Back")
					return "Menu Back";
				if (Settings.gamepadSettings.alt1 == key && bindingName != "Menu Alt 1")
					return "Menu Alt 1";
				if (Settings.gamepadSettings.alt2 == key && bindingName != "Menu Alt 2")
					return "Menu Alt 2";
			} else {
				if (Settings.gamepadSettings.jump[0] == key && bindingName != "Jump")
					return "Jump";
				if (Settings.gamepadSettings.jump[1] == key && bindingName != "Jump")
					return "Jump";
				if (Settings.gamepadSettings.blast[0] == key && bindingName != "Blast")
					return "Blast";
				if (Settings.gamepadSettings.blast[1] == key && bindingName != "Blast")
					return "Blast";
				if (Settings.gamepadSettings.powerup[0] == key && bindingName != "Use Powerup")
					return "Use Powerup";
				if (Settings.gamepadSettings.powerup[1] == key && bindingName != "Use Powerup")
					return "Use Powerup";
				if (Settings.gamepadSettings.rewind[0] == key && bindingName != "Rewind")
					return "Rewind";
				if (Settings.gamepadSettings.rewind[1] == key && bindingName != "Rewind")
					return "Rewind";
			}

			return null;
		}

		function remapFunc(bindingName:String, bindingFunc:String->Void, ctrl:GuiXboxListButton) {
			var remapDlg = new RemapDlg(bindingName, true);
			MarbleGame.canvas.pushDialog(remapDlg);
			remapDlg.controllerRemapCallback = (key) -> {
				MarbleGame.canvas.popDialog(remapDlg);

				if (key == "escape")
					return;

				var conflicting = getConflictingBinding(bindingName, key);
				if (conflicting == null) {
					ctrl.buttonText.text.text = '${bindingName}: ${key}';
					bindingFunc(key);
				} else {
					var yesNoDlg = new MessageBoxYesNoDlg('"${key}" is already bound to "${conflicting}"!<br/>Do you want to undo this mapping?', () -> {
						ctrl.buttonText.text.text = '${bindingName}: ${key}';
						bindingFunc(key);
					}, () -> {});
					MarbleGame.canvas.pushDialog(yesNoDlg);
				}
			}
		}

		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if (js || uwp)
		var scene2d = MarbleGame.instance.scene2d;
		#end

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
		rootTitle.text.text = "CONTROLLER BINDINGS";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		btnListLeft = new GuiXboxList();
		btnListLeft.position = new Vector(70 - offsetX, 135);
		btnListLeft.horizSizing = Left;
		btnListLeft.extent = new Vector(502, 500);
		btnListLeft.active = false;
		innerCtrl.addChild(btnListLeft);

		btnListRight = new GuiXboxList();
		btnListRight.position = new Vector(-400 - offsetX, 135);
		btnListRight.horizSizing = Left;
		btnListRight.extent = new Vector(502, 500);
		innerCtrl.addChild(btnListRight);

		var b1 = btnListRight.addButton(0, 'Menu OK: ${Settings.gamepadSettings.ok}', (e) -> {});
		b1.pressedAction = (e) -> {
			remapFunc("Menu OK", (key) -> Settings.gamepadSettings.ok = key, b1);
		};

		var b2 = btnListLeft.addButton(0, 'Menu Back: ${Settings.gamepadSettings.back}', (e) -> {});
		b2.pressedAction = (e) -> {
			remapFunc("Menu Back", (key) -> Settings.gamepadSettings.back = key, b2);
		};
		var b3 = btnListRight.addButton(0, 'Menu Alt 1: ${Settings.gamepadSettings.alt1}', (e) -> {});
		b3.pressedAction = (e) -> {
			remapFunc("Menu Alt 1", (key) -> Settings.gamepadSettings.alt1 = key, b3);
		};
		var b4 = btnListLeft.addButton(0, 'Menu Alt 2: ${Settings.gamepadSettings.alt2}', (e) -> {});
		b4.pressedAction = (e) -> {
			remapFunc("Move Right", (key) -> Settings.gamepadSettings.alt2 = key, b4);
		}
		var b5 = btnListRight.addButton(0, 'Jump: ${Settings.gamepadSettings.jump[0]}', (e) -> {});
		b5.pressedAction = (e) -> {
			remapFunc("Jump", (key) -> Settings.gamepadSettings.jump[0] = key, b5);
		};
		var b5 = btnListLeft.addButton(0, 'Jump: ${Settings.gamepadSettings.jump[1]}', (e) -> {});
		b5.pressedAction = (e) -> {
			remapFunc("Jump", (key) -> Settings.gamepadSettings.jump[1] = key, b5);
		};
		var b6 = btnListRight.addButton(0, 'Blast: ${Settings.gamepadSettings.blast[0]}', (e) -> {});
		b6.pressedAction = (e) -> {
			remapFunc("Blast", (key) -> Settings.gamepadSettings.blast[0] = key, b6);
		}
		var b6 = btnListLeft.addButton(0, 'Blast: ${Settings.gamepadSettings.blast[1]}', (e) -> {});
		b6.pressedAction = (e) -> {
			remapFunc("Blast", (key) -> Settings.gamepadSettings.blast[1] = key, b6);
		}
		var b11 = btnListRight.addButton(0, 'Use Powerup: ${Settings.gamepadSettings.powerup[0]}', (e) -> {});
		b11.pressedAction = (e) -> {
			remapFunc("Use Powerup", (key) -> Settings.gamepadSettings.powerup[0] = key, b11);
		}
		var b11 = btnListLeft.addButton(0, 'Use Powerup: ${Settings.gamepadSettings.powerup[1]}', (e) -> {});
		b11.pressedAction = (e) -> {
			remapFunc("Use Powerup", (key) -> Settings.gamepadSettings.powerup[1] = key, b11);
		}
		var b12 = btnListRight.addButton(0, 'Rewind: ${Settings.gamepadSettings.rewind[0]}', (e) -> {});
		b12.pressedAction = (e) -> {
			remapFunc("Rewind", (key) -> Settings.gamepadSettings.rewind[0] = key, b12);
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
				MarbleGame.canvas.pushDialog(new InputSelectGui(true));
			}
		else
			backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new InputSelectGui());
		bottomBar.addChild(backButton);
	}

	override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		var prevSelected = selectedColumn;
		if (Key.isPressed(Key.RIGHT) || Gamepad.isPressed(["dpadRight"]))
			selectedColumn++;
		if (Key.isPressed(Key.LEFT) || Gamepad.isPressed(["dpadLeft"]))
			selectedColumn++;
		if (selectedColumn < 0)
			selectedColumn = 1;
		if (selectedColumn > 1)
			selectedColumn = 0;
		if (selectedColumn == 1) {
			btnListLeft.active = true;
			btnListRight.active = false;
		} else {
			btnListLeft.active = false;
			btnListRight.active = true;
		}
		if (prevSelected == 0 && selectedColumn == 1) {
			btnListLeft.selected = btnListRight.selected;
			if (btnListLeft.selected > btnListLeft.buttons.length - 1)
				btnListLeft.selected = btnListLeft.buttons.length - 1;
		}
		if (prevSelected == 1 && selectedColumn == 0) {
			btnListRight.selected = btnListLeft.selected;
			if (btnListRight.selected > btnListRight.buttons.length - 1)
				btnListRight.selected = btnListRight.buttons.length - 1;
		}
		if (_prevMousePosition == null || !_prevMousePosition.equals(mouseState.position)) {
			for (i in 0...btnListLeft.buttons.length) {
				var btn = btnListLeft.buttons[i];
				var renderRect = btn.getHitTestRect();
				renderRect.position = renderRect.position.add(new Vector(24, 20)); // Offset
				renderRect.extent.set(439, 53);
				if (renderRect.inRect(mouseState.position)) {
					selectedColumn = 1;
					btnListLeft.selected = i;
					btnListLeft.active = true;
					btnListRight.active = false;
					break;
				}
			}
			for (i in 0...btnListRight.buttons.length) {
				var btn = btnListRight.buttons[i];
				var renderRect = btn.getHitTestRect();
				renderRect.position = renderRect.position.add(new Vector(24, 20)); // Offset
				renderRect.extent.set(439, 53);
				if (renderRect.inRect(mouseState.position)) {
					selectedColumn = 0;
					btnListRight.selected = i;
					btnListRight.active = true;
					btnListLeft.active = false;
					break;
				}
			}
			_prevMousePosition = mouseState.position.clone();
		}
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
