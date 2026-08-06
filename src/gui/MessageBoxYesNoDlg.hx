package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class MessageBoxYesNoDlg extends GuiControl {
	public function new(text:String, yesFunc:Void->Void, noFunc:Void->Void) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(187, 156);
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

		var yesButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		yesButton.position = new Vector(53, 194);
		yesButton.setExtent(new Vector(98, 49));
		yesButton.vertSizing = Top;
		yesButton.accelerator = hxd.Key.ENTER;
		yesButton.gamepadAccelerator = ["A"];
		yesButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			yesFunc();
		}
		yesButton.txtCtrl.text.text = "Yes";

		wnd.addChild(yesButton);

		var noButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		noButton.position = new Vector(149, 194);
		noButton.setExtent(new Vector(98, 49));
		noButton.vertSizing = Top;
		noButton.accelerator = hxd.Key.ESCAPE;
		noButton.gamepadAccelerator = ["B"];
		noButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			noFunc();
		}
		noButton.txtCtrl.text.text = "No";

		wnd.addChild(noButton);

		if (yesNoText.text.getBounds().yMax > yesNoText.extent.y) {
			var diff = yesNoText.text.getBounds().yMax - yesNoText.extent.y;
			wnd.extent.y += diff;
			yesButton.position.y += diff;
			noButton.position.y += diff;
		}
	}
}
