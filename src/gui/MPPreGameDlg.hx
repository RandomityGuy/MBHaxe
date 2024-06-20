package gui;

import h2d.filter.DropShadow;
import net.Net;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;

class MPPreGameDlg extends GuiControl {
	public function new() {
		super();

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		function loadButtonImagesExt(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);
		var markerFelt20 = markerFelt32b.toSdfFont(cast 18.5 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);
		var markerFelt26 = markerFelt32b.toSdfFont(cast 22 * Settings.uiScale, MultiChannel);

		var dialogImg = new GuiImage(ResourceLoader.getResource("data/ui/mp/pre/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		dialogImg.horizSizing = Center;
		dialogImg.vertSizing = Center;
		dialogImg.position = new Vector(0, 0);
		dialogImg.extent = new Vector(640, 480);
		this.addChild(dialogImg);

		var leaveBtn = new GuiButton(loadButtonImages("/data/ui/mp/pre/leave"));
		leaveBtn.horizSizing = Left;
		leaveBtn.vertSizing = Top;
		leaveBtn.position = new Vector(499, 388);
		leaveBtn.extent = new Vector(94, 45);
		dialogImg.addChild(leaveBtn);

		var playBtn = new GuiButton(loadButtonImages("/data/ui/mp/pre/play"));
		playBtn.horizSizing = Right;
		playBtn.vertSizing = Top;
		playBtn.position = new Vector(406, 388);
		playBtn.extent = new Vector(94, 45);
		playBtn.buttonType = Toggle;
		dialogImg.addChild(playBtn);

		var readyBtn = new GuiButton(loadButtonImages("/data/ui/mp/pre/ready"));
		readyBtn.horizSizing = Right;
		readyBtn.vertSizing = Top;
		readyBtn.position = new Vector(53, 394);
		readyBtn.extent = new Vector(133, 33);
		readyBtn.buttonType = Toggle;
		dialogImg.addChild(readyBtn);

		var kickBtn = new GuiButton(loadButtonImages("/data/ui/mp/play/kick"));
		kickBtn.horizSizing = Right;
		kickBtn.vertSizing = Bottom;
		kickBtn.position = new Vector(360, 388);
		kickBtn.extent = new Vector(45, 45);
		if (Net.isHost)
			dialogImg.addChild(kickBtn);

		var spectateBtn = new GuiButton(loadButtonImages("/data/ui/mp/pre/spectate"));
		spectateBtn.horizSizing = Right;
		spectateBtn.vertSizing = Top;
		spectateBtn.position = new Vector(190, 394);
		spectateBtn.extent = new Vector(127, 33);
		dialogImg.addChild(spectateBtn);

		var serverTitle = new GuiText(markerFelt24);
		serverTitle.text.textColor = 0xFFFFFF;
		serverTitle.position = new Vector(60, 59);
		serverTitle.extent = new Vector(525, 30);
		serverTitle.text.text = Net.isHost ? Settings.serverSettings.name : Net.connectedServerInfo.name;
		serverTitle.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		serverTitle.justify = Center;
		dialogImg.addChild(serverTitle);

		var serverDesc = new GuiText(markerFelt24);
		serverDesc.text.textColor = 0xFFFFFF;
		serverDesc.position = new Vector(60, 92);
		serverDesc.extent = new Vector(525, 66);
		serverDesc.text.text = Net.isHost ? Settings.serverSettings.description : Net.connectedServerInfo.description;
		serverDesc.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		serverDesc.justify = Center;
		dialogImg.addChild(serverDesc);

		var levelName = new GuiText(markerFelt24);
		levelName.text.textColor = 0xFFFFFF;
		levelName.position = new Vector(60, 158);
		levelName.extent = new Vector(525, 22);
		levelName.text.text = MarbleGame.instance.world.mission.title;
		levelName.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		dialogImg.addChild(levelName);

		var levelDesc = new GuiText(markerFelt18);
		levelDesc.text.textColor = 0xFFFFFF;
		levelDesc.position = new Vector(60, 185);
		levelDesc.extent = new Vector(516, 63);
		levelDesc.text.text = MarbleGame.instance.world.mission.description;
		levelDesc.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		dialogImg.addChild(levelDesc);

		var playerTitle = new GuiText(markerFelt18);
		playerTitle.text.textColor = 0xDDDDEE;
		playerTitle.position = new Vector(60, 263);
		playerTitle.extent = new Vector(525, 14);
		playerTitle.text.text = "Player                                                                                            Status";
		playerTitle.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		dialogImg.addChild(playerTitle);

		var playerListContainer = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		playerListContainer.position = new Vector(57, 286);
		playerListContainer.extent = new Vector(525, 99);
		playerListContainer.childrenHandleScroll = true;
		// playerList.maxScrollY = 394 * Settings.uiScale;
		dialogImg.addChild(playerListContainer);

		var playerListLeftShadow = new GuiTextListCtrl(markerFelt18, [
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName
		], 0);
		playerListLeftShadow.horizSizing = Width;
		playerListLeftShadow.position = new Vector(0, 0);
		playerListLeftShadow.extent = new Vector(525, 99);
		playerListLeftShadow.scrollable = true;
		playerListLeftShadow.textYOffset = -6;
		playerListContainer.addChild(playerListLeftShadow);

		var playerListLeft = new GuiTextListCtrl(markerFelt18, [
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName,
			Settings.highscoreName
		], 0xFFFFFF);
		playerListLeft.horizSizing = Width;
		playerListLeft.position = new Vector(-1, -1);
		playerListLeft.extent = new Vector(525, 99);
		playerListLeft.scrollable = true;
		playerListLeft.textYOffset = -6;
		playerListContainer.addChild(playerListLeft);

		playerListContainer.setScrollMax(playerListLeft.calculateFullHeight());
	}
}
