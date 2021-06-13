package gui;

import src.TimeState;
import format.gif.Data.Block;
import hxd.res.BitmapFont;
import h2d.Text;
import h3d.shader.pbr.PropsValues;
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

class PlayGui {
	var scene2d:h2d.Scene;

	public function new() {}

	var timerNumbers:Array<Anim> = [];
	var timerPoint:Bitmap;
	var timerColon:Bitmap;

	var gemCountNumbers:Array<Anim> = [];
	var gemCountSlash:Bitmap;
	var gemImageScene:h3d.scene.Scene;
	var gemImageSceneTarget:Texture;
	var gemImageObject:DtsObject;

	var powerupBox:Bitmap;
	var powerupImageScene:h3d.scene.Scene;
	var powerupImageSceneTarget:Texture;
	var powerupImageObject:DtsObject;

	var RSGOCenterText:Anim;

	var helpTextForeground:Text;
	var helpTextBackground:Text;
	var alertTextForeground:Text;
	var alertTextBackground:Text;

	public function init(scene2d:h2d.Scene) {
		this.scene2d = scene2d;

		var numberTiles = [];
		for (i in 0...10) {
			var tile = ResourceLoader.getImage('data/ui/game/numbers/${i}.png').toTile();
			numberTiles.push(tile);
		}

		for (i in 0...7) {
			timerNumbers.push(new Anim(numberTiles, 0, scene2d));
		}

		for (i in 0...4) {
			gemCountNumbers.push(new Anim(numberTiles, 0, scene2d));
		}

		var rsgo = [];
		rsgo.push(ResourceLoader.getImage("data/ui/game/ready.png").toTile());
		rsgo.push(ResourceLoader.getImage("data/ui/game/set.png").toTile());
		rsgo.push(ResourceLoader.getImage("data/ui/game/go.png").toTile());
		rsgo.push(ResourceLoader.getImage("data/ui/game/outofbounds.png").toTile());
		RSGOCenterText = new Anim(rsgo, 0, scene2d);

		timerPoint = new Bitmap(ResourceLoader.getImage('data/ui/game/numbers/point.png').toTile(), scene2d);
		timerColon = new Bitmap(ResourceLoader.getImage('data/ui/game/numbers/colon.png').toTile(), scene2d);
		gemCountSlash = new Bitmap(ResourceLoader.getImage('data/ui/game/numbers/slash.png').toTile(), scene2d);

		powerupBox = new Bitmap(ResourceLoader.getImage('data/ui/game/powerup.png').toTile(), scene2d);
		initTimer();
		initGemCounter();
		initCenterText();
		initPowerupBox();
		initTexts();
	}

	public function initTimer() {
		var screenWidth = scene2d.width;
		var screenHeight = scene2d.height;

		function toScreenSpaceX(x:Float) {
			return screenWidth / 2 - (234 / 2) + x;
		}
		function toScreenSpaceY(y:Float) {
			return (y / 480) * screenHeight;
		}

		timerNumbers[0].x = toScreenSpaceX(23);
		timerNumbers[1].x = toScreenSpaceX(47);
		timerColon.x = toScreenSpaceX(67);
		timerNumbers[2].x = toScreenSpaceX(83);
		timerNumbers[3].x = toScreenSpaceX(107);
		timerPoint.x = toScreenSpaceX(127);
		timerNumbers[4].x = toScreenSpaceX(143);
		timerNumbers[5].x = toScreenSpaceX(167);
		timerNumbers[6].x = toScreenSpaceX(191);
	}

	public function initCenterText() {
		RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[0].width / 2;
		RSGOCenterText.y = scene2d.height * 0.3; // - RSGOCenterText.frames[0].height / 2;
	}

