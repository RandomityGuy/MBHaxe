package gui;

import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;

class MessageBoxYesNoDlg extends GuiControl {
	public function new(text:String, yesFunc:Void->Void, noFunc:Void->Void) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var domcasual24fontdata = ResourceLoader.loader.load("data/font/DomCasual24px.fnt");
		var domcasual24 = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24.loader = ResourceLoader.loader;

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var yesNoFrame = new GuiImage(ResourceLoader.getImage("data/ui/common/dialog.png").toTile());
		yesNoFrame.horizSizing = Center;
		yesNoFrame.vertSizing = Center;
		yesNoFrame.position = new Vector(187, 156);
		yesNoFrame.extent = new Vector(265, 167);
		this.addChild(yesNoFrame);

		var yesNoText = new GuiMLText(domcasual24, null);
		yesNoText.position = new Vector(33, 46);
		yesNoText.horizSizing = Center;
		yesNoText.extent = new Vector(198, 23);
		yesNoText.text.text = text;
		yesNoText.text.textColor = 0;
		yesNoText.text.maxWidth = 198;
		yesNoFrame.addChild(yesNoText);

		var yesButton = new GuiButton(loadButtonImages("data/ui/common/yes"));
		yesButton.position = new Vector(44, 94);
		yesButton.extent = new Vector(82, 47);
		yesButton.vertSizing = Top;
		yesButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			yesFunc();
		}
		yesNoFrame.addChild(yesButton);

		var noButton = new GuiButton(loadButtonImages("data/ui/common/no"));
		noButton.position = new Vector(151, 94);
		noButton.extent = new Vector(75, 47);
		noButton.vertSizing = Top;
		noButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
			noFunc();
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
