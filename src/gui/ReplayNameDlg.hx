package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class ReplayNameDlg extends GuiImage {
	public function new(callback:Void->Void) {
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

		var text = "Enter a name for the recording";

		var yesNoText = new GuiMLText(arial14, null);
		yesNoText.position = new Vector(103, 85);
		yesNoText.extent = new Vector(313, 186);
		yesNoText.text.text = text;
		yesNoText.text.textColor = 0xEBEBEB;
		yesNoFrame.addChild(yesNoText);

		var textFrame = new GuiControl();
		textFrame.position = new Vector(33, 107);
		textFrame.extent = new Vector(232, 40);
		textFrame.horizSizing = Center;
		yesNoFrame.addChild(textFrame);

		var textInput = new GuiTextInput(arial14);
		textInput.position = new Vector(6, 5);
		textInput.extent = new Vector(216, 40);
		textInput.horizSizing = Width;
		textInput.vertSizing = Height;
		textInput.text.textColor = 0xEBEBEB;
		textInput.setCaretColor(0xEBEBEB);
		textInput.text.selectionColor.setColor(0x8DFF8D);
		textInput.text.selectionTile = h2d.Tile.fromColor(0x88BCEE, 0, hxd.Math.ceil(textInput.text.font.lineHeight));
		textFrame.addChild(textInput);

		textInput.text.text = MarbleGame.instance.world.mission.title;
		if (MarbleGame.instance.world.finishTime == null) {
			textInput.text.text += " Unfinished Run";
		} else {
			textInput.text.text += " " + MarbleGame.instance.world.gameMode.getFinishScore();
		}

		var okButton = new GuiXboxButton("Ok", 120);
		okButton.position = new Vector(211, 248);
		okButton.extent = new Vector(120, 94);
		okButton.vertSizing = Top;
		okButton.accelerators = [hxd.Key.ENTER];
		okButton.gamepadAccelerator = [Settings.gamepadSettings.ok];
		okButton.pressedAction = (sender) -> {
			if (StringTools.trim(textInput.text.text) != "") {
				MarbleGame.instance.recordingName = textInput.text.text;
				MarbleGame.canvas.popDialog(this);
				MarbleGame.instance.world.saveReplay();
				callback();
			}
		}
		yesNoFrame.addChild(okButton);

		var cancelButton = new GuiXboxButton("Cancel", 120);
		cancelButton.position = new Vector(321, 248);
		cancelButton.extent = new Vector(120, 94);
		cancelButton.vertSizing = Top;
		cancelButton.accelerators = [hxd.Key.ENTER];
		cancelButton.gamepadAccelerator = [Settings.gamepadSettings.ok];
		cancelButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			callback();
		}
		yesNoFrame.addChild(cancelButton);
	}
}
