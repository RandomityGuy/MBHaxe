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

		var passwordPopup = new GuiControl();
		passwordPopup.position = new Vector(0, 0);
		passwordPopup.extent = new Vector(640, 480);
		passwordPopup.horizSizing = Width;
		passwordPopup.vertSizing = Height;

		var passwordWindow = new GuiImage(ResourceLoader.getResource("data/ui/mp/join/window2.png", ResourceLoader.getImage, this.imageResources).toTile());
		passwordWindow.horizSizing = Center;
		passwordWindow.vertSizing = Center;
		passwordWindow.position = new Vector(144, 199);
		passwordWindow.extent = new Vector(508, 202);
		passwordPopup.addChild(passwordWindow);

		var passwordTitle = new GuiText(markerFelt32);
		passwordTitle.position = new Vector(22, 28);
		passwordTitle.extent = new Vector(463, 14);
		passwordTitle.text.textColor = 0xFFFFFF;
		passwordTitle.horizSizing = Center;
		passwordTitle.justify = Center;
		passwordTitle.text.text = "Password Required";
		passwordTitle.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		passwordWindow.addChild(passwordTitle);

		var passwordBar = new GuiImage(ResourceLoader.getResource("data/ui/mp/join/textbar.png", ResourceLoader.getImage, this.imageResources).toTile());
		passwordBar.position = new Vector(22, 73);
		passwordBar.extent = new Vector(463, 47);
		passwordWindow.addChild(passwordBar);

		var passwordInput = new GuiTextInput(markerFelt24);
		passwordInput.position = new Vector(30, 79);
		passwordInput.extent = new Vector(447, 38);
		passwordInput.horizSizing = Center;
		passwordInput.text.textColor = 0;
		passwordWindow.addChild(passwordInput);

		var passwordCancel = new GuiButton(loadButtonImages("data/ui/mp/join/cancel"));
		passwordCancel.position = new Vector(29, 126);
		passwordCancel.extent = new Vector(94, 45);
		passwordCancel.pressedAction = (e) -> {
			passwordInput.text.text = "";
			MarbleGame.canvas.popDialog(passwordPopup, false);
		}
		passwordWindow.addChild(passwordCancel);

		var passwordJoin = new GuiButton(loadButtonImages("data/ui/mp/join/join"));
		passwordJoin.position = new Vector(385, 126);
		passwordJoin.extent = new Vector(94, 45);
		passwordWindow.addChild(passwordJoin);

		var window = new GuiImage(ResourceLoader.getResource("data/ui/mp/join/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		window.horizSizing = Center;
		window.vertSizing = Center;
		window.position = new Vector(-60, 5);
		window.extent = new Vector(759, 469);

		var serverInfoContainer = new GuiControl();
		serverInfoContainer.position = new Vector(520, 58);
		serverInfoContainer.extent = new Vector(210, 166);
		window.addChild(serverInfoContainer);

		var serverInfo = new GuiMLText(markerFelt24, mlFontLoader);
		serverInfo.position = new Vector(0, 0);
		serverInfo.extent = new Vector(210, 166);
		serverInfo.text.text = '<p align="center">Select a Server</p>';
		serverInfo.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		serverInfo.text.textColor = 0xFFFFFF;
		serverInfoContainer.addChild(serverInfo);

		var serverListContainer = new GuiControl();
		serverListContainer.position = new Vector(30, 80);
		serverListContainer.extent = new Vector(475, 290);
		window.addChild(serverListContainer);

		function imgLoader(path:String) {
			var t = switch (path) {
				case "ready":
					ResourceLoader.getResource("data/ui/mp/play/Ready.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "notready":
					ResourceLoader.getResource("data/ui/mp/play/NotReady.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "pc":
					ResourceLoader.getResource("data/ui/mp/play/platform_desktop_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "mac":
					ResourceLoader.getResource("data/ui/mp/play/platform_mac_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "web":
					ResourceLoader.getResource("data/ui/mp/play/platform_web_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "android":
					ResourceLoader.getResource("data/ui/mp/play/platform_android_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					ResourceLoader.getResource("data/ui/mp/play/platform_unknown_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case _:
					return null;
			};
			if (t != null)
				t.scaleToSize(t.width * (Settings.uiScale), t.height * (Settings.uiScale));
			return t;
		}

		var ourServerList:Array<RemoteServerInfo> = [];

		var curSelection = -1;
		var serverList = new GuiMLTextListCtrl(markerFelt18, [], imgLoader);
		serverList.position = new Vector(0, 0);
		serverList.extent = new Vector(475, 63);
		serverList.scrollable = true;
		serverList.textYOffset = -6;
		serverList.onSelectedFunc = (sel) -> {
			curSelection = sel;

			if (curSelection == -1) {
				serverInfo.text.text = '<p align="center">Select a Server</p><p align="center">or Host your own</p>';
			} else {
				var server = ourServerList[curSelection];
				serverInfo.text.text = '<p align="center">${server.name}</p><p align="center"><font face="MarkerFelt18" color="#DDDDEE">Hosted by ${server.host}</font></p><p align="left">${server.description}</p>';
			}
		}
		serverListContainer.addChild(serverList);

		var serverDisplays = [];

		var platformToString = ["unknown", "pc", "mac", "web", "android"];

		function updateServerListDisplay() {
			serverDisplays = ourServerList.map(x ->
				'<img src="${platformToString[x.platform]}"></img><font color="#FFFFFF">${x.name} <offset value="${400 * Settings.uiScale}">${x.players}/${x.maxPlayers}</offset></font>');
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

		var joinFunc = (password:String) -> {
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
				Net.joinServer(ourServerList[curSelection].name, password, () -> {
					failed = false;
					Net.remoteServerInfo = ourServerList[curSelection];
				});
			}
		}

		var joinBtn = new GuiButton(loadButtonImages("data/ui/mp/join/join"));
		joinBtn.position = new Vector(628, 379);
		joinBtn.extent = new Vector(93, 45);
		joinBtn.pressedAction = (e) -> {
			if (curSelection != -1) {
				if (ourServerList[curSelection].passworded) {
					MarbleGame.canvas.pushDialog(passwordPopup);
				} else {
					joinFunc("");
				}
			}
		}
		window.addChild(joinBtn);

		passwordJoin.pressedAction = (e) -> {
			joinFunc(passwordInput.text.text);
		}

		var refreshing = false;
		var refreshBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/join/refresh/refresh-1"));
		refreshBtn.position = new Vector(126, 379);
		refreshBtn.extent = new Vector(45, 45);
		refreshBtn.pressedAction = (e) -> {
			if (refreshing)
				return;
			refreshBtn.disabled = true;
			refreshing = true;
			MasterServerClient.connectToMasterServer(() -> {
				MasterServerClient.instance.getServerList((servers) -> {
					ourServerList = servers;
					updateServerListDisplay();
					refreshing = false;
					refreshBtn.disabled = false;
				});
			}, () -> {
				refreshing = false;
				refreshBtn.disabled = false;
			});
		}
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

		var listTitle = new GuiText(markerFelt24);
		listTitle.position = new Vector(30, 48);
		listTitle.extent = new Vector(480, 22);
		listTitle.text.textColor = 0xDDDDEE;
		listTitle.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		listTitle.text.text = "  Server Name                                                              Players";
		window.addChild(listTitle);

		this.addChild(window);
	}
}
