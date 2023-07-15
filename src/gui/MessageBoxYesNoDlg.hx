package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class MessageBoxYesNoDlg extends GuiImage {
	public function new(text:String, yesFunc:Void->Void, noFunc:Void->Void) {
		var res = ResourceLoader.getImage("data/ui/xbox/roundedBG.png").resource.toTile();
		super(res);
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		var yesNoFrame = new GuiImage(ResourceLoader.getResource("data/ui/xbox/popupGUI.png", ResourceLoader.getImage, this.imageResources).toTile());
		yesNoFrame.horizSizing = Center;
		yesNoFrame.vertSizing = Center;
		yesNoFrame.position = new Vector(70, 30);
		yesNoFrame.extent = new Vector(512, 400);
		this.addChild(yesNoFrame);

		var yesNoText = new GuiMLText(arial14, null);
		yesNoText.position = new Vector(103, 85);
		yesNoText.extent = new Vector(313, 186);
		yesNoText.text.text = text;
		yesNoText.text.textColor = 0xEBEBEB;
		yesNoFrame.addChild(yesNoText);

		var okButton = new GuiXboxButton("Yes", 120);
		okButton.position = new Vector(211, 248);
		okButton.extent = new Vector(120, 94);
		okButton.vertSizing = Top;
		okButton.accelerators = [hxd.Key.ENTER];
		okButton.gamepadAccelerator = ["A"];
		okButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			yesFunc();
		}
		yesNoFrame.addChild(okButton);

		var cancelButton = new GuiXboxButton("No", 120);
		cancelButton.position = new Vector(321, 248);
		cancelButton.extent = new Vector(120, 94);
		cancelButton.vertSizing = Top;
		cancelButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		cancelButton.gamepadAccelerator = ["B"];
		cancelButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			noFunc();
		}
		yesNoFrame.addChild(cancelButton);
	}
}
