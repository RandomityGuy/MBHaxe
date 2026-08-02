package gui;

import hxd.Key;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class RemapDlg extends GuiControl {
	var remapCallback:Int->Void;

	public function new(bindingName:String) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(170, 159);
		wnd.extent = new Vector(300, 161);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);

		var remapText = new GuiMLText(whatneyFont, null);
		remapText.horizSizing = Center;
		remapText.vertSizing = Bottom;
		remapText.position = new Vector(46, 60);
		remapText.extent = new Vector(213, 23);
		remapText.text.textColor = 0;
		remapText.text.text = '<p align="center">Press a new key or button for <br/>"${bindingName}"</p>';
		wnd.addChild(remapText);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		for (i in 0...1024) {
			if (i == Key.MOUSE_WHEEL_DOWN || i == Key.MOUSE_WHEEL_UP)
				continue;
			if (Key.isPressed(i)) {
				remapCallback(i);
			}
		}
	}
}
