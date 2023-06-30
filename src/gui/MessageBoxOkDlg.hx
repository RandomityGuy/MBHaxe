package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class MessageBoxOkDlg extends GuiImage {
	public function new(text:String) {
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

		var okButton = new GuiXboxButton("Ok", 120);
		okButton.position = new Vector(211, 248);
		okButton.extent = new Vector(120, 94);
		okButton.vertSizing = Top;
		okButton.accelerator = hxd.Key.ENTER;
		okButton.gamepadAccelerator = ["A"];
		okButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
		}
		yesNoFrame.addChild(okButton);

		if (yesNoText.text.getBounds().yMax > yesNoText.extent.y) {
			var diff = yesNoText.text.getBounds().yMax - yesNoText.extent.y;
			yesNoFrame.extent.y += diff;
			okButton.position.y += diff;
		}
	}
}
