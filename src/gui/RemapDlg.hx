package gui;

import hxd.Key;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Gamepad;

class RemapDlg extends GuiImage {
	var remapCallback:Int->Void;
	var controllerRemapCallback:String->Void;
	var controller:Bool;

	public function new(bindingName:String, controller:Bool = false) {
		var res = ResourceLoader.getImage("data/ui/xbox/roundedBG.png").resource.toTile();
		super(res);
		this.controller = controller;

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		var remapDlg = new GuiImage(ResourceLoader.getResource("data/ui/xbox/popupGUI.png", ResourceLoader.getImage, this.imageResources).toTile());
		remapDlg.horizSizing = Center;
		remapDlg.vertSizing = Center;
		remapDlg.position = new Vector(70, 30);
		remapDlg.extent = new Vector(512, 400);
		this.addChild(remapDlg);

		var remapText = new GuiMLText(arial14, null);
		remapText.position = new Vector(103, 85);
		remapText.extent = new Vector(313, 186);
		remapText.text.textColor = 0xEBEBEB;
		remapText.text.text = '<p align="center">Press a new key or button for <br/>"${bindingName}"</p>';
		remapDlg.addChild(remapText);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		if (controller) {
			var controllerKeys = [
				"A",
				"B",
				"X",
				"Y",
				"LB",
				"RB",
				"LT",
				"RT",
				"start",
				"back",
				"analogClick",
				"ranalogClick",
				"dpadUp",
				"dpadDown",
				"dpadLeft",
				"dpadRight"
			];

			for (key in controllerKeys) {
				if (Gamepad.isPressed([key])) {
					controllerRemapCallback(key);
					return;
				}
			}
			if (Key.isPressed(Key.ESCAPE))
				controllerRemapCallback("escape");
		} else {
			for (i in 0...1024) {
				if (i == Key.MOUSE_WHEEL_DOWN || i == Key.MOUSE_WHEEL_UP)
					continue;
				if (Key.isPressed(i)) {
					remapCallback(i);
				}
			}
		}
	}
}
