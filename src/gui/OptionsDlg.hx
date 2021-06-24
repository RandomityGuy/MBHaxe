package gui;

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

		var graphicsPane = new GuiControl();
		graphicsPane.position = new Vector(35, 110);
		graphicsPane.extent = new Vector(438, 298);

		mainPane.addChild(graphicsPane);

		var mainMenuButton = new GuiButton(loadButtonImages("data/ui/options/mainm"));
		mainMenuButton.position = new Vector(330, 356);
		mainMenuButton.extent = new Vector(121, 53);
		mainMenuButton.pressedAction = (sender) -> {
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
		gfxWindow.pressed = true;
		gfxWindow.pressedAction = (sender) -> {
			updateWindowFunc(gfxWindow);
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

		var gfx800600 = new GuiButton(loadButtonImages("data/ui/options/graf800"));
		gfx800600.position = new Vector(237, 0);
		gfx800600.extent = new Vector(86, 51);
		gfx800600.buttonType = Toggle;
		resolutionBoxes.push(gfx800600);
		gfx800600.pressedAction = (sender) -> {
			updateResolutionFunc(gfx800600);
		}
		graphicsPane.addChild(gfx800600);

		var gfx1024768 = new GuiButton(loadButtonImages("data/ui/options/graf1024"));
		gfx1024768.position = new Vector(320, -1);
		gfx1024768.extent = new Vector(94, 51);
		gfx1024768.buttonType = Toggle;
		gfx1024768.pressed = true;
		resolutionBoxes.push(gfx1024768);
		gfx1024768.pressedAction = (sender) -> {
			updateResolutionFunc(gfx1024768);
		}
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
		gfxopengl.pressed = true;
		driverBoxes.push(gfxopengl);
		gfxopengl.pressedAction = (sender) -> {
			updateDriverFunc(gfxopengl);
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
		graphicsPane.addChild(gfxd3d);

		var applyButton = new GuiButton(loadButtonImages("data/ui/options/grafapply"));
		applyButton.position = new Vector(188, 239);
		applyButton.extent = new Vector(106, 60);
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
		graphicsPane.addChild(gfx16);

		var gfx32 = new GuiButton(loadButtonImages("data/ui/options/graf32bt"));
		gfx32.position = new Vector(272, 174);
		gfx32.extent = new Vector(84, 51);
		gfx32.buttonType = Toggle;
		gfx32.pressed = true;
		bitBoxes.push(gfx32);
		gfx32.pressedAction = (sender) -> {
			updateBitsFunc(gfx32);
		}
		graphicsPane.addChild(gfx32);

		var shadowsButton = new GuiButton(loadButtonImages("data/ui/options/graf_chkbx"));
		shadowsButton.position = new Vector(141, 233);
		shadowsButton.extent = new Vector(46, 54);
		shadowsButton.buttonType = Toggle;
		graphicsPane.addChild(shadowsButton);
	}
}
