package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class ReplayNameDlg extends GuiControl {
	public function new(callback:Void->Void) {
		super();
		var text = "Enter a name for the recording";
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);

		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(187, 156);
		wnd.extent = new Vector(300, 191);
		this.addChild(wnd);

		var yesNoText = new GuiMLText(whatneyFont, null);
		yesNoText.position = new Vector(33, 46);
		yesNoText.horizSizing = Center;
		yesNoText.extent = new Vector(198, 23);
		yesNoText.text.text = text;
		yesNoText.text.textColor = 0;
		yesNoText.text.maxWidth = 198 * Settings.uiScale;
		wnd.addChild(yesNoText);

		var boxbg = new GuiTransparencyCtrl("data/ui/transparency/75square");
		boxbg.position = new Vector(15, 103);
		boxbg.extent = new Vector(266, 55);
		wnd.addChild(boxbg);

		var textInput = new GuiTextInput(whatneyFont);
		textInput.position = new Vector(28, 120);
		textInput.extent = new Vector(236, 38);
		textInput.text.textColor = 0;
		textInput.text.selectionColor.setColor(0xFFFFFFFF);
		textInput.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(textInput.text.font.lineHeight));
		wnd.addChild(textInput);

		textInput.text.text = MarbleGame.instance.world.mission.title;
		if (MarbleGame.instance.world.finishTime == null) {
			textInput.text.text += " Unfinished Run";
		} else {
			textInput.text.text += " " + MarbleGame.instance.world.gameMode.getFinishScore().score;
		}

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
		yesButton.position = new Vector(171, 124);
		yesButton.setExtent(new Vector(98, 49));
		yesButton.vertSizing = Top;
		yesButton.accelerator = hxd.Key.ENTER;
		yesButton.gamepadAccelerator = ["A"];
		yesButton.pressedAction = (sender) -> {
			if (StringTools.trim(textInput.text.text) != "") {
				MarbleGame.instance.recordingName = textInput.text.text;
				MarbleGame.canvas.popDialog(this);
				MarbleGame.instance.world.saveReplay();
				callback();
			}
		}
		yesButton.txtCtrl.text.text = "Yes";

		wnd.addChild(yesButton);

		var noButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		noButton.position = new Vector(44, 124);
		noButton.setExtent(new Vector(98, 49));
		noButton.vertSizing = Top;
		noButton.accelerator = hxd.Key.ESCAPE;
		noButton.gamepadAccelerator = ["B"];
		noButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			callback();
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
