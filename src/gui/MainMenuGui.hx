package gui;

import src.MarbleGame;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;

class MainMenuGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/background.jpg");
		super(img.resource.toTile());
		var fontdata = ResourceLoader.getFileEntry("data/font/DomCasual32px.fnt");
		var bfont = new BitmapFont(fontdata.entry);
		@:privateAccess bfont.loader = ResourceLoader.loader;

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var versionText = new GuiText(bfont);
		versionText.horizSizing = Center;
		versionText.vertSizing = Top;
		versionText.position = new Vector(289, 457);
		versionText.extent = new Vector(62, 18);
		versionText.text.text = "1.0.0";
		this.addChild(versionText);

		var homebase = new GuiImage(ResourceLoader.getResource("data/ui/home/homegui.png", ResourceLoader.getImage, this.imageResources).toTile());
		homebase.horizSizing = Center;
		homebase.vertSizing = Center;
		homebase.extent = new Vector(349, 477);
		homebase.position = new Vector(145, 1);
		this.addChild(homebase);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var playButton = new GuiButton(loadButtonImages("data/ui/home/play"));
		playButton.position = new Vector(50, 113);
		playButton.extent = new Vector(270, 95);
		playButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new PlayMissionGui());
		}
		homebase.addChild(playButton);

		var helpButton = new GuiButton(loadButtonImages("data/ui/home/help"));
		helpButton.position = new Vector(59, 200);
		helpButton.extent = new Vector(242, 84);
		helpButton.pressedAction = (sender) -> {
			MarbleGame.canvas.setContent(new HelpCreditsGui());
		}
		homebase.addChild(helpButton);

		var optionsButton = new GuiButton(loadButtonImages("data/ui/home/options"));
		optionsButton.position = new Vector(55, 279);
		optionsButton.extent = new Vector(253, 83);
		optionsButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new OptionsDlg());
		}
		homebase.addChild(optionsButton);

		var exitButton = new GuiButton(loadButtonImages("data/ui/home/exit"));
		exitButton.position = new Vector(82, 358);
		exitButton.extent = new Vector(203, 88);
		exitButton.pressedAction = (sender) -> {
			#if hl
			Sys.exit(0);
			#end
		};
		homebase.addChild(exitButton);
	}
}
