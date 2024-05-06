package gui;

import net.Net;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Util;

class MultiplayerLoadingGui extends GuiImage {
	var loadText:GuiText;
	var loadTextBg:GuiText;
	var loadAnim:GuiLoadAnim;
	var bottomBar:GuiControl;
	var innerCtrl:GuiControl;
	var backButton:GuiXboxButton;

	public function new(initialStatus:String) {
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

		loadAnim = new GuiLoadAnim();
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
		loadTextBg.text.text = initialStatus;
		loadTextBg.text.textColor = 0;
		this.addChild(loadTextBg);

		loadText = new GuiText(arial14);
		loadText.position = new Vector(610, 334);
		loadText.extent = new Vector(63, 40);
		loadText.horizSizing = Center;
		loadText.vertSizing = Bottom;
		loadText.justify = Center;
		loadText.text.text = initialStatus;
		this.addChild(loadText);

		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var subX = 640 - (scene2d.width - offsetX) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY) * 480 / scene2d.height;

		innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		innerCtrl.horizSizing = Width;
		innerCtrl.vertSizing = Height;
		this.addChild(innerCtrl);

		bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		backButton = new GuiXboxButton("Cancel", 160);
		backButton.position = new Vector(960, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = ["A"];
		backButton.accelerators = [hxd.Key.ENTER];
		backButton.pressedAction = (e) -> {
			Net.disconnect();
			MarbleGame.canvas.setContent(new MultiplayerGui());
		};
		bottomBar.addChild(backButton);
	}

	public function setLoadingStatus(str:String) {
		loadText.text.text = str;
		loadTextBg.text.text = str;
	}

	public function setErrorStatus(str:String) {
		loadText.text.text = str;
		loadTextBg.text.text = str;
		loadAnim.anim.visible = false;
		backButton.text.text.text = "Ok";
		backButton.pressedAction = (e) -> {
			MarbleGame.canvas.setContent(new MultiplayerGui());
		};

		MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);

		super.onResize(width, height);
	}
}
