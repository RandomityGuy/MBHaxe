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
	var RSGOCenterText:Anim;

	var helpTextForeground:GuiText;
	var helpTextBackground:GuiText;
	var alertTextForeground:GuiText;
	var alertTextBackground:GuiText;

	var blastBar:GuiControl;
	var blastFill:GuiImage;
	var blastFillUltra:GuiImage;
	var blastFrame:GuiImage;

	var imageResources:Array<Resource<Image>> = [];
	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var playGuiCtrlOuter:GuiControl;
	var playGuiCtrl:GuiControl;

	var resizeEv:Void->Void;

	var _init:Bool;

	var fpsMeter:GuiText;

	var middleMessages:Array<MiddleMessage> = [];

	var totalGems:Int = 0;

	public function dispose() {
		if (_init) {
			playGuiCtrlOuter.dispose();
			RSGOCenterText.remove();

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

		playGuiCtrl = new GuiControl();
		playGuiCtrl.position = new Vector(145, 82);

		var subX = 640 - (scene2d.width - 145 * 2) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - 82 * 2) * 480 / scene2d.height;

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

		var rsgo = [];
		rsgo.push(ResourceLoader.getResource("data/ui/game/ready.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/set.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/go.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/outofbounds.png", ResourceLoader.getImage, this.imageResources).toTile());
		RSGOCenterText = new Anim(rsgo, 0, scene2d);

		initTimer();
		initGemCounter();
		initCenterText();
		initPowerupBox();
		if (game == 'ultra')
			initBlastBar();
		initTexts();
		if (Settings.optionsSettings.frameRateVis)
			initFPSMeter();

		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.showControls(this.playGuiCtrl, game == 'ultra');
		}

		playGuiCtrlOuter.render(scene2d);

		resizeEv = () -> {
			var wnd = Window.getInstance();
			powerupBox.position.x = wnd.width * 469.0 / 640.0;
			playGuiCtrlOuter.render(MarbleGame.canvas.scene2d);
		};

		Window.getInstance().addResizeEvent(resizeEv);

		onFinish();
	}

	public function initTimer() {
		var timerCtrl = new GuiImage(ResourceLoader.getResource('data/ui/game/timebackdrop0.png', ResourceLoader.getImage, this.imageResources).toTile());
		timerCtrl.position = new Vector(215, 0);
		timerCtrl.extent = new Vector(256, 64);
		timerCtrl.horizSizing = Center;
		timerCtrl.xScale = (scene2d.height - 82 * 2) / 480;
		timerCtrl.yScale = (scene2d.height - 82 * 2) / 480;

		var innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(26, 0);
		innerCtrl.extent = new Vector(256, 64);
		innerCtrl.xScale = (scene2d.height - 82 * 2) / 480;
		innerCtrl.yScale = (scene2d.height - 82 * 2) / 480;
		timerCtrl.addChild(innerCtrl);

		timerNumbers[0].position = new Vector(20, 4);
		timerNumbers[0].extent = new Vector(43, 55);
		timerNumbers[0].xScale = (scene2d.height - 82 * 2) / 480;
		timerNumbers[0].yScale = (scene2d.height - 82 * 2) / 480;

		timerNumbers[1].position = new Vector(40, 4);
		timerNumbers[1].extent = new Vector(43, 55);
		timerNumbers[1].xScale = (scene2d.height - 82 * 2) / 480;
		timerNumbers[1].yScale = (scene2d.height - 82 * 2) / 480;

		var colonCols = ResourceLoader.getResource('data/ui/game/numbers/colon.png', ResourceLoader.getImage, this.imageResources).toTile();

		timerColon = new GuiImage(colonCols);
		timerColon.position = new Vector(55, 4);
		timerColon.extent = new Vector(43, 55);
		timerColon.xScale = (scene2d.height - 82 * 2) / 480;
		timerColon.yScale = (scene2d.height - 82 * 2) / 480;

		timerNumbers[2].position = new Vector(70, 4);
		timerNumbers[2].extent = new Vector(43, 55);
		timerNumbers[2].xScale = (scene2d.height - 82 * 2) / 480;
		timerNumbers[2].yScale = (scene2d.height - 82 * 2) / 480;

		timerNumbers[3].position = new Vector(90, 4);
		timerNumbers[3].extent = new Vector(43, 55);
		timerNumbers[3].xScale = (scene2d.height - 82 * 2) / 480;
		timerNumbers[3].yScale = (scene2d.height - 82 * 2) / 480;

		var pointCols = ResourceLoader.getResource('data/ui/game/numbers/point.png', ResourceLoader.getImage, this.imageResources).toTile();

		timerPoint = new GuiImage(pointCols);
		timerPoint.position = new Vector(105, 4);
		timerPoint.extent = new Vector(43, 55);
		timerPoint.xScale = (scene2d.height - 82 * 2) / 480;
		timerPoint.yScale = (scene2d.height - 82 * 2) / 480;

		timerNumbers[4].position = new Vector(120, 4);
		timerNumbers[4].extent = new Vector(43, 55);
		timerNumbers[4].xScale = (scene2d.height - 82 * 2) / 480;
		timerNumbers[4].yScale = (scene2d.height - 82 * 2) / 480;

		timerNumbers[5].position = new Vector(140, 4);
		timerNumbers[5].extent = new Vector(43, 55);
		timerNumbers[5].xScale = (scene2d.height - 82 * 2) / 480;
		timerNumbers[5].yScale = (scene2d.height - 82 * 2) / 480;

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

		playGuiCtrl.addChild(timerCtrl);
	}

	public function initCenterText() {
		RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[0].width * Settings.uiScale / 2;
		RSGOCenterText.y = scene2d.height * 0.3; // - RSGOCenterText.frames[0].height / 2;
		RSGOCenterText.setScale(Settings.uiScale);
	}

	public function setCenterText(identifier:String) {
		if (identifier == 'none') {
			this.RSGOCenterText.visible = false;
		} else if (identifier == 'ready') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 0;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[0].width * Settings.uiScale / 2;
		} else if (identifier == 'set') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 1;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[1].width * Settings.uiScale / 2;
		} else if (identifier == 'go') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 2;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[2].width * Settings.uiScale / 2;
		} else if (identifier == 'outofbounds') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 3;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[3].width * Settings.uiScale / 2;
		}
	}

	public function initGemCounter() {
		var gemBox = new GuiControl();
		gemBox.position = new Vector(0, 0);
		gemBox.extent = new Vector(300, 200);
		gemBox.xScale = (scene2d.height - 82 * 2) / 480;
		gemBox.yScale = (scene2d.height - 82 * 2) / 480;

		var innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(26, 0);
		innerCtrl.extent = new Vector(256, 64);
		innerCtrl.xScale = (scene2d.height - 82 * 2) / 480;
		innerCtrl.yScale = (scene2d.height - 82 * 2) / 480;
		gemBox.addChild(innerCtrl);

		gemCountNumbers[0].position = new Vector(20, 4);
		gemCountNumbers[0].extent = new Vector(43, 55);
		gemCountNumbers[0].xScale = (scene2d.height - 82 * 2) / 480;
		gemCountNumbers[0].yScale = (scene2d.height - 82 * 2) / 480;

		gemCountNumbers[1].position = new Vector(38, 4);
		gemCountNumbers[1].extent = new Vector(43, 55);
		gemCountNumbers[1].xScale = (scene2d.height - 82 * 2) / 480;
		gemCountNumbers[1].yScale = (scene2d.height - 82 * 2) / 480;

		gemCountNumbers[2].position = new Vector(56, 4);
		gemCountNumbers[2].extent = new Vector(43, 55);
		gemCountNumbers[2].xScale = (scene2d.height - 82 * 2) / 480;
		gemCountNumbers[2].yScale = (scene2d.height - 82 * 2) / 480;

		gemCountSlash = new GuiImage(ResourceLoader.getResource('data/ui/game/numbers/slash.png', ResourceLoader.getImage, this.imageResources).toTile());
		gemCountSlash.position = new Vector(73, 4);
		gemCountSlash.extent = new Vector(43, 55);
		gemCountSlash.xScale = (scene2d.height - 82 * 2) / 480;
		gemCountSlash.yScale = (scene2d.height - 82 * 2) / 480;

		gemCountNumbers[3].position = new Vector(89, 4);
		gemCountNumbers[3].extent = new Vector(43, 55);
		gemCountNumbers[3].xScale = (scene2d.height - 82 * 2) / 480;
		gemCountNumbers[3].yScale = (scene2d.height - 82 * 2) / 480;

		gemCountNumbers[4].position = new Vector(107, 4);
		gemCountNumbers[4].extent = new Vector(43, 55);
		gemCountNumbers[4].xScale = (scene2d.height - 82 * 2) / 480;
		gemCountNumbers[4].yScale = (scene2d.height - 82 * 2) / 480;

		gemCountNumbers[5].position = new Vector(125, 4);
		gemCountNumbers[5].extent = new Vector(43, 55);
		gemCountNumbers[5].xScale = (scene2d.height - 82 * 2) / 480;
		gemCountNumbers[5].yScale = (scene2d.height - 82 * 2) / 480;

		gemHUD = new GuiImage(ResourceLoader.getResource('data/ui/game/gem.png', ResourceLoader.getImage, this.imageResources).toTile());
		gemHUD.position = new Vector(144, 2);
		gemHUD.extent = new Vector(64, 64);
		gemHUD.xScale = (scene2d.height - 82 * 2) / 480;
		gemHUD.yScale = (scene2d.height - 82 * 2) / 480;

		innerCtrl.addChild(gemCountNumbers[0]);
		innerCtrl.addChild(gemCountNumbers[1]);
		innerCtrl.addChild(gemCountNumbers[2]);
		innerCtrl.addChild(gemCountSlash);
		innerCtrl.addChild(gemCountNumbers[3]);
		innerCtrl.addChild(gemCountNumbers[4]);
		innerCtrl.addChild(gemCountNumbers[5]);
		innerCtrl.addChild(gemHUD);

		playGuiCtrl.addChild(gemBox);
		// gemImageSceneTargetBitmap.blendMode = None;
		// gemImageSceneTargetBitmap.addShader(new ColorKey());
	}

	function initPowerupBox() {
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
		powerupBox.xScale = (scene2d.height - 82 * 2) / 480;
		powerupBox.yScale = (scene2d.height - 82 * 2) / 480;

		playGuiCtrl.addChild(powerupBox);
	}

	function initTexts() {
		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

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
		blastBar = new GuiControl();
		blastBar.position = new Vector(0, 400);
		blastBar.extent = new Vector(170, 83);
		blastBar.vertSizing = Bottom;
		blastBar.xScale = (scene2d.height - 82 * 2) / 480;
		blastBar.yScale = (scene2d.height - 82 * 2) / 480;
		this.playGuiCtrl.addChild(blastBar);

		blastFill = new GuiImage(ResourceLoader.getResource("data/ui/game/powerbarMask.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFill.position = new Vector(36, 38);
		blastFill.extent = new Vector(100, 27);
		blastFill.xScale = (scene2d.height - 82 * 2) / 480;
		blastFill.yScale = (scene2d.height - 82 * 2) / 480;
		var colorMat = Matrix.I();
		colorMat.colorSet(0x0080FF);
		blastFill.bmp.filter = new h2d.filter.ColorMatrix(colorMat);

		blastBar.addChild(blastFill);

		blastFillUltra = new GuiImage(ResourceLoader.getResource("data/ui/game/powerbarMask.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFillUltra.position = new Vector(36, 38);
		blastFillUltra.extent = new Vector(100, 27);
		blastFillUltra.xScale = (scene2d.height - 82 * 2) / 480;
		blastFillUltra.yScale = (scene2d.height - 82 * 2) / 480;
		var colorMat = Matrix.I();
		colorMat.colorSet(0xC4FF00);
		blastFillUltra.bmp.filter = new h2d.filter.ColorMatrix(colorMat);

		blastBar.addChild(blastFillUltra);

		blastFrame = new GuiImage(ResourceLoader.getResource("data/ui/game/pc/powerbar.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFrame.position = new Vector(0, 0);
		blastFrame.extent = new Vector(170, 83);
		blastFrame.xScale = (scene2d.height - 82 * 2) / 480;
		blastFrame.yScale = (scene2d.height - 82 * 2) / 480;
		blastBar.addChild(blastFrame);
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

	public function formatGemCounter(collected:Int, total:Int) {
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

	// 0: default
	// 1: green
	// 2: red
	public function formatTimer(time:Float) {
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
		if (itermessages.length > 0) {
			var thismsg = itermessages.shift();
			thismsg.age += dt;
			if (thismsg.age > 0.6) {
				this.middleMessages.remove(thismsg);
				thismsg.ctrl.parent.removeChild(thismsg.ctrl); // Delete it
			} else {
				if (thismsg.age >= 0.3) {
					thismsg.ctrl.text.alpha = 1 - (thismsg.age - 0.3) / 0.3;
				}
				thismsg.ctrl.text.y -= (0.1 / playGuiCtrl.extent.y) * scene2d.height;
			}
		}
	}

	public function addMiddleMessage(text:String, color:Int) {
		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var middleMsg = new GuiText(markerFelt32);
		middleMsg.position = new Vector(200, 50);
		middleMsg.extent = new Vector(400, 100);
		middleMsg.horizSizing = Center;
		middleMsg.vertSizing = Center;
		middleMsg.text.text = text;
		middleMsg.justify = Center;
		middleMsg.text.textColor = color;
		middleMsg.text.filter = new h2d.filter.DropShadow(1.414, 0.785, 0x000000F, 1, 0, 0.4, 1, true);
		this.playGuiCtrl.addChild(middleMsg);
		middleMsg.render(scene2d);
		middleMsg.text.y -= (25 / playGuiCtrl.extent.y) * scene2d.height;

		this.middleMessages.push({ctrl: middleMsg, age: 0});
	}
}
