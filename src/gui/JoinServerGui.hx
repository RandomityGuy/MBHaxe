package gui;

import net.MasterServerClient;
import net.MasterServerClient.RemoteServerInfo;
import net.Net;
import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import src.MarbleGame;
import src.ResourceLoader;
import h3d.Vector;
import src.Util;
import src.Settings;

class JoinServerGui extends GuiImage {
	public function new() {
		function chooseBg() {
			var rand = Math.random();
			if (rand >= 0 && rand <= 0.244)
				return ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
			if (rand > 0.244 && rand <= 0.816)
				return ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg');
			return ResourceLoader.getImage('data/ui/backgrounds/ultra/${cast (Math.floor(Util.lerp(1, 9, Math.random())), Int)}.jpg');
		}
		var img = chooseBg();
		super(img.resource.toTile());

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "MarkerFelt32":
					return markerFelt32;
				case "MarkerFelt24":
					return markerFelt24;
				case "MarkerFelt18":
					return markerFelt18;
				default:
					return null;
			}
		}

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var window = new GuiImage(ResourceLoader.getResource("data/ui/mp/join/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		window.horizSizing = Center;
		window.vertSizing = Center;
		window.position = new Vector(-60, 5);
		window.extent = new Vector(759, 469);

		var serverListContainer = new GuiControl();
		serverListContainer.position = new Vector(30, 80);
		serverListContainer.extent = new Vector(475, 290);
		window.addChild(serverListContainer);

		var curSelection = -1;
		var serverList = new GuiTextListCtrl(markerFelt18, [], 0xFFFFFF);
		serverList.position = new Vector(0, 0);
		serverList.extent = new Vector(475, 63);
		serverList.scrollable = true;
		serverList.textYOffset = -6;
		serverList.onSelectedFunc = (sel) -> {
			curSelection = sel;
		}
		serverListContainer.addChild(serverList);

		var serverDisplays = [];

		var ourServerList:Array<RemoteServerInfo> = [];
		var platformToString = ["unknown", "pc", "mac", "web", "android"];

		function updateServerListDisplay() {
			serverDisplays = ourServerList.map(x -> '${x.name}');
			serverList.setTexts(serverDisplays);
		}

		MasterServerClient.connectToMasterServer(() -> {
			MasterServerClient.instance.getServerList((servers) -> {
				ourServerList = servers;
				updateServerListDisplay();
			});
		});

		var hostBtn = new GuiButton(loadButtonImages("data/ui/mp/join/host"));
		hostBtn.position = new Vector(521, 379);
		hostBtn.extent = new Vector(93, 45);
		hostBtn.pressedAction = (e) -> {
			Net.hostServer(Settings.serverSettings.name, Settings.serverSettings.description, Settings.serverSettings.maxPlayers, "", () -> {
				MarbleGame.canvas.setContent(new MPPlayMissionGui(true));
			});
		}
		window.addChild(hostBtn);

		var joinBtn = new GuiButton(loadButtonImages("data/ui/mp/join/join"));
		joinBtn.position = new Vector(628, 379);
		joinBtn.extent = new Vector(93, 45);
		joinBtn.pressedAction = (e) -> {
			if (curSelection != -1) {
				var selectedServerVersion = ourServerList[curSelection].version;
				// if (selectedServerVersion != MarbleGame.currentVersion) {
				// 	var pup = new MessageBoxOkDlg("You are using a different version of the game than the server. Please update your game.");
				// 	MarbleGame.canvas.pushDialog(pup);
				// 	return;
				// }

				MarbleGame.canvas.setContent(new MPMessageGui("Please Wait", "Connecting"));
				var failed = true;
				haxe.Timer.delay(() -> {
					if (MarbleGame.canvas.content is MPMessageGui) {
						var loadGui:MPMessageGui = cast MarbleGame.canvas.content;
						if (loadGui != null) {
							loadGui.setTexts("Error", "Failed to connect to server");
						}
					}
				}, 15000);
				Net.joinServer(ourServerList[curSelection].name, "", () -> {
					failed = false;
					Net.remoteServerInfo = ourServerList[curSelection];
				});
			}
		}
		window.addChild(joinBtn);

		var refreshBtn = new GuiButton(loadButtonImages("data/ui/mp/join/refresh/refresh-1"));
		refreshBtn.position = new Vector(126, 379);
		refreshBtn.extent = new Vector(45, 45);
		window.addChild(refreshBtn);

		var serverSettingsBtn = new GuiButton(loadButtonImages("data/ui/mp/play/settings"));
		serverSettingsBtn.position = new Vector(171, 379);
		serverSettingsBtn.extent = new Vector(45, 45);
		serverSettingsBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MPServerDlg());
		}
		window.addChild(serverSettingsBtn);

		var exitBtn = new GuiButton(loadButtonImages("data/ui/mp/join/leave"));
		exitBtn.position = new Vector(32, 379);
		exitBtn.extent = new Vector(93, 45);
		exitBtn.pressedAction = (e) -> {
			MarbleGame.canvas.setContent(new MainMenuGui());
		}
		window.addChild(exitBtn);

		var titleText = new GuiText(markerFelt32);
		titleText.position = new Vector(30, 20);
		titleText.extent = new Vector(647, 30);
		titleText.justify = Center;
		titleText.text.text = "Join Server";
		titleText.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		titleText.text.textColor = 0xFFFFFF;
		window.addChild(titleText);

		var serverInfoHeader = new GuiText(markerFelt24);
		serverInfoHeader.position = new Vector(520, 58);
		serverInfoHeader.extent = new Vector(210, 166);
		serverInfoHeader.justify = Center;
		serverInfoHeader.text.text = "Select a Server";
		serverInfoHeader.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		serverInfoHeader.text.textColor = 0xFFFFFF;
		window.addChild(serverInfoHeader);

		this.addChild(window);
	}
}
