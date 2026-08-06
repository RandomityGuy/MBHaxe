package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class MessageBoxOkDlg extends GuiControl {
	public function new(text:String, ?onOk:() -> Void) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(490, 225);
		wnd.extent = new Vector(300, 270);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var yesNoText = new GuiMLText(whatneyFont, null);
		yesNoText.position = new Vector(33, 46);
		yesNoText.horizSizing = Center;
		yesNoText.extent = new Vector(198, 23);
		yesNoText.text.text = text;
		yesNoText.text.textColor = 0;
		yesNoText.text.maxWidth = 198 * Settings.uiScale;
		wnd.addChild(yesNoText);

		var okButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		okButton.position = new Vector(101, 194);
		okButton.setExtent(new Vector(98, 49));
		okButton.vertSizing = Top;
		okButton.horizSizing = Center;
		okButton.accelerator = hxd.Key.ENTER;
		okButton.gamepadAccelerator = ["A"];
		okButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			if (onOk != null) {
				onOk();
			}
		}
		okButton.txtCtrl.text.text = "Ok";

		wnd.addChild(okButton);

		if (yesNoText.text.getBounds().yMax > yesNoText.extent.y) {
			var diff = yesNoText.text.getBounds().yMax - yesNoText.extent.y;
			wnd.extent.y += diff;
			okButton.position.y += diff;
		}
	}
}
