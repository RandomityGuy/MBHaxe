package gui;

import h3d.Matrix;
import src.ProfilerUI;
import hxd.App;
import hxd.res.Image;
import hxd.Window;
import h3d.shader.AlphaMult;
import h3d.shader.ColorKey;
import hxd.snd.WavData;
import gui.GuiControl.HorizSizing;
import src.TimeState;
import format.gif.Data.Block;
import hxd.res.BitmapFont;
import h2d.Text;
import h3d.Vector;
import hxd.fmt.hmd.Data.AnimationEvent;
import h2d.Tile;
import h3d.mat.DepthBuffer;
import h3d.mat.Texture;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.prim.Cube;
import src.DtsObject;
import h2d.Anim;
import h2d.Bitmap;
import src.ResourceLoader;
import src.MarbleGame;
import src.Resource;
import hxd.res.Sound;
import h3d.mat.Texture;
import src.Settings;
import src.Util;

typedef MiddleMessage = {
	ctrl:GuiText,
	age:Float,
	yPos:Float
}

typedef PlayerInfo = {
	id:Int,
	name:String,
	us:Bool,
	score:Int
}

class PlayGui {
	var scene2d:h2d.Scene;

	public function new() {}

	var timerNumbers:Array<GuiAnim> = [];
	var timerPoint:GuiImage;
	var timerColon:GuiImage;

	var gemCountNumbers:Array<GuiAnim> = [];
	var gemCountSlash:GuiImage;
	var gemHUD:GuiImage;
	var powerupBox:GuiAnim;
	var centerText:GuiText;
	var centerTextBg:GuiImage;

	var helpTextForeground:GuiText;
	var helpTextBackground:GuiText;
	var alertTextForeground:GuiText;
	var alertTextBackground:GuiText;

	var blastBar:GuiControl;
	var blastFill:GuiImage;
	var blastFillUltra:GuiImage;
	var blastFrame:GuiImage;

	var playerListContainerOuter:GuiControl;
	var playerListContainer:GuiControl;
	var playerListCtrl:GuiMLTextListCtrl;
	var playerListScoresCtrl:GuiMLTextListCtrl;
	var playerList:Array<PlayerInfo> = [];

	var imageResources:Array<Resource<Image>> = [];
	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var playGuiCtrlOuter:GuiControl;
	var playGuiCtrl:GuiControl;

	var resizeEv:Void->Void;
	var resizeControlEvents:Array<Void->Void> = [];

	var _init:Bool;

	var fpsMeter:GuiText;

	var middleMessages:Array<MiddleMessage> = [];

	var totalGems:Int = 0;

	public function dispose() {
		if (_init) {
			playGuiCtrlOuter.dispose();

			for (textureResource in textureResources) {
				textureResource.release();
			}
			for (imageResource in imageResources) {
				imageResource.release();
			}
			for (audioResource in soundResources) {
				audioResource.release();
			}

			Window.getInstance().removeResizeEvent(resizeEv);
		}
	}

	public function init(scene2d:h2d.Scene, game:String, onFinish:Void->Void) {
		this.scene2d = scene2d;
		this._init = true;
		// Settings.uiScale = 2.25;

		playGuiCtrlOuter = new GuiControl();
		playGuiCtrlOuter.position = new Vector();
		playGuiCtrlOuter.extent = new Vector(640, 480);
		playGuiCtrlOuter.horizSizing = Width;
		playGuiCtrlOuter.vertSizing = Height;

		#if hl
		var wnd = hxd.Window.getInstance();
		#end
		#if js
		var wnd = MarbleGame.instance.scene2d;
		#end

		var safeVerMargin = 1 + (wnd.height * 0.15) / 2;
		var safeHorMargin = 1 + (wnd.width * 0.15) / 2;

		playGuiCtrl = new GuiControl();
		playGuiCtrl.position = new Vector(safeHorMargin, safeVerMargin);

		var subX = 640 - (wnd.width - safeHorMargin * 2) * 640 / wnd.width;
		var subY = 480 - (wnd.height - safeVerMargin * 2) * 480 / wnd.height;

		playGuiCtrl.extent = new Vector(640 - subX, 480 - subY);
		playGuiCtrl.horizSizing = Width;
		playGuiCtrl.vertSizing = Height;
		playGuiCtrlOuter.addChild(playGuiCtrl);

		var numberTiles = [];
		for (i in 0...10) {
			var tile = ResourceLoader.getResource('data/ui/game/numbers/${i}.png', ResourceLoader.getImage, this.imageResources).toTile();
			numberTiles.push(tile);
		}

		for (i in 0...7) {
			timerNumbers.push(new GuiAnim(numberTiles));
		}

		for (i in 0...6) {
			gemCountNumbers.push(new GuiAnim(numberTiles));
		}
		initTimer();
		if (!MarbleGame.instance.world.isMultiplayer)
			initGemCounter();
		initPowerupBox();
		if (game == 'ultra')
			initBlastBar();
		initTexts();
		if (MarbleGame.instance.world.isMultiplayer)
			initPlayerList();
		// if (Settings.optionsSettings.frameRateVis)
		// 	initFPSMeter();

		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.showControls(this.playGuiCtrlOuter, game == 'ultra');
		}

