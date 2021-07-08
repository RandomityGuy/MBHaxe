package gui;

import hxd.Key;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;

class RemapDlg extends GuiControl {
	var remapCallback:Int->Void;

	public function new(bindingName:String) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var remapDlg = new GuiImage(ResourceLoader.getImage("data/ui/common/dialog.png").toTile());
		remapDlg.horizSizing = Center;
		remapDlg.vertSizing = Center;
		remapDlg.position = new Vector(170, 159);
		remapDlg.extent = new Vector(300, 161);
		this.addChild(remapDlg);

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasual24px.fnt");
		var domcasual24 = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24.loader = ResourceLoader.loader;

		var remapText = new GuiMLText(domcasual24, null);
		remapText.horizSizing = Center;
		remapText.vertSizing = Bottom;
		remapText.position = new Vector(46, 60);
		remapText.extent = new Vector(213, 23);
		remapText.text.textColor = 0;
		remapText.text.text = '<p align="center">Press a new key or button for <br/>"${bindingName}"</p>';
		remapDlg.addChild(remapText);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		for (i in 0...1024) {
			if (i == 5)
				continue;
			if (Key.isDown(i)) {
				remapCallback(i);
			}
		}
	}
}
