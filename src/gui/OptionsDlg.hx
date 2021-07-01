package gui;

import src.AudioManager;
import hxd.Key;
import src.Settings;
import src.Marble;
import h2d.Tile;
import hxd.res.BitmapFont;
import src.MarbleGame;
import h3d.Vector;
import src.ResourceLoader;

class OptionsDlg extends GuiImage {
	public function new() {
		super(ResourceLoader.getImage("data/ui/background.jpg").toTile());
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var arial14fontdata = ResourceLoader.loader.load("data/font/Arial14.fnt");
		var arial14 = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14.loader = ResourceLoader.loader;

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var tabs = new GuiControl();
		tabs.horizSizing = Center;
		tabs.vertSizing = Center;
		tabs.position = new Vector(60, 15);
		tabs.extent = new Vector(520, 450);
		this.addChild(tabs);

		var setTab:String->Void = null;

		var graphicsTab = new GuiImage(ResourceLoader.getImage("data/ui/options/graf_tab.png").toTile());
		graphicsTab.position = new Vector(58, 44);
		graphicsTab.extent = new Vector(149, 86);

		var controlsTab = new GuiImage(ResourceLoader.getImage("data/ui/options/cntr_tab.png").toTile());
		controlsTab.position = new Vector(315, 15);
		controlsTab.extent = new Vector(149, 65);

		var boxFrame = new GuiImage(ResourceLoader.getImage("data/ui/options/options_base.png").toTile());
		boxFrame.position = new Vector(25, 14);
		boxFrame.extent = new Vector(470, 422);
		boxFrame.horizSizing = Center;
		boxFrame.vertSizing = Center;

		var audioTab = new GuiImage(ResourceLoader.getImage("data/ui/options/aud_tab.png").toTile());
		audioTab.position = new Vector(204, 33);
		audioTab.extent = new Vector(114, 75);

		tabs.addChild(audioTab);
		tabs.addChild(controlsTab);
		tabs.addChild(boxFrame);
		tabs.addChild(graphicsTab);

		var mainPane = new GuiControl();
		mainPane.position = new Vector(60, 15);
		mainPane.extent = new Vector(520, 450);
		mainPane.horizSizing = Center;
		mainPane.vertSizing = Center;
		this.addChild(mainPane);

		// GRAPHICS PANEL
		var graphicsPane = new GuiControl();
		graphicsPane.position = new Vector(35, 110);
		graphicsPane.extent = new Vector(438, 298);

		mainPane.addChild(graphicsPane);
		var applyFunc:Void->Void = null;

		var mainMenuButton = new GuiButton(loadButtonImages("data/ui/options/mainm"));
		mainMenuButton.position = new Vector(330, 356);
		mainMenuButton.extent = new Vector(121, 53);
		mainMenuButton.pressedAction = (sender) -> {
			applyFunc();
			MarbleGame.canvas.setContent(new MainMenuGui());
		}
		mainPane.addChild(mainMenuButton);

		// Hacky radio box logic
		var windowBoxes = [];

		function updateWindowFunc(sender:GuiButton) {
			for (box in windowBoxes) {
				if (box != sender)
					box.pressed = false;
			}
		}

		var gfxWindow = new GuiButton(loadButtonImages("data/ui/options/grafwindo"));
		gfxWindow.position = new Vector(174, 116);
		gfxWindow.extent = new Vector(97, 55);
		gfxWindow.buttonType = Toggle;
		gfxWindow.pressedAction = (sender) -> {
			updateWindowFunc(gfxWindow);
		}
		if (!Settings.optionsSettings.isFullScreen) {
			gfxWindow.pressed = true;
		}
		graphicsPane.addChild(gfxWindow);
		windowBoxes.push(gfxWindow);

		var gfxFull = new GuiButton(loadButtonImages("data/ui/options/grafful"));
		gfxFull.position = new Vector(288, 118);
		gfxFull.extent = new Vector(61, 55);
		gfxFull.buttonType = Toggle;
		gfxFull.pressedAction = (sender) -> {
			updateWindowFunc(gfxFull);
		}
		if (Settings.optionsSettings.isFullScreen) {
			gfxFull.pressed = true;
		}
		graphicsPane.addChild(gfxFull);
		windowBoxes.push(gfxFull);

		var gfxText = new GuiImage(ResourceLoader.getImage("data/ui/options/graf_txt.png").toTile());
		gfxText.horizSizing = Right;
		gfxText.vertSizing = Bottom;
		gfxText.position = new Vector(12, 12);
		gfxText.extent = new Vector(146, 261);
		graphicsPane.addChild(gfxText);

		var resolutionBoxes = [];

		function updateResolutionFunc(sender:GuiButton) {
			for (box in resolutionBoxes) {
				if (box != sender)
					box.pressed = false;
			}
		}

		var gfx640480 = new GuiButton(loadButtonImages("data/ui/options/graf640"));
		gfx640480.position = new Vector(157, -3);
		gfx640480.extent = new Vector(84, 53);
		gfx640480.buttonType = Toggle;
		resolutionBoxes.push(gfx640480);
		gfx640480.pressedAction = (sender) -> {
			updateResolutionFunc(gfx640480);
		}
		graphicsPane.addChild(gfx640480);
		if (Settings.optionsSettings.screenWidth == 640)
			gfx640480.pressed = true;

		var gfx800600 = new GuiButton(loadButtonImages("data/ui/options/graf800"));
		gfx800600.position = new Vector(237, 0);
		gfx800600.extent = new Vector(86, 51);
		gfx800600.buttonType = Toggle;
		resolutionBoxes.push(gfx800600);
		gfx800600.pressedAction = (sender) -> {
			updateResolutionFunc(gfx800600);
		}
		graphicsPane.addChild(gfx800600);
		if (Settings.optionsSettings.screenWidth == 800)
			gfx800600.pressed = true;

		var gfx1024768 = new GuiButton(loadButtonImages("data/ui/options/graf1024"));
		gfx1024768.position = new Vector(320, -1);
		gfx1024768.extent = new Vector(94, 51);
		gfx1024768.buttonType = Toggle;
		resolutionBoxes.push(gfx1024768);
		gfx1024768.pressedAction = (sender) -> {
			updateResolutionFunc(gfx1024768);
		}
		if (Settings.optionsSettings.screenWidth == 1024)
			gfx1024768.pressed = true;
		graphicsPane.addChild(gfx1024768);

		var driverBoxes = [];

		function updateDriverFunc(sender:GuiButton) {
			for (box in driverBoxes) {
				if (box != sender)
					box.pressed = false;
			}
		}

		var gfxopengl = new GuiButton(loadButtonImages("data/ui/options/grafopgl"));
		gfxopengl.position = new Vector(165, 58);
		gfxopengl.extent = new Vector(97, 54);
		gfxopengl.buttonType = Toggle;
		driverBoxes.push(gfxopengl);
		gfxopengl.pressedAction = (sender) -> {
			updateDriverFunc(gfxopengl);
		}
		if (Settings.optionsSettings.videoDriver == 0) {
			gfxopengl.pressed = true;
		}
		graphicsPane.addChild(gfxopengl);

		var gfxd3d = new GuiButton(loadButtonImages("data/ui/options/grafdir3d"));
		gfxd3d.position = new Vector(270, 59);
		gfxd3d.extent = new Vector(104, 52);
		gfxd3d.buttonType = Toggle;
		driverBoxes.push(gfxd3d);
		gfxd3d.pressedAction = (sender) -> {
			updateDriverFunc(gfxd3d);
		}
		if (Settings.optionsSettings.videoDriver == 1) {
			gfxd3d.pressed = true;
		}
		graphicsPane.addChild(gfxd3d);

		var applyButton = new GuiButton(loadButtonImages("data/ui/options/grafapply"));
		applyButton.position = new Vector(188, 239);
		applyButton.extent = new Vector(106, 60);
		applyButton.pressedAction = (sender) -> applyFunc();
		graphicsPane.addChild(applyButton);

		var bitBoxes = [];

		function updateBitsFunc(sender:GuiButton) {
			for (box in bitBoxes) {
				if (box != sender)
					box.pressed = false;
			}
		}

		var gfx16 = new GuiButton(loadButtonImages("data/ui/options/graf16bt"));
		gfx16.position = new Vector(179, 170);
		gfx16.extent = new Vector(79, 54);
		gfx16.buttonType = Toggle;
		bitBoxes.push(gfx16);
		gfx16.pressedAction = (sender) -> {
			updateBitsFunc(gfx16);
		}
		if (Settings.optionsSettings.colorDepth == 0) {
			gfx16.pressed = true;
		}
		graphicsPane.addChild(gfx16);

		var gfx32 = new GuiButton(loadButtonImages("data/ui/options/graf32bt"));
		gfx32.position = new Vector(272, 174);
		gfx32.extent = new Vector(84, 51);
		gfx32.buttonType = Toggle;
		bitBoxes.push(gfx32);
		gfx32.pressedAction = (sender) -> {
			updateBitsFunc(gfx32);
		}
		if (Settings.optionsSettings.colorDepth == 1) {
			gfx32.pressed = true;
		}
		graphicsPane.addChild(gfx32);

		var shadowsButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
		shadowsButton.position = new Vector(141, 233);
		shadowsButton.extent = new Vector(46, 54);
		shadowsButton.buttonType = Toggle;
		graphicsPane.addChild(shadowsButton);
		if (Settings.optionsSettings.shadows) {
			shadowsButton.pressed = true;
		}

		// AUDIO PANEL

		var audioPane = new GuiControl();
		audioPane.position = new Vector(41, 91);
		audioPane.extent = new Vector(425, 281);
		// mainPane.addChild(audioPane);

		var audSndSlide = new GuiImage(ResourceLoader.getImage("data/ui/options/aud_snd_slide.png").toTile());
		audSndSlide.position = new Vector(14, 92);
		audSndSlide.extent = new Vector(388, 34);
		audioPane.addChild(audSndSlide);

		var audMusSlide = new GuiImage(ResourceLoader.getImage("data/ui/options/aud_mus_slide.png").toTile());
		audMusSlide.position = new Vector(17, 32);
		audMusSlide.extent = new Vector(381, 40);
		audioPane.addChild(audMusSlide);

		var audMusKnob = new GuiSlider(ResourceLoader.getImage("data/ui/options/aud_mus_knb.png").toTile());
		audMusKnob.position = new Vector(137, 37);
		audMusKnob.extent = new Vector(250, 34);
		audMusKnob.sliderValue = Settings.optionsSettings.musicVolume;
		audMusKnob.pressedAction = (sender) -> {
			Settings.optionsSettings.musicVolume = audMusKnob.sliderValue;
		}
		audioPane.addChild(audMusKnob);

		var audSndKnob = new GuiSlider(ResourceLoader.getImage("data/ui/options/aud_snd_knb.png").toTile());
		audSndKnob.position = new Vector(137, 95);
		audSndKnob.extent = new Vector(254, 37);
		audSndKnob.sliderValue = Settings.optionsSettings.soundVolume;
		var testingSnd = AudioManager.playSound(ResourceLoader.getAudio("data/sound/testing.wav"), null, true);
		testingSnd.pause = true;
		audSndKnob.slidingSound = testingSnd;
		audSndKnob.pressedAction = (sender) -> {
			Settings.optionsSettings.soundVolume = audSndKnob.sliderValue;
		}
		audioPane.addChild(audSndKnob);

		var audTxtWndo = new GuiImage(ResourceLoader.getImage("data/ui/options/aud_txt_wndo.png").toTile());
		audTxtWndo.position = new Vector(26, 130);
		audTxtWndo.extent = new Vector(396, 132);
		audioPane.addChild(audTxtWndo);

		var audInfo = new GuiText(arial14);
		audInfo.position = new Vector(24, 41);
		audInfo.extent = new Vector(330, 56);
		audInfo.text.textColor = 0x000000;
		audInfo.text.text = "Vendor: Creative Labs Inc.
Version: OpenAL 1.0
Renderer: Software
Extensions: EAX 2.0, EAX 3.0, EAX Unified, and EAX-AC3";
		audTxtWndo.addChild(audInfo);

		applyFunc = () -> {
			if (gfx640480.pressed) {
				Settings.optionsSettings.screenWidth = 640;
				Settings.optionsSettings.screenHeight = 480;
			}
			if (gfx800600.pressed) {
				Settings.optionsSettings.screenWidth = 800;
				Settings.optionsSettings.screenHeight = 600;
			}
			if (gfx1024768.pressed) {
				Settings.optionsSettings.screenWidth = 1024;
				Settings.optionsSettings.screenHeight = 768;
			}
			if (gfxFull.pressed)
				Settings.optionsSettings.isFullScreen = true;
			else
				Settings.optionsSettings.isFullScreen = false;
			if (gfx16.pressed)
				Settings.optionsSettings.colorDepth = 0;
			else
				Settings.optionsSettings.colorDepth = 1;
			if (gfxopengl.pressed)
				Settings.optionsSettings.videoDriver = 0;
			else
				Settings.optionsSettings.videoDriver = 1;
			Settings.optionsSettings.shadows = shadowsButton.pressed;

			Settings.optionsSettings.musicVolume = audMusKnob.sliderValue;
			Settings.optionsSettings.soundVolume = audSndKnob.sliderValue;

			Settings.applySettings();
		}

		// CONTROLS PANEL
		var controlsPane = new GuiControl();
		controlsPane.position = new Vector(44, 58);
		controlsPane.extent = new Vector(459, 339);
		// MARBLE PANEL
		var marbleControlsPane = new GuiImage(ResourceLoader.getImage("data/ui/options/cntrl_marb_bse.png").toTile());
		marbleControlsPane.position = new Vector(0, 5);
		marbleControlsPane.extent = new Vector(438, 320);
		controlsPane.addChild(marbleControlsPane);

		var cameraControlsPane:GuiImage = null;
		var mouseControlsPane:GuiImage = null;

		function getConflictingBinding(bindingName:String, key:Int) {
			if (Settings.controlsSettings.forward == key && bindingName != "Move Forward")
				return "Move Forward";
			if (Settings.controlsSettings.backward == key && bindingName != "Move Backward")
				return "Move Backward";
			if (Settings.controlsSettings.left == key && bindingName != "Move Left")
				return "Move Left";
			if (Settings.controlsSettings.right == key && bindingName != "Move Right")
				return "Move Right";
			if (Settings.controlsSettings.camForward == key && bindingName != "Rotate Camera Up")
				return "Rotate Camera Up";
			if (Settings.controlsSettings.camBackward == key && bindingName != "Rotate Camera Down")
				return "Rotate Camera Down";
			if (Settings.controlsSettings.camLeft == key && bindingName != "Rotate Camera Left")
				return "Rotate Camera Left";
			if (Settings.controlsSettings.camRight == key && bindingName != "Rotate Camera Right")
				return "Rotate Camera Right";
			if (Settings.controlsSettings.jump == key && bindingName != "Jump")
				return "Jump";
			if (Settings.controlsSettings.powerup == key && bindingName != "Use PowerUp")
				return "Use PowerUp";
			if (Settings.controlsSettings.freelook == key && bindingName != "Free Look")
				return "Free Look";

			return null;
		}

		function remapFunc(bindingName:String, bindingFunc:Int->Void, ctrl:GuiButtonText) {
			var remapDlg = new RemapDlg(bindingName);
			MarbleGame.canvas.pushDialog(remapDlg);
			remapDlg.remapCallback = (key) -> {
				MarbleGame.canvas.popDialog(remapDlg);

				var conflicting = getConflictingBinding(bindingName, key);
				if (conflicting == null) {
					ctrl.txtCtrl.text.text = Key.getKeyName(key);
					bindingFunc(key);
				} else {
					var yesNoDlg = new MessageBoxYesNoDlg('<p align="center">"${Key.getKeyName(key)}" is already bound to "${conflicting}"!<br/>Do you want to undo this mapping?</p>',
						() -> {
						ctrl.txtCtrl.text.text = Key.getKeyName(key);
						bindingFunc(key);
					}, () -> {});
					MarbleGame.canvas.pushDialog(yesNoDlg);
				}
			}
		}

		var moveForward = new GuiButtonText(loadButtonImages("data/ui/options/cntr_mrb_fw"), arial14);
		moveForward.position = new Vector(82, 104);
		moveForward.setExtent(new Vector(117, 51));
		moveForward.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.forward);
		moveForward.pressedAction = (sender) -> {
			remapFunc("Move Forward", (key) -> Settings.controlsSettings.forward = key, moveForward);
		}
		marbleControlsPane.addChild(moveForward);