		playGuiCtrlOuter.render(scene2d);

		resizeEv = () -> {
			var safeVerMargin = 1 + (wnd.height * 0.15) / 2;
			var safeHorMargin = 1 + (wnd.width * 0.15) / 2;
			playGuiCtrl.position = new Vector(safeHorMargin, safeVerMargin);

			var subX = 640 - (wnd.width - safeHorMargin * 2) * 640 / wnd.width;
			var subY = 480 - (wnd.height - safeVerMargin * 2) * 480 / wnd.height;

			playGuiCtrl.extent = new Vector(640 - subX, 480 - subY);
			resizeControls();

			playGuiCtrlOuter.render(MarbleGame.canvas.scene2d);
		};

		Window.getInstance().addResizeEvent(resizeEv);

		onFinish();
	}

	function resizeControls() {
		for (resizeControl in resizeControlEvents) {
			resizeControl();
		}
	}

	public function initTimer() {
		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end
		var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;

		var timerCtrl = new GuiImage(ResourceLoader.getResource('data/ui/game/timebackdrop0.png', ResourceLoader.getImage, this.imageResources).toTile());
		timerCtrl.position = new Vector(215, 0);
		timerCtrl.extent = new Vector(256, 64);
		timerCtrl.horizSizing = Center;
		timerCtrl.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerCtrl.yScale = (scene2d.height - safeVerMargin * 2) / 480;

		var innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(26, 0);
		innerCtrl.extent = new Vector(256, 64);
		innerCtrl.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		innerCtrl.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerCtrl.addChild(innerCtrl);

		timerNumbers[0].position = new Vector(20, 4);
		timerNumbers[0].extent = new Vector(43, 55);
		timerNumbers[0].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerNumbers[0].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		timerNumbers[1].position = new Vector(40, 4);
		timerNumbers[1].extent = new Vector(43, 55);
		timerNumbers[1].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerNumbers[1].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		var colonCols = ResourceLoader.getResource('data/ui/game/numbers/colon.png', ResourceLoader.getImage, this.imageResources).toTile();

		timerColon = new GuiImage(colonCols);
		timerColon.position = new Vector(55, 4);
		timerColon.extent = new Vector(43, 55);
		timerColon.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerColon.yScale = (scene2d.height - safeVerMargin * 2) / 480;

		timerNumbers[2].position = new Vector(70, 4);
		timerNumbers[2].extent = new Vector(43, 55);
		timerNumbers[2].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerNumbers[2].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		timerNumbers[3].position = new Vector(90, 4);
		timerNumbers[3].extent = new Vector(43, 55);
		timerNumbers[3].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerNumbers[3].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		var pointCols = ResourceLoader.getResource('data/ui/game/numbers/point.png', ResourceLoader.getImage, this.imageResources).toTile();

		timerPoint = new GuiImage(pointCols);
		timerPoint.position = new Vector(105, 4);
		timerPoint.extent = new Vector(43, 55);
		timerPoint.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerPoint.yScale = (scene2d.height - safeVerMargin * 2) / 480;

		timerNumbers[4].position = new Vector(120, 4);
		timerNumbers[4].extent = new Vector(43, 55);
		timerNumbers[4].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerNumbers[4].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		timerNumbers[5].position = new Vector(140, 4);
		timerNumbers[5].extent = new Vector(43, 55);
		timerNumbers[5].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		timerNumbers[5].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		timerNumbers[6].position = new Vector(191, 0);
		timerNumbers[6].extent = new Vector(43, 55);

		innerCtrl.addChild(timerNumbers[0]);
		innerCtrl.addChild(timerNumbers[1]);
		innerCtrl.addChild(timerColon);
		innerCtrl.addChild(timerNumbers[2]);
		innerCtrl.addChild(timerNumbers[3]);
		innerCtrl.addChild(timerPoint);
		innerCtrl.addChild(timerNumbers[4]);
		innerCtrl.addChild(timerNumbers[5]);
		// innerCtrl.addChild(timerNumbers[6]);

		resizeControlEvents.push(() -> {
			var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;
			innerCtrl.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			innerCtrl.yScale = (scene2d.height - safeVerMargin * 2) / 480;
			for (i in 0...6) {
				timerNumbers[i].xScale = (scene2d.height - safeVerMargin * 2) / 480;
				timerNumbers[i].yScale = (scene2d.height - safeVerMargin * 2) / 480;
			}
			timerColon.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			timerColon.yScale = (scene2d.height - safeVerMargin * 2) / 480;

			timerPoint.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			timerPoint.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		});

		playGuiCtrl.addChild(timerCtrl);
	}

	public function setCenterText(text:String) {
		if (text != "") {
			centerText.text.text = text;
			centerText.text.visible = true;
			centerTextBg.bmp.visible = true;
		} else {
			centerText.text.visible = false;
			centerTextBg.bmp.visible = false;
		}
	}

	public function initGemCounter() {
		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end
		var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;

		var gemBox = new GuiControl();
		gemBox.position = new Vector(0, 0);
		gemBox.extent = new Vector(300, 200);
		gemBox.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemBox.yScale = (scene2d.height - safeVerMargin * 2) / 480;

		var innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(26, 0);
		innerCtrl.extent = new Vector(256, 64);
		innerCtrl.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		innerCtrl.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemBox.addChild(innerCtrl);

		gemCountNumbers[0].position = new Vector(20, 4);
		gemCountNumbers[0].extent = new Vector(43, 55);
		gemCountNumbers[0].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemCountNumbers[0].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		gemCountNumbers[1].position = new Vector(38, 4);
		gemCountNumbers[1].extent = new Vector(43, 55);
		gemCountNumbers[1].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemCountNumbers[1].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		gemCountNumbers[2].position = new Vector(56, 4);
		gemCountNumbers[2].extent = new Vector(43, 55);
		gemCountNumbers[2].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemCountNumbers[2].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		gemCountSlash = new GuiImage(ResourceLoader.getResource('data/ui/game/numbers/slash.png', ResourceLoader.getImage, this.imageResources).toTile());
		gemCountSlash.position = new Vector(73, 4);
		gemCountSlash.extent = new Vector(43, 55);
		gemCountSlash.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemCountSlash.yScale = (scene2d.height - safeVerMargin * 2) / 480;

		gemCountNumbers[3].position = new Vector(89, 4);
		gemCountNumbers[3].extent = new Vector(43, 55);
		gemCountNumbers[3].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemCountNumbers[3].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		gemCountNumbers[4].position = new Vector(107, 4);
		gemCountNumbers[4].extent = new Vector(43, 55);
		gemCountNumbers[4].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemCountNumbers[4].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		gemCountNumbers[5].position = new Vector(125, 4);
		gemCountNumbers[5].extent = new Vector(43, 55);
		gemCountNumbers[5].xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemCountNumbers[5].yScale = (scene2d.height - safeVerMargin * 2) / 480;

		gemHUD = new GuiImage(ResourceLoader.getResource('data/ui/game/gem.png', ResourceLoader.getImage, this.imageResources).toTile());
		gemHUD.position = new Vector(144, 2);
		gemHUD.extent = new Vector(64, 64);
		gemHUD.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		gemHUD.yScale = (scene2d.height - safeVerMargin * 2) / 480;

		innerCtrl.addChild(gemCountNumbers[0]);
		innerCtrl.addChild(gemCountNumbers[1]);
		innerCtrl.addChild(gemCountNumbers[2]);
		innerCtrl.addChild(gemCountSlash);
		innerCtrl.addChild(gemCountNumbers[3]);
		innerCtrl.addChild(gemCountNumbers[4]);
		innerCtrl.addChild(gemCountNumbers[5]);
		innerCtrl.addChild(gemHUD);

		resizeControlEvents.push(() -> {
			var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;
			gemBox.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			gemBox.yScale = (scene2d.height - safeVerMargin * 2) / 480;
			innerCtrl.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			innerCtrl.yScale = (scene2d.height - safeVerMargin * 2) / 480;
			for (i in 0...6) {
				gemCountNumbers[i].xScale = (scene2d.height - safeVerMargin * 2) / 480;
				gemCountNumbers[i].yScale = (scene2d.height - safeVerMargin * 2) / 480;
			}
			gemHUD.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			gemHUD.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		});

		playGuiCtrl.addChild(gemBox);
		// gemImageSceneTargetBitmap.blendMode = None;
		// gemImageSceneTargetBitmap.addShader(new ColorKey());
	}

	function initPowerupBox() {
		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end
		var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;

		var powerupImgs = [
			ResourceLoader.getResource('data/ui/game/pc/powerup.png', ResourceLoader.getImage, this.imageResources).toTile(),
			ResourceLoader.getResource('data/ui/game/pc/powerup_copter.png', ResourceLoader.getImage, this.imageResources).toTile(),
			ResourceLoader.getResource('data/ui/game/pc/powerup_jump.png', ResourceLoader.getImage, this.imageResources).toTile(),
			ResourceLoader.getResource('data/ui/game/pc/powerup_mega.png', ResourceLoader.getImage, this.imageResources).toTile(),
			ResourceLoader.getResource('data/ui/game/pc/powerup_speed.png', ResourceLoader.getImage, this.imageResources).toTile(),
		];

		powerupBox = new GuiAnim(powerupImgs);
		// powerupBox.position = new Vector(469, 0);
		powerupBox.position = new Vector(playGuiCtrl.extent.x - 171, 0);
		powerupBox.extent = new Vector(170, 170);
		powerupBox.horizSizing = Left;
		powerupBox.vertSizing = Bottom;
		powerupBox.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		powerupBox.yScale = (scene2d.height - safeVerMargin * 2) / 480;

		resizeControlEvents.push(() -> {
			var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;
			powerupBox.position = new Vector(playGuiCtrl.extent.x - 171, 0);
			powerupBox.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			powerupBox.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		});

		playGuiCtrl.addChild(powerupBox);
	}

	function initTexts() {
		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var coliseumfontdata = ResourceLoader.getFileEntry("data/font/ColiseumRR.fnt");
		var coliseumb = new BitmapFont(coliseumfontdata.entry);
		@:privateAccess coliseumb.loader = ResourceLoader.loader;
		var coliseum = coliseumb.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var centerTextCtrl = new GuiControl();
		centerTextCtrl.position = new Vector(0, 0);
		centerTextCtrl.extent = new Vector(640, 480);
		centerTextCtrl.vertSizing = Center;
		centerTextCtrl.horizSizing = Center;

		var centerTextBitmap = new GuiImage(ResourceLoader.getResource("data/ui/xbox/bgShadeCircle.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		centerTextBitmap.position = new Vector(225, 142);
		centerTextBitmap.extent = new Vector(200, 64);
		centerTextBitmap.vertSizing = Bottom;
		centerTextBitmap.horizSizing = Left;
		centerTextBg = centerTextBitmap;
		centerTextCtrl.addChild(centerTextBitmap);

		var centerTextText = new GuiText(coliseum);
		centerTextText.text.textColor = 0xEBEBEB;
		centerTextText.position = new Vector(0, 146);
		centerTextText.extent = new Vector(640, 80);
		centerTextText.vertSizing = Bottom;
		centerTextText.horizSizing = Left;
		centerTextText.justify = Center;
		centerTextCtrl.addChild(centerTextText);
		centerText = centerTextText;

		playGuiCtrlOuter.addChild(centerTextCtrl);

		var helpTextCtrl = new GuiControl();
		helpTextCtrl.position = new Vector(0, playGuiCtrl.extent.y * 190 / 480);
		helpTextCtrl.extent = new Vector(640, 60);
		helpTextCtrl.vertSizing = Center;
		helpTextCtrl.horizSizing = Width;

		helpTextBackground = new GuiText(arial14);
		helpTextBackground.text.textColor = 0x000000;
		helpTextBackground.position = new Vector(2, 2);
		helpTextBackground.extent = new Vector(640, 14);
		helpTextBackground.vertSizing = Height;
		helpTextBackground.horizSizing = Width;
		helpTextBackground.justify = Center;

		helpTextForeground = new GuiText(arial14);
		helpTextForeground.text.textColor = 0xEBEBEB;
		helpTextForeground.position = new Vector(0, 0);
		helpTextForeground.extent = new Vector(640, 16);
		helpTextForeground.vertSizing = Height;
		helpTextForeground.horizSizing = Width;
		helpTextForeground.justify = Center;

		helpTextCtrl.addChild(helpTextBackground);
		helpTextCtrl.addChild(helpTextForeground);

		var alertTextCtrl = new GuiControl();
		alertTextCtrl.position = new Vector(0, playGuiCtrl.extent.y * 375 / 480);
		alertTextCtrl.extent = new Vector(640, 105);
		alertTextCtrl.vertSizing = Top;
		alertTextCtrl.horizSizing = Width;

		alertTextBackground = new GuiText(arial14);
		alertTextBackground.text.textColor = 0x000000;
		alertTextBackground.position = new Vector(2, 2);
		alertTextBackground.extent = new Vector(640, 32);
		alertTextBackground.vertSizing = Height;
		alertTextBackground.horizSizing = Width;
		alertTextBackground.justify = Center;

		alertTextForeground = new GuiText(arial14);
		alertTextForeground.text.textColor = 0xEBEBEB;
		alertTextForeground.position = new Vector(0, 0);
		alertTextForeground.extent = new Vector(640, 32);
		alertTextForeground.vertSizing = Height;
		alertTextForeground.horizSizing = Width;
		alertTextForeground.justify = Center;

		alertTextCtrl.addChild(alertTextBackground);
		alertTextCtrl.addChild(alertTextForeground);

		playGuiCtrlOuter.addChild(helpTextCtrl);
		playGuiCtrlOuter.addChild(alertTextCtrl);

		resizeControlEvents.push(() -> {
			helpTextCtrl.position = new Vector(0, playGuiCtrl.extent.y * 190 / 480);
			alertTextCtrl.position = new Vector(0, playGuiCtrl.extent.y * 375 / 480);
		});
	}

	function initFPSMeter() {
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var bfont = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var fpsMeterCtrl = new GuiImage(ResourceLoader.getResource("data/ui/game/transparency-fps.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		fpsMeterCtrl.position = new Vector(544, 448);
		fpsMeterCtrl.horizSizing = Left;
		fpsMeterCtrl.vertSizing = Top;
		fpsMeterCtrl.extent = new Vector(96, 32);

		fpsMeter = new GuiText(bfont);
		fpsMeter.horizSizing = Width;
		fpsMeter.vertSizing = Height;
		fpsMeter.position = new Vector(10, 3);
		fpsMeter.text.textColor = 0;
		fpsMeter.extent = new Vector(96, 32);
		fpsMeterCtrl.addChild(fpsMeter);

		playGuiCtrl.addChild(fpsMeterCtrl);
	}

	function initBlastBar() {
		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end
		var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;

		blastBar = new GuiControl();
		blastBar.position = new Vector(0, 400);
		blastBar.extent = new Vector(170, 83);
		blastBar.vertSizing = Bottom;
		blastBar.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		blastBar.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		this.playGuiCtrl.addChild(blastBar);

		blastFill = new GuiImage(ResourceLoader.getResource("data/ui/game/powerbarMask.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFill.position = new Vector(36, 38);
		blastFill.extent = new Vector(100, 27);
		blastFill.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		blastFill.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		var colorMat = Matrix.I();
		colorMat.colorSet(0xCDD2D7);
		blastFill.bmp.filter = new h2d.filter.ColorMatrix(colorMat);

		blastBar.addChild(blastFill);

		blastFillUltra = new GuiImage(ResourceLoader.getResource("data/ui/game/powerbarMask.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFillUltra.position = new Vector(36, 38);
		blastFillUltra.extent = new Vector(100, 27);
		blastFillUltra.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		blastFillUltra.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		var colorMat = Matrix.I();
		colorMat.colorSet(0xC4FF00);
		blastFillUltra.bmp.filter = new h2d.filter.ColorMatrix(colorMat);

		blastBar.addChild(blastFillUltra);

		blastFrame = new GuiImage(ResourceLoader.getResource("data/ui/game/pc/powerbar.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFrame.position = new Vector(0, 0);
		blastFrame.extent = new Vector(170, 83);
		blastFrame.xScale = (scene2d.height - safeVerMargin * 2) / 480;
		blastFrame.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		blastBar.addChild(blastFrame);

		resizeControlEvents.push(() -> {
			var safeVerMargin = 1 + (scene2d.height * 0.15) / 2;
			blastBar.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			blastBar.yScale = (scene2d.height - safeVerMargin * 2) / 480;
			blastFill.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			blastFill.yScale = (scene2d.height - safeVerMargin * 2) / 480;
			blastFillUltra.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			blastFillUltra.yScale = (scene2d.height - safeVerMargin * 2) / 480;
			blastFrame.xScale = (scene2d.height - safeVerMargin * 2) / 480;
			blastFrame.yScale = (scene2d.height - safeVerMargin * 2) / 480;
		});
	}

	var blastValue:Float = 0;

	public function setBlastValue(value:Float) {
		if (value <= 1) {
			var oldVal = blastValue;
			blastValue = value;
			blastFill.bmp.tile.setSize(Util.lerp(0, 75, value), 20);
			blastFill.bmp.scaleX = value;
			// blastFill.extent = new Vector(Util.lerp(0, 100, value), 27);
			if (oldVal < 0.25 && value >= 0.25) {
				var colorMat = cast(blastFill.bmp.filter, h2d.filter.ColorMatrix);
				colorMat.matrix.colorSet(0x0080FF);
				MarbleGame.instance.touchInput.blastbutton.setEnabled(true);
			}
			if (oldVal >= 0.25 && value < 0.25) {
				var colorMat = cast(blastFill.bmp.filter, h2d.filter.ColorMatrix);
				colorMat.matrix.colorSet(0xCDD2D7);
				MarbleGame.instance.touchInput.blastbutton.setEnabled(false);
			}
			blastFillUltra.bmp.visible = false;
		} else {
			blastFillUltra.bmp.visible = true;

			var fillPercent = (value - 1) * 6;
			blastFillUltra.bmp.tile.setSize(Util.lerp(0, 75, fillPercent), 20);
			blastFillUltra.bmp.scaleX = fillPercent;

			MarbleGame.instance.touchInput.blastbutton.setEnabled(true);
		}
	}

	function initPlayerList() {
		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 22 * Settings.uiScale, MultiChannel);

		var coliseumfontdata = ResourceLoader.getFileEntry("data/font/ColiseumRR.fnt");
		var coliseumb = new BitmapFont(coliseumfontdata.entry);
		@:privateAccess coliseumb.loader = ResourceLoader.loader;
		var coliseum = coliseumb.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		playerListContainer = new GuiControl();
		playerListContainer.horizSizing = Right;
		playerListContainer.vertSizing = Bottom;
		playerListContainer.position = new Vector(0, 0);
		playerListContainer.extent = new Vector(392, 360);
		this.playGuiCtrl.addChild(playerListContainer);

		var scoreBackdrop = new GuiImage(ResourceLoader.getResource("data/ui/game/scoreBackdrop.png", ResourceLoader.getImage, this.imageResources).toTile());
		scoreBackdrop.position = new Vector(0, 0);
		scoreBackdrop.extent = new Vector(386, 128);
		playerListContainer.addChild(scoreBackdrop);

		var scorePlusMinus = new GuiImage(ResourceLoader.getResource("data/ui/game/scoreBackdropMinus.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		scorePlusMinus.position = new Vector(20, 17);
		scorePlusMinus.extent = new Vector(22, 111);
		scoreBackdrop.addChild(scorePlusMinus);

		function imgLoader(path:String) {
			switch (path) {
				case "us":
					return ResourceLoader.getResource("data/ui/xbox/GreenDot.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "them":
					return ResourceLoader.getResource("data/ui/xbox/EmptyDot.png", ResourceLoader.getImage, this.imageResources).toTile();
			}
			return null;
		}

		// var playerList = [
		// 	'<font color="#EBEBEB"><img src="us"></img>Player 1   1</font>',
		// 	'<font color="#EBEBEB"><img src="them"></img>Player 2    2</font>'
		// ];

		var ds = new h2d.filter.DropShadow(1.414, 0.785, 0x000000, 1, 0, 0.4, 1, true);

		playerListCtrl = new GuiMLTextListCtrl(arial14, [], imgLoader, ds);

		playerListCtrl.position = new Vector(27, 43);
		playerListCtrl.extent = new Vector(392, 271);
		playerListCtrl.scrollable = true;
		playerListCtrl.onSelectedFunc = (sel) -> {}
		playerListContainer.addChild(playerListCtrl);

		playerListScoresCtrl = new GuiMLTextListCtrl(arial14, [], imgLoader, ds);

		playerListScoresCtrl.position = new Vector(277, 43);
		playerListScoresCtrl.extent = new Vector(392, 271);
		playerListScoresCtrl.scrollable = true;
		playerListScoresCtrl.onSelectedFunc = (sel) -> {}
		playerListContainer.addChild(playerListScoresCtrl);
	}

	public function redrawPlayerList() {
		var pl = [];
		var plScores = [];
		playerList.sort((a, b) -> a.score > b.score ? -1 : (a.score < b.score ? 1 : 0));
		for (item in playerList) {
			pl.push('<font color="#EBEBEB"><img src="${item.us ? "us" : "them"}"></img>${Util.rightPad(item.name, 25, 3)}</font>');
			plScores.push('<font color="#EBEBEB">${item.score}</font>');
		}
		playerListCtrl.setTexts(pl);
		playerListScoresCtrl.setTexts(plScores);
	}

	public function doMPEndGameMessage() {
		playerList.sort((a, b) -> a.score > b.score ? -1 : (a.score < b.score ? 1 : 0));
		var p1 = playerList[0];
		var p2 = playerList.length > 1 ? playerList[1] : null;
		if (p2 == null) {
			var onePt = p1.score == 1;
			if (onePt)
				MarbleGame.instance.world.displayAlert('${p1.name} won with 1 point!');
			else
				MarbleGame.instance.world.displayAlert('${p1.name} won with ${p1.score} points!');
		} else {
			var tie = p1.score == p2.score;
			if (tie) {
				MarbleGame.instance.world.displayAlert('Game tied!');
			} else {
				var onePt = p1.score == 1;
				if (onePt)
					MarbleGame.instance.world.displayAlert('${p1.name} won with 1 point!');
				else
					MarbleGame.instance.world.displayAlert('${p1.name} won with ${p1.score} points!');
			}
		}
	}

	public function addPlayer(id:Int, name:String, us:Bool) {
		playerList.push({
			id: id,
			name: name,
			us: us,
			score: 0
		});
		redrawPlayerList();
	}

	public function removePlayer(id:Int) {
		var f = playerList.filter(x -> x.id == id);
		if (f.length != 0)
			playerList.remove(f[0]);
		redrawPlayerList();
	}

	public function incrementPlayerScore(id:Int, score:Int) {
		var f = playerList.filter(x -> x.id == id);
		if (f.length != 0)
			f[0].score += score;

		redrawPlayerList();
	}

	public function resetPlayerScores() {
		for (player in playerList) {
			player.score = 0;
		}

		redrawPlayerList();
	}

	public function setHelpTextOpacity(value:Float) {
		@:privateAccess helpTextForeground.text._textColorVec.a = value;
		@:privateAccess helpTextBackground.text._textColorVec.a = value;
	}

	public function setAlertTextOpacity(value:Float) {
		@:privateAccess alertTextForeground.text._textColorVec.a = value;
		@:privateAccess alertTextBackground.text._textColorVec.a = value;
	}

	public function setAlertText(text:String) {
		this.alertTextForeground.text.text = text;
		this.alertTextBackground.text.text = text;
		// alertTextBackground.render(scene2d);
		// alertTextForeground.x = scene2d.width / 2 - alertTextForeground.textWidth / 2;
		// alertTextForeground.y = scene2d.height - 102;
		// alertTextBackground.x = scene2d.width / 2 - alertTextBackground.textWidth / 2 + 1;
		// alertTextBackground.y = scene2d.height - 102 + 1;
	}

	public function setHelpText(text:String) {
		this.helpTextForeground.text.text = text;
		this.helpTextBackground.text.text = text;
		// helpTextBackground.render(scene2d);
		// helpTextForeground.x = scene2d.width / 2 - helpTextForeground.textWidth / 2;
		// helpTextForeground.y = scene2d.height * 0.45;
		// helpTextBackground.x = scene2d.width / 2 - helpTextBackground.textWidth / 2 + 1;
		// helpTextBackground.y = scene2d.height * 0.45 + 1;
	}

	public function setPowerupImage(powerupIdentifier:String) {
		if (powerupIdentifier == "SuperJump") {
			powerupBox.anim.currentFrame = 2;
		} else if (powerupIdentifier == "SuperSpeed") {
			powerupBox.anim.currentFrame = 4;
		} else if (powerupIdentifier == "Helicopter") {
			powerupBox.anim.currentFrame = 1;
		} else if (powerupIdentifier == "MegaMarble") {
			powerupBox.anim.currentFrame = 3;
		} else {
			powerupBox.anim.currentFrame = 0;
		}
	}

	public function resizeGemCounter(total:Int) {
		if (total >= 100) {
			// 3 digits
			gemCountNumbers[0].anim.visible = true;
			gemCountNumbers[1].anim.visible = true;
			gemCountNumbers[2].anim.visible = true;
			gemCountNumbers[3].anim.visible = true;
			gemCountNumbers[4].anim.visible = true;
			gemCountNumbers[5].anim.visible = true;

			gemCountNumbers[0].position.x = 20;
			gemCountNumbers[1].position.x = 38;
			gemCountNumbers[2].position.x = 56;
			gemCountNumbers[3].position.x = 89;
			gemCountNumbers[4].position.x = 107;
			gemCountNumbers[5].position.x = 125;
			gemCountSlash.position.x = 73;
			gemHUD.position.x = 144;
		} else if (total >= 10) {
			// 2 digits
			gemCountNumbers[0].anim.visible = false;
			gemCountNumbers[1].anim.visible = true;
			gemCountNumbers[2].anim.visible = true;
			gemCountNumbers[3].anim.visible = false;
			gemCountNumbers[4].anim.visible = true;
			gemCountNumbers[5].anim.visible = true;

			gemCountNumbers[2].position.x = 32;
			gemCountNumbers[5].position.x = 83;
			gemCountNumbers[1].position.x = 14;
			gemCountNumbers[4].position.x = 65;
			gemCountSlash.position.x = 49;
			gemHUD.position.x = 101;
		} else {
			// 1 digit
			gemCountNumbers[0].anim.visible = false;
			gemCountNumbers[1].anim.visible = false;
			gemCountNumbers[2].anim.visible = true;
			gemCountNumbers[3].anim.visible = false;
			gemCountNumbers[4].anim.visible = false;
			gemCountNumbers[5].anim.visible = true;

			gemCountNumbers[2].position.x = 8;
			gemCountNumbers[5].position.x = 41;
			gemCountSlash.position.x = 25;
			gemHUD.position.x = 59;
		}
		gemHUD.parent.render(scene2d, @:privateAccess gemHUD.parent.parent._flow);
	}

	public function resizeGemHuntCounter(total:Int) {
		if (total >= 100) {
			// 3 digits
			gemCountNumbers[0].anim.visible = true;
			gemCountNumbers[1].anim.visible = true;
			gemCountNumbers[2].anim.visible = true;

			gemCountNumbers[0].position.x = 20;
			gemCountNumbers[1].position.x = 38;
			gemCountNumbers[2].position.x = 56;
		} else if (total >= 10) {
			// 2 digits
			gemCountNumbers[0].anim.visible = false;
			gemCountNumbers[1].anim.visible = true;
			gemCountNumbers[2].anim.visible = true;

			gemCountNumbers[0].position.x = 20;
			gemCountNumbers[1].position.x = 38;
			gemCountNumbers[2].position.x = 56;
		} else {
			// 1 digit
			gemCountNumbers[0].anim.visible = false;
			gemCountNumbers[1].anim.visible = false;
			gemCountNumbers[2].anim.visible = true;

			gemCountNumbers[0].position.x = 20;
			gemCountNumbers[1].position.x = 38;
			gemCountNumbers[2].position.x = 56;
		}
		gemHUD.position.x = 74;
		gemHUD.parent.render(scene2d, @:privateAccess gemHUD.parent.parent._flow);
	}

	public function formatGemCounter(collected:Int, total:Int) {
		if (MarbleGame.instance.world.isMultiplayer)
			return;
		if (total == 0) {
			for (number in gemCountNumbers) {
				number.anim.visible = false;
			}
			gemCountSlash.bmp.visible = false;
			gemHUD.bmp.visible = false;
		} else {
			if (totalGems != total) {
				resizeGemCounter(total);
				totalGems = total;
			}
			gemCountSlash.bmp.visible = true;
			gemHUD.bmp.visible = true;
		}

		var totalHundredths = Math.floor(total / 100);
		var totalTenths = Math.floor(total / 10) % 10;
		var totalOnes = total % 10;

		var collectedHundredths = Math.floor(collected / 100);
		var collectedTenths = Math.floor(collected / 10) % 10;
		var collectedOnes = collected % 10;

		gemCountNumbers[0].anim.currentFrame = collectedHundredths;
		gemCountNumbers[1].anim.currentFrame = collectedTenths;
		gemCountNumbers[2].anim.currentFrame = collectedOnes;
		gemCountNumbers[3].anim.currentFrame = totalHundredths;
		gemCountNumbers[4].anim.currentFrame = totalTenths;
		gemCountNumbers[5].anim.currentFrame = totalOnes;
	}

	public function formatGemHuntCounter(collected:Int) {
		if (MarbleGame.instance.world.isMultiplayer)
			return;
		gemCountNumbers[0].anim.visible = true;
		gemCountNumbers[1].anim.visible = true;
		gemCountNumbers[2].anim.visible = true;
		gemCountNumbers[3].anim.visible = false;
		gemCountNumbers[4].anim.visible = false;
		gemCountNumbers[5].anim.visible = false;
		gemHUD.bmp.visible = true;

		var collectedHundredths = Math.floor(collected / 100);
		var collectedTenths = Math.floor(collected / 10) % 10;
		var collectedOnes = collected % 10;

		gemCountNumbers[0].anim.currentFrame = collectedHundredths;
		gemCountNumbers[1].anim.currentFrame = collectedTenths;
		gemCountNumbers[2].anim.currentFrame = collectedOnes;

		resizeGemHuntCounter(collected);
	}

	// 0: default
	// 1: green
	// 2: red
	public function formatTimer(time:Float) {
		if (time < 0)
			time = 0; // Can't support negatives for now
		var et = time * 1000;
		var thousandth = et % 10;
		var hundredth = Math.floor((et % 1000) / 10);
		var totalSeconds = Math.floor(et / 1000);
		var seconds = totalSeconds % 60;
		var minutes = (totalSeconds - seconds) / 60;

		var secondsOne = seconds % 10;
		var secondsTen = (seconds - secondsOne) / 10;
		var minutesOne = minutes % 10;
		var minutesTen = ((minutes - minutesOne) / 10) % 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		timerNumbers[0].anim.currentFrame = minutesTen;
		timerNumbers[1].anim.currentFrame = minutesOne;
		timerNumbers[2].anim.currentFrame = secondsTen;
		timerNumbers[3].anim.currentFrame = secondsOne;
		timerNumbers[4].anim.currentFrame = hundredthTen;
		timerNumbers[5].anim.currentFrame = hundredthOne;
		timerNumbers[6].anim.currentFrame = thousandth;
	}

	public function render(engine:h3d.Engine) {
		// Do nothing
	}

	public function update(timeState:TimeState) {
		if (this.fpsMeter != null) {
			this.fpsMeter.text.text = '${Math.floor(ProfilerUI.instance.fps)} fps';
		}
		this.updateMiddleMessages(timeState.dt);
	}

	function updateMiddleMessages(dt:Float) {
		var itermessages = this.middleMessages.copy();
		while (itermessages.length > 0) {
			var thismsg = itermessages.shift();
			thismsg.age += dt;
			if (thismsg.age > 3) {
				this.middleMessages.remove(thismsg);
				thismsg.ctrl.parent.removeChild(thismsg.ctrl); // Delete it
			} else {
				var t = thismsg.age;
				thismsg.ctrl.text.alpha = 1 - thismsg.age / 3;
				thismsg.ctrl.text.y = thismsg.yPos - (-33 * 0.5 * t * t + 100 * t);
			}
		}
	}

	public function addMiddleMessage(text:String, color:Int) {
		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 33 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		var middleMsg = new GuiText(arial14);
		middleMsg.position = new Vector(200, 50);
		middleMsg.extent = new Vector(400, 100);
		middleMsg.horizSizing = Center;
		middleMsg.vertSizing = Center;
		middleMsg.text.text = text;
		middleMsg.justify = Center;
		middleMsg.text.textColor = color;
		middleMsg.text.filter = new h2d.filter.DropShadow(1.414, 0.785, 0x000000, 1, 0, 0.4, 1, true);
		this.playGuiCtrl.addChild(middleMsg);
		middleMsg.render(scene2d, @:privateAccess this.playGuiCtrl._flow);
		middleMsg.text.y -= (25 / playGuiCtrl.extent.y) * scene2d.height;

		this.middleMessages.push({ctrl: middleMsg, age: 0, yPos: middleMsg.text.y});
	}

	var pgoChildren = [];

	public function setGuiVisibility(show:Bool) {
		if (show) {
			if (pgoChildren.length != 0) {
				for (ch in pgoChildren) {
					playGuiCtrlOuter.addChild(ch);
				}
				if (Util.isTouchDevice()) {
					MarbleGame.instance.touchInput.showControls(this.playGuiCtrlOuter, true);
				}
				playGuiCtrlOuter.render(MarbleGame.canvas.scene2d);
				pgoChildren = [];
			}
		} else {
			pgoChildren = playGuiCtrlOuter.children.copy();
			playGuiCtrlOuter.removeChildren();
			playGuiCtrlOuter.render(MarbleGame.canvas.scene2d);
		}
	}
}
