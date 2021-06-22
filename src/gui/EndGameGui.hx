package gui;

import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;

class EndGameGui extends GuiControl {
	public function new() {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(640, 480);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var pg = new GuiImage(ResourceLoader.getImage("data/ui/play/playgui.png").toTile());
		pg.horizSizing = Center;
		pg.vertSizing = Center;
		pg.position = new Vector(77, 9);
		pg.extent = new Vector(485, 461);

		var continueButton = new GuiButton(loadButtonImages("data/ui/endgame/continue"));
		continueButton.horizSizing = Right;
		continueButton.vertSizing = Bottom;
		continueButton.position = new Vector(333, 386);
		continueButton.extent = new Vector(113, 47);

		var restartButton = new GuiButton(loadButtonImages("data/ui/endgame/replay"));
		restartButton.horizSizing = Right;
		restartButton.vertSizing = Bottom;
		restartButton.position = new Vector(51, 388);
		restartButton.extent = new Vector(104, 48);

		var arial14fontdata = ResourceLoader.loader.load("data/font/Arial14.fnt");
		var arial14 = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14.loader = ResourceLoader.loader;

		var domcasual32fontdata = ResourceLoader.loader.load("data/font/DomCasual32px.fnt");
		var domcasual32 = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32.loader = ResourceLoader.loader;

		var expo50fontdata = ResourceLoader.loader.load("data/font/Expo50.fnt");
		var expo50 = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50.loader = ResourceLoader.loader;

		var expo32fontdata = ResourceLoader.loader.load("data/font/Expo32.fnt");
		var expo32 = new BitmapFont(expo32fontdata.entry);
		@:privateAccess expo32.loader = ResourceLoader.loader;

		var congrats = new GuiText(expo50);
		congrats.text.textColor = 0xffff00;
		congrats.text.text = "Final Time:";
		congrats.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0, 0.4, 1, true);
		congrats.position = new Vector(43, 17);
		congrats.extent = new Vector(208, 50);
		pg.addChild(congrats);

		var finishMessage = new GuiText(expo32);
		finishMessage.text.textColor = 0x00ff00;
		finishMessage.text.text = "You've qualified!";
		finishMessage.text.filter = new DropShadow(1, 0.785, 0, 1, 0, 0.4, 1, true);
		finishMessage.justify = Center;
		finishMessage.position = new Vector(155, 65);
		finishMessage.extent = new Vector(200, 100);
		pg.addChild(finishMessage);

		var leftColumn = new GuiText(domcasual32);
		leftColumn.text.textColor = 0x000000;
		leftColumn.text.text = "Qualify Time:\nGold Time:\nElapsed Time:\nBonus Time:";
		leftColumn.text.filter = new DropShadow(1.414, 0.785, 0xffffff, 1, 0, 0.4, 1, true);
		leftColumn.position = new Vector(108, 103);
		leftColumn.extent = new Vector(208, 50);
		pg.addChild(leftColumn);

		pg.addChild(continueButton);
		pg.addChild(restartButton);

		this.addChild(pg);
	}
}
