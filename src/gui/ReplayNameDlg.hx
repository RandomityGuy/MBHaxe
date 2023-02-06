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
		this.extent = new Vector(640, 480);

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual24b = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24b.loader = ResourceLoader.loader;
		var domcasual24 = domcasual24b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var yesNoFrame = new GuiImage(ResourceLoader.getResource("data/ui/common/dialog.png", ResourceLoader.getImage, this.imageResources).toTile());
		yesNoFrame.horizSizing = Center;
		yesNoFrame.vertSizing = Center;
		yesNoFrame.position = new Vector(187, 156);
		yesNoFrame.extent = new Vector(300, 191);
		this.addChild(yesNoFrame);

		var yesNoText = new GuiMLText(domcasual24, null);
		yesNoText.position = new Vector(33, 26);
		yesNoText.horizSizing = Center;
		yesNoText.extent = new Vector(198, 23);
		yesNoText.text.text = text;
		yesNoText.text.textColor = 0;
		yesNoText.text.maxWidth = 198;
		yesNoFrame.addChild(yesNoText);

		var textFrame = new GuiImage(ResourceLoader.getResource("data/ui/endgame/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		textFrame.position = new Vector(33, 67);
		textFrame.extent = new Vector(232, 40);
		textFrame.horizSizing = Center;
		yesNoFrame.addChild(textFrame);

		var textInput = new GuiTextInput(domcasual24);
		textInput.position = new Vector(6, 5);
		textInput.extent = new Vector(216, 40);
		textInput.horizSizing = Width;
		textInput.vertSizing = Height;
		textInput.text.textColor = 0;
		textInput.text.selectionColor.setColor(0xFFFFFFFF);
		textInput.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(textInput.text.font.lineHeight));
		textFrame.addChild(textInput);

		textInput.text.text = MarbleGame.instance.world.mission.title;
		if (MarbleGame.instance.world.finishTime == null) {
			textInput.text.text += " Unfinished Run";
		} else {
			textInput.text.text += " " + MarbleGame.instance.world.finishTime.gameplayClock;
		}

		var yesButton = new GuiButton(loadButtonImages("data/ui/common/ok"));
		yesButton.position = new Vector(171, 124);
		yesButton.extent = new Vector(95, 45);
		yesButton.vertSizing = Top;
		yesButton.accelerator = hxd.Key.ENTER;
		yesButton.pressedAction = (sender) -> {
			if (StringTools.trim(textInput.text.text) != "") {
				MarbleGame.instance.recordingName = textInput.text.text;
				MarbleGame.canvas.popDialog(this);
				MarbleGame.instance.world.saveReplay();
				callback();
			}
		}
		yesNoFrame.addChild(yesButton);

		var noButton = new GuiButton(loadButtonImages("data/ui/common/cancel"));
		noButton.position = new Vector(44, 124);
		noButton.extent = new Vector(88, 41);
		noButton.vertSizing = Top;
		noButton.accelerator = hxd.Key.ESCAPE;
		noButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			callback();
		}
		yesNoFrame.addChild(noButton);

		if (yesNoText.text.getBounds().yMax > yesNoText.extent.y) {
			var diff = yesNoText.text.getBounds().yMax - yesNoText.extent.y;
			yesNoFrame.extent.y += diff;
			yesButton.position.y += diff;
			noButton.position.y += diff;
		}
	}
}