		var moveRight = new GuiButtonText(loadButtonImages("data/ui/options/cntr_mrb_rt"), arial14);
		moveRight.position = new Vector(230, 167);
		moveRight.setExtent(new Vector(112, 45));
		moveRight.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.right);
		moveRight.pressedAction = (sender) -> {
			remapFunc("Move Right", (key) -> Settings.controlsSettings.right = key, moveRight);
		}
		marbleControlsPane.addChild(moveRight);

		var mouseFire = new GuiButtonText(loadButtonImages("data/ui/options/cntr_mrb_pwr"), arial14);
		mouseFire.position = new Vector(310, 84);
		mouseFire.setExtent(new Vector(120, 51));
		mouseFire.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.powerup);
		mouseFire.pressedAction = (sender) -> {
			remapFunc("Use PowerUp", (key) -> Settings.controlsSettings.powerup = key, mouseFire);
		}
		marbleControlsPane.addChild(mouseFire);

		var moveBackward = new GuiButtonText(loadButtonImages("data/ui/options/cntr_mrb_bak"), arial14);
		moveBackward.position = new Vector(135, 235);
		moveBackward.setExtent(new Vector(118, 48));
		moveBackward.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.backward);
		moveBackward.pressedAction = (sender) -> {
			remapFunc("Move Backward", (key) -> Settings.controlsSettings.backward = key, moveBackward);
		}
		marbleControlsPane.addChild(moveBackward);

		var moveLeft = new GuiButtonText(loadButtonImages("data/ui/options/cntr_mrb_lft"), arial14);
		moveLeft.position = new Vector(19, 189);
		moveLeft.setExtent(new Vector(108, 45));
		moveLeft.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.left);
		moveLeft.pressedAction = (sender) -> {
			remapFunc("Move Left", (key) -> Settings.controlsSettings.left = key, moveLeft);
		}
		marbleControlsPane.addChild(moveLeft);

		var moveJmp = new GuiButtonText(loadButtonImages("data/ui/options/cntr_mrb_jmp"), arial14);
		moveJmp.position = new Vector(299, 231);
		moveJmp.setExtent(new Vector(120, 47));
		moveJmp.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.jump);
		moveJmp.pressedAction = (sender) -> {
			remapFunc("Jump", (key) -> Settings.controlsSettings.jump = key, moveJmp);
		}
		marbleControlsPane.addChild(moveJmp);

		var transparentbmp = new hxd.BitmapData(1, 1);
		transparentbmp.setPixel(0, 0, 0);
		var transparentTile = Tile.fromBitmap(transparentbmp);

		var marbleToCameraButton = new GuiButton([transparentTile, transparentTile, transparentTile]);
		marbleToCameraButton.position = new Vector(138, 26);
		marbleToCameraButton.extent = new Vector(121, 40);
		marbleToCameraButton.pressedAction = (sender) -> {
			controlsPane.removeChild(marbleControlsPane);
			controlsPane.addChild(cameraControlsPane);
			this.render(cast(this.parent, Canvas).scene2d);
		}
		marbleControlsPane.addChild(marbleToCameraButton);

		var marbleToMouseButton = new GuiButton([transparentTile, transparentTile, transparentTile]);
		marbleToMouseButton.position = new Vector(277, 0);
		marbleToMouseButton.extent = new Vector(121, 43);
		marbleToMouseButton.pressedAction = (sender) -> {
			controlsPane.addChild(mouseControlsPane);
			controlsPane.removeChild(marbleControlsPane);
			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		}
		marbleControlsPane.addChild(marbleToMouseButton);

		// CAMERA PANEL
		cameraControlsPane = new GuiImage(ResourceLoader.getImage("data/ui/options/cntrl_cam_bse.png").toTile());
		cameraControlsPane.position = new Vector(0, 5);
		cameraControlsPane.extent = new Vector(438, 320);

		var panUp = new GuiButtonText(loadButtonImages("data/ui/options/cntr_cam_up"), arial14);
		panUp.position = new Vector(29, 133);
		panUp.setExtent(new Vector(108, 42));
		panUp.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.camForward);
		panUp.pressedAction = (sender) -> {
			remapFunc("Rotate Camera Up", (key) -> Settings.controlsSettings.camForward = key, panUp);
		}
		cameraControlsPane.addChild(panUp);

		var turnRight = new GuiButtonText(loadButtonImages("data/ui/options/cntr_cam_rt"), arial14);
		turnRight.position = new Vector(312, 99);
		turnRight.setExtent(new Vector(103, 36));
		turnRight.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.camRight);
		turnRight.pressedAction = (sender) -> {
			remapFunc("Rotate Camera Right", (key) -> Settings.controlsSettings.camRight = key, turnRight);
		}
		cameraControlsPane.addChild(turnRight);

		var panDown = new GuiButtonText(loadButtonImages("data/ui/options/cntr_cam_dwn"), arial14);
		panDown.position = new Vector(42, 213);
		panDown.setExtent(new Vector(109, 39));
		panDown.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.camBackward);
		panDown.pressedAction = (sender) -> {
			remapFunc("Rotate Camera Down", (key) -> Settings.controlsSettings.camBackward = key, panDown);
		}
		cameraControlsPane.addChild(panDown);

		var turnLeft = new GuiButtonText(loadButtonImages("data/ui/options/cntr_cam_lft"), arial14);
		turnLeft.position = new Vector(319, 210);
		turnLeft.setExtent(new Vector(99, 36));
		turnLeft.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.camLeft);
		turnLeft.pressedAction = (sender) -> {
			remapFunc("Rotate Camera Left", (key) -> Settings.controlsSettings.camLeft = key, turnLeft);
		}
		cameraControlsPane.addChild(turnLeft);

		var cameraToMarbleButton = new GuiButton([transparentTile, transparentTile, transparentTile]);
		cameraToMarbleButton.position = new Vector(13, 45);
		cameraToMarbleButton.extent = new Vector(121, 40);
		cameraToMarbleButton.pressedAction = (sender) -> {
			controlsPane.addChild(marbleControlsPane);
			controlsPane.removeChild(cameraControlsPane);
			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		}
		cameraControlsPane.addChild(cameraToMarbleButton);

		var cameraToMouseButton = new GuiButton([transparentTile, transparentTile, transparentTile]);
		cameraToMouseButton.position = new Vector(276, 7);
		cameraToMouseButton.extent = new Vector(121, 40);
		cameraToMouseButton.pressedAction = (sender) -> {
			controlsPane.addChild(mouseControlsPane);
			controlsPane.removeChild(cameraControlsPane);
			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		}
		cameraControlsPane.addChild(cameraToMouseButton);

		// MOUSE CONTROLS

		mouseControlsPane = new GuiImage(ResourceLoader.getImage("data/ui/options/cntrl_mous_base.png").toTile());
		mouseControlsPane.position = new Vector(-17, -47);
		mouseControlsPane.extent = new Vector(470, 425);

		var freelook = new GuiButtonText(loadButtonImages("data/ui/options/cntrl_mous_bttn"), arial14);
		freelook.position = new Vector(219, 225);
		freelook.setExtent(new Vector(105, 45));
		freelook.txtCtrl.text.text = Key.getKeyName(Settings.controlsSettings.freelook);
		freelook.pressedAction = (sender) -> {
			remapFunc("Free Look", (key) -> Settings.controlsSettings.freelook = key, freelook);
		}

		mouseControlsPane.addChild(freelook);

		var mouseToMarbleButton = new GuiButton([transparentTile, transparentTile, transparentTile]);
		mouseToMarbleButton.position = new Vector(26, 95);
		mouseToMarbleButton.extent = new Vector(121, 40);
		mouseToMarbleButton.pressedAction = (sender) -> {
			controlsPane.addChild(marbleControlsPane);
			controlsPane.removeChild(mouseControlsPane);
			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		}
		mouseControlsPane.addChild(mouseToMarbleButton);

		var mouseToCameraButton = new GuiButton([transparentTile, transparentTile, transparentTile]);
		mouseToCameraButton.position = new Vector(153, 71);
		mouseToCameraButton.extent = new Vector(121, 40);
		mouseToCameraButton.pressedAction = (sender) -> {
			controlsPane.addChild(cameraControlsPane);
			controlsPane.removeChild(mouseControlsPane);
			MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
		}
		mouseControlsPane.addChild(mouseToCameraButton);

		var invertAxis = new GuiButton(loadButtonImages("data/ui/options/cntrl_mous_invrt"));
		invertAxis.position = new Vector(95, 249);
		invertAxis.extent = new Vector(43, 53);
		invertAxis.buttonType = Toggle;
		invertAxis.pressed = Settings.controlsSettings.invertYAxis;
		invertAxis.pressedAction = (sender) -> {
			Settings.controlsSettings.invertYAxis = !Settings.controlsSettings.invertYAxis;
		}
		mouseControlsPane.addChild(invertAxis);

		var alwaysFreelook = new GuiButton(loadButtonImages("data/ui/options/cntrl_mous_freel"));
		alwaysFreelook.position = new Vector(365, 269);
		alwaysFreelook.extent = new Vector(43, 53);
		alwaysFreelook.buttonType = Toggle;
		alwaysFreelook.pressed = Settings.controlsSettings.alwaysFreeLook;
		alwaysFreelook.pressedAction = (sender) -> {
			Settings.controlsSettings.alwaysFreeLook = !Settings.controlsSettings.alwaysFreeLook;
		}
		mouseControlsPane.addChild(alwaysFreelook);

		var mouseSensitivity = new GuiSlider(ResourceLoader.getImage("data/ui/options/cntrl_mous_knb.png").toTile());
		mouseSensitivity.position = new Vector(147, 148);
		mouseSensitivity.extent = new Vector(254, 34);
		mouseSensitivity.sliderValue = (Settings.controlsSettings.cameraSensitivity - 0.2) / (3 - 0.2);
		mouseSensitivity.pressedAction = (sender) -> {
			Settings.controlsSettings.cameraSensitivity = 0.2 + (3 - 0.2) * mouseSensitivity.sliderValue;
		}
		mouseControlsPane.addChild(mouseSensitivity);

		// INVISIBLE BUTTON SHIT
		var audioTabBtn = new GuiButton([transparentTile, transparentTile, transparentTile]);
		audioTabBtn.position = new Vector(213, 39);
		audioTabBtn.extent = new Vector(92, 42);
		audioTabBtn.pressedAction = (sender) -> setTab("Audio");
		mainPane.addChild(audioTabBtn);

		var controlsTabBtn = new GuiButton([transparentTile, transparentTile, transparentTile]);
		controlsTabBtn.position = new Vector(331, 24);
		controlsTabBtn.extent = new Vector(117, 42);
		controlsTabBtn.pressedAction = (sender) -> setTab("Controls");
		mainPane.addChild(controlsTabBtn);

		var graphicsTabBtn = new GuiButton([transparentTile, transparentTile, transparentTile]);
		graphicsTabBtn.position = new Vector(70, 48);
		graphicsTabBtn.extent = new Vector(117, 48);
		graphicsTabBtn.pressedAction = (sender) -> setTab("Graphics");
		mainPane.addChild(graphicsTabBtn);

		setTab = function(tab:String) {
			tabs.removeChild(audioTab);
			tabs.removeChild(controlsTab);
			tabs.removeChild(boxFrame);
			tabs.removeChild(graphicsTab);
			mainPane.removeChild(graphicsPane);
			mainPane.removeChild(audioPane);
			mainPane.removeChild(controlsPane);
			if (tab == "Graphics") {
				tabs.addChild(audioTab);
				tabs.addChild(controlsTab);
				tabs.addChild(boxFrame);
				tabs.addChild(graphicsTab);
				mainPane.addChild(graphicsPane);
			}
			if (tab == "Audio") {
				tabs.addChild(graphicsTab);
				tabs.addChild(controlsTab);
				tabs.addChild(boxFrame);
				tabs.addChild(audioTab);
				mainPane.addChild(audioPane);
			}
			if (tab == "Controls") {
				// TODO
				tabs.addChild(audioTab);
				tabs.addChild(controlsTab);
				tabs.addChild(boxFrame);
				tabs.addChild(graphicsTab);
				mainPane.addChild(controlsPane);
			}
			this.render(MarbleGame.canvas.scene2d);
		}
	}
}
