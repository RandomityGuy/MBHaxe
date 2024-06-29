package gui;

import src.Console;
import net.Net;
import net.Net.ServerInfo;
import net.MasterServerClient;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Mission;
import src.MissionList;

class MPServerListGui extends GuiImage {
	var innerCtrl:GuiControl;
	var serverWnd:GuiImage;

	public function new() {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var subX = 640 - (scene2d.width - offsetX) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY) * 480 / scene2d.height;

		innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		innerCtrl.horizSizing = Width;
		innerCtrl.vertSizing = Height;
		this.addChild(innerCtrl);

		serverWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/helpWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		serverWnd.horizSizing = Right;
		serverWnd.vertSizing = Bottom;
		serverWnd.position = new Vector(260, 107);
		serverWnd.extent = new Vector(736, 460);
		innerCtrl.addChild(serverWnd);

		function imgLoader(path:String) {
			var t = switch (path) {
				case "ready":
					ResourceLoader.getResource("data/ui/xbox/Ready.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "notready":
					ResourceLoader.getResource("data/ui/xbox/NotReady.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "pc":
					ResourceLoader.getResource("data/ui/xbox/platform_desktop_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "mac":
					ResourceLoader.getResource("data/ui/xbox/platform_mac_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "web":
					ResourceLoader.getResource("data/ui/xbox/platform_web_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "android":
					ResourceLoader.getResource("data/ui/xbox/platform_android_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					ResourceLoader.getResource("data/ui/xbox/platform_unknown_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case _:
					return null;
			};
			if (t != null)
				t.scaleToSize(t.width * (Settings.uiScale), t.height * (Settings.uiScale));
			return t;
		}

		var curSelection = -1;

		var serverDisplays = [];

		var serverList = new GuiMLTextListCtrl(arial14, serverDisplays, imgLoader);

		serverList.selectedColor = 0xF29515;
		serverList.selectedFillColor = 0x858585;
		serverList.position = new Vector(25, 22);
		serverList.extent = new Vector(680, 480);
		serverList.scrollable = true;
		serverList.onSelectedFunc = (sel) -> {
			curSelection = sel;
		}
		serverWnd.addChild(serverList);

		var ourServerList:Array<RemoteServerInfo> = [];
		var platformToString = ["unknown", "pc", "mac", "web", "android"];

		function updateServerListDisplay() {
			serverDisplays = ourServerList.map(x -> return
				'<img src="${platformToString[x.platform]}"></img><font color="#FFFFFF">${x.players}/${x.maxPlayers}  ${x.name}</font>');
			serverList.setTexts(serverDisplays);
		}

		var serverListStatusText = new GuiText(arial14);
		serverListStatusText.text.text = "Searching for matches...";
		serverListStatusText.justify = Center;
		serverListStatusText.horizSizing = Center;
		serverListStatusText.vertSizing = Center;
		serverListStatusText.position = new Vector();
		serverListStatusText.extent = new Vector(100, 30);
		serverList.addChild(serverListStatusText);

		MasterServerClient.connectToMasterServer(() -> {
			MasterServerClient.instance.getServerList((servers) -> {
				ourServerList = servers;
				updateServerListDisplay();

				if (ourServerList.length == 0) {
					serverListStatusText.text.visible = true;
					serverListStatusText.text.text = "No matches found, you should start a match for others.";
				} else {
					serverListStatusText.text.visible = false;
				}
			});
		});

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Back", 160);
		backButton.position = new Vector(400, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = ["B"];
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MainMenuGui());
		bottomBar.addChild(backButton);

		var refreshing = false;

		var refreshButton = new GuiXboxButton("Refresh", 220);
		refreshButton.position = new Vector(750, 0);
		refreshButton.vertSizing = Bottom;
		refreshButton.horizSizing = Right;
		refreshButton.pressedAction = (e) -> {
			if (refreshing)
				return;
			refreshing = true;
			serverListStatusText.text.visible = true;
			serverListStatusText.text.text = "Searching for matches...";
			MasterServerClient.connectToMasterServer(() -> {
				MasterServerClient.instance.getServerList((servers) -> {
					ourServerList = servers;
					updateServerListDisplay();
					refreshing = false;

					if (ourServerList.length == 0) {
						serverListStatusText.text.visible = true;
						serverListStatusText.text.text = "No matches found, you should start a match for others.";
					} else {
						serverListStatusText.text.visible = false;
					}
				});
			}, () -> {
				refreshing = false;
				serverListStatusText.text.visible = true;
				serverListStatusText.text.text = "Failed to connect to master server.";
			});
		}
		bottomBar.addChild(refreshButton);

		var nextButton = new GuiXboxButton("Join", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.accelerators = [hxd.Key.ENTER];
		nextButton.gamepadAccelerator = ["X"];
		nextButton.pressedAction = (e) -> {
			if (curSelection != -1) {
				var selectedServerVersion = ourServerList[curSelection].version;
				if (selectedServerVersion != MarbleGame.currentVersion) {
					var pup = new MessageBoxOkDlg("You are using a different version of the game than the server. Please update your game.");
					MarbleGame.canvas.pushDialog(pup);
					return;
				}

				MarbleGame.canvas.setContent(new MultiplayerLoadingGui("Connecting"));
				var failed = true;
				haxe.Timer.delay(() -> {
					if (failed) {
						if (MarbleGame.canvas.content is MultiplayerLoadingGui) {
							var loadGui:MultiplayerLoadingGui = cast MarbleGame.canvas.content;
							if (loadGui != null) {
								loadGui.setErrorStatus("Failed to connect to server. Please try again.");
								Net.disconnect();
							}
						}
					}
				}, 15000);
				Net.joinServer(ourServerList[curSelection].name, false, () -> {
					failed = false;
					Net.remoteServerInfo = ourServerList[curSelection];
				});
			}
		};
		bottomBar.addChild(nextButton);
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);

		super.onResize(width, height);
	}
}