	public function setCenterText(identifier:String) {
		if (identifier == 'none') {
			this.RSGOCenterText.visible = false;
		} else if (identifier == 'ready') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 0;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[0].width / 2;
		} else if (identifier == 'set') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 1;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[1].width / 2;
		} else if (identifier == 'go') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 2;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[2].width / 2;
		} else if (identifier == 'outofbounds') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 3;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[3].width / 2;
		}
	}

	public function initGemCounter() {
		gemCountNumbers[0].x = 30;
		gemCountNumbers[1].x = 54;
		gemCountSlash.x = 75;
		gemCountNumbers[2].x = 96;
		gemCountNumbers[3].x = 120;

		this.gemImageScene = new h3d.scene.Scene();
		var gemImageRenderer = cast(this.gemImageScene.renderer, h3d.scene.pbr.Renderer);
		gemImageRenderer.skyMode = Hide;

		gemImageSceneTarget = new Texture(60, 60, [Target]);
		gemImageSceneTarget.depthBuffer = new DepthBuffer(60, 60);

		var gemImageSceneTargetBitmap = new Bitmap(Tile.fromTexture(gemImageSceneTarget), scene2d);
		gemImageSceneTargetBitmap.x = -8;
		gemImageSceneTargetBitmap.y = -8;

		gemImageObject = new DtsObject();
		gemImageObject.dtsPath = "data/shapes/items/gem.dts";
		gemImageObject.ambientRotate = true;
		gemImageObject.showSequences = false;
		// gemImageObject.matNameOverride.set("base.gem", "base.gem.");
		gemImageObject.ambientSpinFactor /= -2;
		// ["base.gem"] = color + ".gem";
		gemImageObject.init(null);
		for (mat in gemImageObject.materials) {
			mat.mainPass.addShader(new PropsValues(1, 0, 0, 1));
		}
		gemImageScene.addChild(gemImageObject);
		var gemImageCenter = gemImageObject.getBounds().getCenter();

		gemImageScene.camera.pos = new Vector(0, 3, gemImageCenter.z);
		gemImageScene.camera.target = new Vector(gemImageCenter.x, gemImageCenter.y, gemImageCenter.z);
	}

	function initPowerupBox() {
		powerupBox.x = scene2d.width - 102;
		powerupBox.y = 6;

		this.powerupImageScene = new h3d.scene.Scene();
		var powerupImageRenderer = cast(this.powerupImageScene.renderer, h3d.scene.pbr.Renderer);
		powerupImageRenderer.skyMode = Hide;

		powerupImageSceneTarget = new Texture(68, 67, [Target]);
		powerupImageSceneTarget.depthBuffer = new DepthBuffer(68, 67);

		var powerupImageSceneTargetBitmap = new Bitmap(Tile.fromTexture(powerupImageSceneTarget), scene2d);
		powerupImageSceneTargetBitmap.x = scene2d.width - 88;
		powerupImageSceneTargetBitmap.y = 18;
	}

	function initTexts() {
		var fontdata = ResourceLoader.loader.load("data/font/DomCasual32px.fnt");
		var bfont = new BitmapFont(fontdata.entry);
		@:privateAccess bfont.loader = ResourceLoader.loader;
		helpTextBackground = new Text(bfont.toFont(), scene2d);
		helpTextBackground.text = "Bruh";
		helpTextBackground.x = scene2d.width / 2 - helpTextBackground.textWidth / 2 + 1;
		helpTextBackground.y = scene2d.height * 0.45 + 1;
		helpTextBackground.textColor = 0x000000;

		helpTextForeground = new Text(bfont.toFont(), scene2d);
		helpTextForeground.text = "Bruh";
		helpTextForeground.x = scene2d.width / 2 - helpTextForeground.textWidth / 2;
		helpTextForeground.y = scene2d.height * 0.45;
		helpTextForeground.textColor = 0xFFFFFF;

		alertTextBackground = new Text(bfont.toFont(), scene2d);
		alertTextBackground.text = "Bruh";
		alertTextBackground.x = scene2d.width / 2 - alertTextBackground.textWidth / 2 + 1;
		alertTextBackground.y = scene2d.height - 102 + 1;
		alertTextBackground.textColor = 0x000000;

		alertTextForeground = new Text(bfont.toFont(), scene2d);
		alertTextForeground.text = "Bruh";
		alertTextForeground.x = scene2d.width / 2 - alertTextForeground.textWidth / 2;
		alertTextForeground.y = scene2d.height - 102;
		alertTextForeground.textColor = 0xFFE240;
	}

	public function setHelpTextOpacity(value:Float) {
		helpTextForeground.color.a = value;
		helpTextBackground.color.a = value;
	}

	public function setAlertTextOpacity(value:Float) {
		alertTextForeground.color.a = value;
		alertTextBackground.color.a = value;
	}

	public function setAlertText(text:String) {
		this.alertTextForeground.text = text;
		this.alertTextBackground.text = text;
		alertTextForeground.x = scene2d.width / 2 - alertTextForeground.textWidth / 2;
		alertTextForeground.y = scene2d.height - 102;
		alertTextBackground.x = scene2d.width / 2 - alertTextBackground.textWidth / 2 + 1;
		alertTextBackground.y = scene2d.height - 102 + 1;
	}

	public function setHelpText(text:String) {
		this.helpTextForeground.text = text;
		this.helpTextBackground.text = text;
		helpTextForeground.x = scene2d.width / 2 - helpTextForeground.textWidth / 2;
		helpTextForeground.y = scene2d.height - 102;
		helpTextBackground.x = scene2d.width / 2 - helpTextBackground.textWidth / 2 + 1;
		helpTextBackground.y = scene2d.height - 102 + 1;
	}

	public function setPowerupImage(powerupIdentifier:String) {
		this.powerupImageScene.removeChildren();
		if (powerupIdentifier == "SuperJump") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/superjump.dts";
		} else if (powerupIdentifier == "SuperSpeed") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/superspeed.dts";
		} else if (powerupIdentifier == "ShockAbsorber") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/shockabsorber.dts";
		} else if (powerupIdentifier == "SuperBounce") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/items/superbounce.dts";
		} else if (powerupIdentifier == "Helicopter") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = "data/shapes/images/helicopter.dts";
		} else {
			powerupIdentifier = "";
			this.powerupImageObject = null;
		}

		if (powerupIdentifier != "") {
			powerupImageObject.ambientRotate = true;
			powerupImageObject.ambientSpinFactor /= 2;
			powerupImageObject.showSequences = false;
			powerupImageObject.init(null);
			for (mat in powerupImageObject.materials) {
				mat.mainPass.addShader(new PropsValues(1, 0, 0, 1));
			}
			powerupImageScene.addChild(powerupImageObject);
			var powerupImageCenter = powerupImageObject.getBounds().getCenter();

			powerupImageScene.camera.pos = new Vector(0, 4, powerupImageCenter.z);
			powerupImageScene.camera.target = new Vector(powerupImageCenter.x, powerupImageCenter.y, powerupImageCenter.z);
		}
	}

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
		var minutesTen = (minutes - minutesOne) / 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		timerNumbers[0].currentFrame = minutesTen;
		timerNumbers[1].currentFrame = minutesOne;
		timerNumbers[2].currentFrame = secondsTen;
		timerNumbers[3].currentFrame = secondsOne;
		timerNumbers[4].currentFrame = hundredthTen;
		timerNumbers[5].currentFrame = hundredthOne;
		timerNumbers[6].currentFrame = thousandth;
	}

	public function render(engine:h3d.Engine) {
		engine.pushTarget(this.gemImageSceneTarget);

		engine.clear(0, 1);
		this.gemImageScene.render(engine);

		engine.popTarget();
		engine.pushTarget(this.powerupImageSceneTarget);

		engine.clear(0, 1);
		this.powerupImageScene.render(engine);

		engine.popTarget();
	}

	public function update(timeState:TimeState) {
		this.gemImageObject.update(timeState);
		this.gemImageScene.setElapsedTime(timeState.dt);
		if (this.powerupImageObject != null)
			this.powerupImageObject.update(timeState);
		this.powerupImageScene.setElapsedTime(timeState.dt);
	}
}
