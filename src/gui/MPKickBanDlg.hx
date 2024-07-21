package gui;

import net.ClientConnection;
import net.NetCommands;
import net.Net;
import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import h3d.prim.Polygon;
import h3d.scene.Mesh;
import h3d.shader.AlphaChannel;
import src.MarbleGame;
import h3d.Vector;
import src.ResourceLoader;
import src.DtsObject;
import src.Settings;
import src.ResourceLoaderWorker;

class MPKickBanDlg extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/mp/kickban/window.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(226, 137);
		this.extent = new Vector(409, 316);

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

		var closeBtn = new GuiButton(loadButtonImages("data/ui/mp/team/close"));
		closeBtn.position = new Vector(247, 254);
		closeBtn.extent = new Vector(94, 45);
		closeBtn.vertSizing = Bottom;
		closeBtn.horizSizing = Right;
		closeBtn.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(closeBtn);

		var kickBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/kickban/kick"));
		kickBtn.position = new Vector(77, 254);
		kickBtn.extent = new Vector(94, 45);
		kickBtn.vertSizing = Bottom;
		kickBtn.horizSizing = Right;
		kickBtn.disabled = true;
		this.addChild(kickBtn);

		var kickTitle = new GuiText(markerFelt32);
		kickTitle.text.textColor = 0xFFFFFF;
		kickTitle.text.text = "Kick Players";
		kickTitle.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		kickTitle.justify = Center;
		kickTitle.position = new Vector(11, 17);
		kickTitle.extent = new Vector(388, 14);
		this.addChild(kickTitle);

		var playerNames = [];
		var playerIds = [];
		for (c in Net.clients) {
			playerNames.push(c.getName());
			playerIds.push(c.id);
		}

		var kickPlayerId = -1;

		var playerList = new GuiTextListCtrl(markerFelt18, playerNames, 0);
		playerList.position = new Vector(120, 60);
		playerList.extent = new Vector(188, 180);
		playerList.scrollable = true;
		playerList.textYOffset = -6;
		playerList.onSelectedFunc = (sel) -> {
			kickBtn.disabled = false;
			kickPlayerId = playerIds[sel];
		}
		this.addChild(playerList);

		kickBtn.pressedAction = (e) -> {
			if (Net.clientIdMap.exists(kickPlayerId)) {
				var playerToKick = kickPlayerId;
				playerNames.remove(Net.clientIdMap.get(playerToKick).getName());
				playerIds.remove(playerToKick);
				playerList.setTexts(playerNames);
				kickBtn.disabled = true;
				NetCommands.getKickedClient(Net.clientIdMap.get(playerToKick));
				var cc = cast(Net.clientIdMap.get(playerToKick), ClientConnection);
				cc.socket.close();
			}
		}
	}
}
