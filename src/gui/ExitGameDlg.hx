package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;

class ExitGameDlg extends GuiControl {
	public function new(yesFunc:GuiControl->Void, noFunc:GuiControl->Void, restartFunc:GuiControl->Void) {
		super();

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var dialogImg = new GuiImage(ResourceLoader.getImage("data/ui/common/dialog.png").toTile());
		dialogImg.horizSizing = Center;
		dialogImg.vertSizing = Center;
		dialogImg.position = new Vector(134, 148);
		dialogImg.extent = new Vector(388, 186);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasual32px.fnt");
		var domcasual32 = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32.loader = ResourceLoader.loader;

		var exitGameText = new GuiText(domcasual32);
		exitGameText.text.textColor = 0x000000;
		exitGameText.text.text = "Exit from this Level?";
		exitGameText.justify = Center;
		exitGameText.position = new Vector(95, 46);
		exitGameText.extent = new Vector(198, 23);
		exitGameText.horizSizing = Center;
		exitGameText.vertSizing = Bottom;

		var yesButton = new GuiButton(loadButtonImages("data/ui/common/yes"));
		yesButton.position = new Vector(47, 107);
		yesButton.extent = new Vector(88, 52);
		yesButton.vertSizing = Top;
		yesButton.horizSizing = Right;
		yesButton.pressedAction = yesFunc;

		var noButton = new GuiButton(loadButtonImages("data/ui/common/no"));
		noButton.position = new Vector(151, 107);
		noButton.extent = new Vector(83, 55);
		noButton.vertSizing = Top;
		noButton.horizSizing = Right;
		noButton.pressedAction = noFunc;

		var restartButton = new GuiButton(loadButtonImages("data/ui/common/restart"));
		restartButton.position = new Vector(249, 107);
		restartButton.extent = new Vector(103, 56);
		restartButton.vertSizing = Top;
		restartButton.horizSizing = Right;
		restartButton.pressedAction = restartFunc;

		dialogImg.addChild(exitGameText);
		dialogImg.addChild(yesButton);
		dialogImg.addChild(noButton);
		dialogImg.addChild(restartButton);

		this.addChild(dialogImg);
	}
}
