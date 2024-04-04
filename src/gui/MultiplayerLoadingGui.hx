package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Util;

class MultiplayerLoadingGui extends GuiImage {
	var loadText:GuiText;
	var loadTextBg:GuiText;

	public function new(missionName:String) {
		var res = ResourceLoader.getImage("data/ui/game/CloudBG.jpg").resource.toTile();
		super(res);
		this.position = new Vector();
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;

		var fadeEdge = new GuiImage(ResourceLoader.getResource("data/ui/xbox/BG_fadeOutSoftEdge.png", ResourceLoader.getImage, this.imageResources).toTile());
		fadeEdge.position = new Vector(0, 0);
		fadeEdge.extent = new Vector(640, 480);
		fadeEdge.vertSizing = Height;
		fadeEdge.horizSizing = Width;
		this.addChild(fadeEdge);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		var loadAnim = new GuiLoadAnim();
		loadAnim.position = new Vector(610, 253);
		loadAnim.extent = new Vector(63, 63);
		loadAnim.horizSizing = Center;
		loadAnim.vertSizing = Bottom;
		this.addChild(loadAnim);

		loadTextBg = new GuiText(arial14);
		loadTextBg.position = new Vector(608, 335);
		loadTextBg.extent = new Vector(63, 40);
		loadTextBg.horizSizing = Center;
		loadTextBg.vertSizing = Bottom;
		loadTextBg.justify = Center;
		loadTextBg.text.text = "Loading";
		loadTextBg.text.textColor = 0;
		this.addChild(loadTextBg);

		loadText = new GuiText(arial14);
		loadText.position = new Vector(610, 334);
		loadText.extent = new Vector(63, 40);
		loadText.horizSizing = Center;
		loadText.vertSizing = Bottom;
		loadText.justify = Center;
		loadText.text.text = "Loading";
		this.addChild(loadText);
	}

	public function setLoadingStatus(str:String) {
		loadText.text.text = str;
		loadTextBg.text.text = str;
	}
}
