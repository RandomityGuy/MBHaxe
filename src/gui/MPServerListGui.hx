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

		var scene2d = MarbleGame.canvas.scene2d;

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
			switch (path) {
				case "ready":
					return ResourceLoader.getResource("data/ui/xbox/Ready.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "notready":
					return ResourceLoader.getResource("data/ui/xbox/NotReady.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "pc":
					return ResourceLoader.getResource("data/ui/xbox/platform_desktop_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "mac":
					return ResourceLoader.getResource("data/ui/xbox/platform_mac_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "web":
					return ResourceLoader.getResource("data/ui/xbox/platform_web_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "android":
					return ResourceLoader.getResource("data/ui/xbox/platform_android_white.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					return ResourceLoader.getResource("data/ui/xbox/platform_unknown_white.png", ResourceLoader.getImage, this.imageResources).toTile();
			}
			return null;
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

		MasterServerClient.connectToMasterServer(() -> {
			MasterServerClient.instance.getServerList((servers) -> {
				ourServerList = servers;
				updateServerListDisplay();
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

		var refreshButton = new GuiXboxButton("Refresh", 220);
		refreshButton.position = new Vector(750, 0);
		refreshButton.vertSizing = Bottom;
		refreshButton.horizSizing = Right;
		refreshButton.pressedAction = (e) -> {
			MasterServerClient.connectToMasterServer(() -> {
				MasterServerClient.instance.getServerList((servers) -> {
					ourServerList = servers;
					updateServerListDisplay();
				});
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
				MarbleGame.canvas.setContent(new MultiplayerLoadingGui("Connecting"));
				var failed = true;
				haxe.Timer.delay(() -> {
					if (failed) {
						if (MarbleGame.canvas.content is MultiplayerLoadingGui) {
							var loadGui:MultiplayerLoadingGui = cast MarbleGame.canvas.content;
							if (loadGui != null) {
								loadGui.setErrorStatus("Failed to connect to server");
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
