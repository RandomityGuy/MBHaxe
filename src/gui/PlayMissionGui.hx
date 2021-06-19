package gui;

import src.ResourceLoader;
import h3d.Vector;

class PlayMissionGui extends GuiImage {
	public function new() {
		super(ResourceLoader.getImage("data/ui/background.jpg").toTile());

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.extent = new Vector(640, 480);
		this.position = new Vector(0, 0);

		var localContainer = new GuiControl();
		localContainer.horizSizing = Center;
		localContainer.vertSizing = Center;
		localContainer.position = new Vector(-1, 44);
		localContainer.extent = new Vector(651, 392);
		this.addChild(localContainer);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			return [normal, hover, pressed];
		}

		var tabAdvanced = new GuiImage(ResourceLoader.getImage("data/ui/play/tab_adv.png").toTile());
		tabAdvanced.position = new Vector(410, 21);
		tabAdvanced.extent = new Vector(166, 43);
		localContainer.addChild(tabAdvanced);

		var tabIntermediate = new GuiImage(ResourceLoader.getImage("data/ui/play/tab_inter.png").toTile());
		tabIntermediate.position = new Vector(213, 4);
		tabIntermediate.extent = new Vector(205, 58);
		localContainer.addChild(tabIntermediate);

		var tabCustom = new GuiImage(ResourceLoader.getImage("data/ui/play/cust_tab.png").toTile());
		tabCustom.position = new Vector(589, 91);
		tabCustom.extent = new Vector(52, 198);
		localContainer.addChild(tabCustom);

		var pmBox = new GuiImage(ResourceLoader.getImage("data/ui/play/playgui.png").toTile());
		pmBox.position = new Vector(0, 42);
		pmBox.extent = new Vector(610, 351);
		pmBox.horizSizing = Right;
		pmBox.vertSizing = Bottom;
		localContainer.addChild(pmBox);

		var textWnd = new GuiImage(ResourceLoader.getImage("data/ui/play/text_window.png").toTile());
		textWnd.horizSizing = Right;
		textWnd.vertSizing = Bottom;
		textWnd.position = new Vector(31, 29);
		textWnd.extent = new Vector(276, 229);
		pmBox.addChild(textWnd);

		var pmPreview = new GuiImage(ResourceLoader.getImage("data/missions/beginner/superspeed.jpg").toTile());
		pmPreview.position = new Vector(312, 42);
		pmPreview.extent = new Vector(258, 193);
		pmBox.addChild(pmPreview);

		var levelWnd = new GuiImage(ResourceLoader.getImage("data/ui/play/level_window.png").toTile());
		levelWnd.position = new Vector();
		levelWnd.extent = new Vector(258, 194);
		pmPreview.addChild(levelWnd);

		// TODO texts
		// var levelBkgnd = new GuiText()

		var pmPlay = new GuiButton(loadButtonImages("data/ui/play/play"));
		pmPlay.position = new Vector(391, 257);
		pmPlay.extent = new Vector(121, 62);
		pmBox.addChild(pmPlay);

		var pmPrev = new GuiButton(loadButtonImages("data/ui/play/prev"));
		pmPrev.position = new Vector(321, 260);
		pmPrev.extent = new Vector(77, 58);
		pmBox.addChild(pmPrev);

		var pmNext = new GuiButton(loadButtonImages("data/ui/play/next"));
		pmNext.position = new Vector(507, 262);
		pmNext.extent = new Vector(75, 60);
		pmBox.addChild(pmNext);

		var pmBack = new GuiButton(loadButtonImages("data/ui/play/back"));
		pmBack.position = new Vector(102, 260);
		pmBack.extent = new Vector(79, 61);
		pmBack.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new MainMenuGui());
		};
		pmBox.addChild(pmBack);

		// TODO Pm description

		var tabBeginner = new GuiImage(ResourceLoader.getImage("data/ui/play/tab_begin.png").toTile());
		tabBeginner.position = new Vector(29, 2);
		tabBeginner.extent = new Vector(184, 55);
		localContainer.addChild(tabBeginner);

		// TODO actual tab buttons
	}
}
