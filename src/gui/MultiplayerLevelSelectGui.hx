package gui;

import net.ClientConnection.NetPlatform;
import net.Net;
import net.NetCommands;
import modes.GameMode.ScoreType;
import src.Util;
import haxe.io.Path;
import h2d.filter.DropShadow;
import src.MarbleGame;
import gui.GuiControl.MouseState;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.MissionList;

class MultiplayerLevelSelectGui extends GuiImage {
	static var currentSelectionStatic:Int = 0;

	static var setLevelFn:Int->Void;
	static var playSelectedLevel:Int->Void;
	static var setLevelStr:String->Void;

	var playerList:GuiMLTextListCtrl;
	var customList:GuiTextListCtrl;
	var updatePlayerCountFn:(Int, Int, Int, Int) -> Void;
	var innerCtrl:GuiControl;
	var inviteVisibility:Bool = true;
	var chatWnd:ChatCtrl;

	static var custSelected:Bool = false;
	static var custPath:String;

	var showingCustoms = false;

	public function new(isHost:Bool) {
		var res = ResourceLoader.getImage("data/ui/game/CloudBG.jpg").resource.toTile();
		super(res);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		var arial12 = arial14b.toSdfFont(cast 16 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		function mlFontLoader(text:String) {
			switch (text) {
				case "arial14":
					return arial14;
				case "arial12":
					return arial12;
			}
			return null;
		}

		MarbleGame.instance.toRecord = false;

		var fadeEdge = new GuiImage(ResourceLoader.getResource("data/ui/xbox/BG_fadeOutSoftEdge.png", ResourceLoader.getImage, this.imageResources).toTile());
		fadeEdge.position = new Vector(0, 0);
		fadeEdge.extent = new Vector(640, 480);
		fadeEdge.vertSizing = Height;
		fadeEdge.horizSizing = Width;
		this.addChild(fadeEdge);

		var loadAnim = new GuiLoadAnim();
		loadAnim.position = new Vector(610, 253);
		loadAnim.extent = new Vector(63, 63);
		loadAnim.horizSizing = Center;
		loadAnim.vertSizing = Bottom;
		this.addChild(loadAnim);

		var loadTextBg = new GuiText(arial14);
		loadTextBg.position = new Vector(608, 335);
		loadTextBg.extent = new Vector(63, 40);
		loadTextBg.horizSizing = Center;
		loadTextBg.vertSizing = Bottom;
		loadTextBg.justify = Center;
		loadTextBg.text.text = "Loading";
		loadTextBg.text.textColor = 0;
		this.addChild(loadTextBg);

		var loadText = new GuiText(arial14);
		loadText.position = new Vector(610, 334);
		loadText.extent = new Vector(63, 40);
		loadText.horizSizing = Center;
		loadText.vertSizing = Bottom;
		loadText.justify = Center;
		loadText.text.text = "Loading";
		this.addChild(loadText);

		var difficultyMissions = MissionList.missionList['ultra']["multiplayer"];
		if (currentSelectionStatic >= difficultyMissions.length)
			currentSelectionStatic = 0;
		var curMission = difficultyMissions[currentSelectionStatic];

		var lock = true;
		var currentToken = 0;
		var requestToken = 0;

		// var misFile = Path.withoutExtension(Path.withoutDirectory(curMission.path));
		// MarbleGame.instance.setPreviewMission(misFile, () -> {
		// 	lock = false;
		// 	if (currentToken != requestToken)
		// 		return;
		// 	this.bmp.visible = false;
		// 	loadAnim.anim.visible = false;
		// 	loadText.text.visible = false;
		// 	loadTextBg.text.visible = false;
		// });

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 42 * Settings.uiScale, MultiChannel);

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);
		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if (js || uwp)
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
		var coliseumfontdata = ResourceLoader.getFileEntry("data/font/ColiseumRR.fnt");
		var coliseumb = new BitmapFont(coliseumfontdata.entry);
		@:privateAccess coliseumb.loader = ResourceLoader.loader;
		var coliseum = coliseumb.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var rootTitle = new GuiText(coliseum);

		rootTitle.position = new Vector(100, 30);
		rootTitle.extent = new Vector(1120, 80);
		rootTitle.text.textColor = 0xFFFFFF;
		rootTitle.text.text = "LOBBY";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var playerWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/achievementWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		playerWnd.horizSizing = Right;
		playerWnd.vertSizing = Bottom;
		playerWnd.position = new Vector(330, 58);
		playerWnd.extent = new Vector(640, 480);
		innerCtrl.addChild(playerWnd);

		var playerListArr = [];
		if (Net.isHost) {
			playerListArr.push({
				name: Settings.highscoreName,
				state: Net.lobbyHostReady,
				platform: Net.getPlatform()
			});
		}
		if (Net.isClient) {
			playerListArr.push({
				name: Settings.highscoreName,
				state: Net.clientConnection.lobbyReady,
				platform: Net.getPlatform()
			});
		}

		if (Net.clientIdMap != null) {
			for (c => v in Net.clientIdMap) {
				playerListArr.push({
					name: v.name,
					state: v.lobbyReady,
					platform: v.platform
				});
			}
		}

		function imgLoader(path:String) {
			var t = switch (path) {
				case "ready":
					ResourceLoader.getResource("data/ui/xbox/Ready.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "notready":
					ResourceLoader.getResource("data/ui/xbox/NotReady.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "pc":
					ResourceLoader.getResource("data/ui/xbox/platform_desktop.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "mac":
					ResourceLoader.getResource("data/ui/xbox/platform_mac.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "web":
					ResourceLoader.getResource("data/ui/xbox/platform_web.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "android":
					ResourceLoader.getResource("data/ui/xbox/platform_android.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					ResourceLoader.getResource("data/ui/xbox/platform_unknown.png", ResourceLoader.getImage, this.imageResources).toTile();
				case _:
					return null;
			}
			if (t != null)
				t.scaleToSize(t.width * (Settings.uiScale), t.height * (Settings.uiScale));

			return t;
		}

		chatWnd = new ChatCtrl();
		chatWnd.horizSizing = Left;
		chatWnd.position = new Vector(330, 58);
		chatWnd.extent = new Vector(200, 250);
		innerCtrl.addChild(chatWnd);

		playerList = new GuiMLTextListCtrl(arial14, playerListArr.map(player -> {
			return '<img src="${player.state ? "ready" : "notready"}"></img><img src="${platformToString(player.platform)}"></img>${player.name}';
		}), imgLoader);
		playerList.selectedColor = 0xF29515;
		playerList.selectedFillColor = 0xEBEBEB;
		playerList.position = new Vector(25, 22);
		playerList.extent = new Vector(550, 480);
		playerList.scrollable = true;
		playerList.onSelectedFunc = (sel) -> {}
		playerWnd.addChild(playerList);

		var custWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/helpWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		custWnd.horizSizing = Right;
		custWnd.vertSizing = Bottom;
		custWnd.position = new Vector(330, 58);
		custWnd.extent = new Vector(640, 330);

		var customListScroll = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/osxscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		customListScroll.position = new Vector(25, 22);
		customListScroll.extent = new Vector(600, 280);
		customListScroll.scrollToBottom = false;
		custWnd.addChild(customListScroll);

		customList = new GuiTextListCtrl(arial14, MPCustoms.missionList.map(mission -> {
			return mission.title;
		}), 0xFFFFFF);
		var custSelectedIdx = 0;
		customList.selectedColor = 0xF29515;
		customList.selectedFillColor = 0x858585;
		customList.textColor = 0xFFFFFF;
		customList.position = new Vector(0, 0);
		customList.extent = new Vector(550, 2880);
		customList.scrollable = true;
		customList.onSelectedFunc = (idx) -> {
			NetCommands.setLobbyCustLevelName(MPCustoms.missionList[idx].path);
			custSelected = true;
			custSelectedIdx = idx;
			custPath = MPCustoms.missionList[idx].path;
			updateLobbyNames();
		}
		customListScroll.addChild(customList);
		customListScroll.setScrollMax(customList.calculateFullHeight());
		// playerWnd.addChild(customList);

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
		backButton.gamepadAccelerator = [Settings.gamepadSettings.back];
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		backButton.pressedAction = (e) -> {
			Net.disconnect();
			if (Net.isHost) {
				MarbleGame.canvas.setContent(new CreateMatchGui());
			} else {
				MarbleGame.canvas.setContent(new MultiplayerGui());
			}
		}
		bottomBar.addChild(backButton);

		if (Net.isHost) {
			var customsButton = new GuiXboxButton("Customs", 200);
			customsButton.position = new Vector(560, 0);
			customsButton.vertSizing = Bottom;
			customsButton.horizSizing = Right;
			customsButton.gamepadAccelerator = [Settings.gamepadSettings.alt1];
			customsButton.pressedAction = (e) -> {
				showingCustoms = !showingCustoms;
				if (showingCustoms) {
					innerCtrl.removeChild(playerWnd);
					innerCtrl.addChild(custWnd);
				} else {
					innerCtrl.addChild(playerWnd);
					innerCtrl.removeChild(custWnd);
					updateLobbyNames();
				}
				MarbleGame.canvas.render(MarbleGame.canvas.scene2d);
			}
			bottomBar.addChild(customsButton);

			var inviteButton = new GuiXboxButton("Invite Visibility", 220);
			inviteButton.position = new Vector(750, 0);
			inviteButton.vertSizing = Bottom;
			inviteButton.horizSizing = Right;
			inviteButton.gamepadAccelerator = [Settings.gamepadSettings.alt2];
			inviteButton.pressedAction = (e) -> {
				inviteVisibility = !inviteVisibility;
				updateLobbyNames();
			}
			bottomBar.addChild(inviteButton);
		}

		var nextButton = new GuiXboxButton("Ready", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.gamepadAccelerator = [Settings.gamepadSettings.ok];
		nextButton.accelerators = [hxd.Key.ENTER];
		nextButton.pressedAction = (e) -> {
			NetCommands.toggleReadiness(Net.isClient ? Net.clientId : 0);
		};
		bottomBar.addChild(nextButton);

		playSelectedLevel = (index:Int) -> {
			if (custSelected) {
				NetCommands.playCustomLevel(MPCustoms.missionList[custSelectedIdx].path);
			} else {
				curMission = difficultyMissions[index];
				MarbleGame.instance.playMission(curMission, true);
			}
		}

		var levelWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/levelPreviewWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		levelWnd.position = new Vector(555, 469);
		levelWnd.extent = new Vector(535, 137);
		levelWnd.vertSizing = Bottom;
		levelWnd.horizSizing = Right;
		innerCtrl.addChild(levelWnd);

		var c0 = 0xEBEBEB;
		var c1 = 0x8DFF8D;
		var c2 = 0x88BCEE;
		var c3 = 0xFF7575;

		var levelInfoLeft = new GuiMLText(arial14, mlFontLoader);
		levelInfoLeft.position = new Vector(33, 40);
		levelInfoLeft.extent = new Vector(480, 100);
		levelInfoLeft.text.text = '';
		levelInfoLeft.text.lineSpacing = 0;
		levelInfoLeft.text.filter = new h2d.filter.DropShadow(2, 0.785, 0x000000, 1, 0, 0.4, 1, true);
		levelWnd.addChild(levelInfoLeft);

		var levelNames = difficultyMissions.map(x -> x.title);
		var levelSelectOpts = new GuiXboxOptionsList(6, "Level", levelNames, 0.3, 155.5, isHost);

		function setLevel(idx:Int) {
			// if (lock)
			//	return false;
			custSelected = false;
			levelSelectOpts.currentOption = idx;
			this.bmp.visible = true;
			loadAnim.anim.visible = true;
			loadText.text.visible = true;
			loadTextBg.text.visible = true;
			lock = true;
			curMission = difficultyMissions[idx];
			currentSelectionStatic = idx;
			currentToken++;
			var misFile = Path.withoutExtension(Path.withoutDirectory(curMission.path));
			var mis = difficultyMissions[idx];
			var requestToken = currentToken;
			MarbleGame.instance.setPreviewMission(misFile, () -> {
				lock = false;
				if (requestToken != currentToken)
					return;
				this.bmp.visible = false;
				loadAnim.anim.visible = false;
				loadText.text.visible = false;
				loadTextBg.text.visible = false;
			});
			var hostName = Settings.highscoreName;
			if (!Net.isHost) {
				hostName = Net.clientIdMap[0].getName();
			}

			if (Net.isHost) {
				updatePlayerCountFn = (pub:Int, priv:Int, publicTotal:Int, privateTotal:Int) -> {
					if (inviteVisibility)
						levelInfoLeft.text.text = '<p><font face="arial14">Host: ${hostName}</font></p>'
							+ '<p><font face="arial14">Level: ${levelSelectOpts.optionText.text.text}</font></p>'
							+
							'<p><font face="arial12">Public Slots: ${pub}/${publicTotal}, Private Slots: ${priv}/${privateTotal}, Invite Code: ${Net.serverInfo.inviteCode}</font></p>';
					else
						levelInfoLeft.text.text = '<p><font face="arial14">Host: ${hostName}</font></p>'
							+ '<p><font face="arial14">Level: ${levelSelectOpts.optionText.text.text}</font></p>'
							+ '<p><font face="arial12">Public Slots: ${pub}/${publicTotal}, Private Slots: ${priv}/${privateTotal}</font></p>';
				}
				var pubCount = 1; // 1 for host
				var privCount = 0;
				for (cid => cc in Net.clientIdMap) {
					if (cc.isPrivate) {
						privCount++;
					} else {
						pubCount++;
					}
				}

				updatePlayerCountFn(pubCount, privCount, Net.serverInfo.maxPlayers - Net.serverInfo.privateSlots, Net.serverInfo.privateSlots);
			}
			if (Net.isClient) {
				updatePlayerCountFn = (pub:Int, priv:Int, publicTotal:Int, privateTotal:Int) -> {
					levelInfoLeft.text.text = '<p><font face="arial14">Host: ${hostName}</font></p>'
						+ '<p><font face="arial14">Level: ${levelSelectOpts.optionText.text.text}</font></p>';
				}
				updatePlayerCountFn(0, 0, 0, 0);
			}
			return true;
		}

		levelSelectOpts.position = new Vector(380, 430);
		levelSelectOpts.extent = new Vector(815, 94);
		levelSelectOpts.vertSizing = Bottom;
		levelSelectOpts.horizSizing = Right;
		levelSelectOpts.alwaysActive = true;
		levelSelectOpts.onChangeFunc = (i) -> {
			NetCommands.setLobbyLevelIndex(i);
			return true;
		};

		setLevelFn = (idx) -> {
			levelSelectOpts.setCurrentOption(idx);
			setLevel(idx);
		};

		setLevelStr = (str) -> {
			var cust = MPCustoms.missionList.filter(x -> x.path == str)[0];
			levelSelectOpts.optionText.text.text = cust.title;
			custSelected = true;
			custPath = str;
			if (Net.isHost) {
				updateLobbyNames();
			} else
				updatePlayerCountFn(0, 0, 0, 0);
		}

		var customIsSelected = custSelected == true;
		levelSelectOpts.setCurrentOption(currentSelectionStatic);
		setLevel(currentSelectionStatic);
		innerCtrl.addChild(levelSelectOpts);

		if (customIsSelected) {
			setLevelStr(custPath);
		}
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

	inline function platformToString(platform:NetPlatform) {
		return switch (platform) {
			case Unknown: return "unknown";
			case Android: return "android";
			case MacOS: return "mac";
			case PC: return "pc";
			case Web: return "web";
		}
	}

	public function updateLobbyNames() {
		var playerListArr = [];
		if (Net.isHost) {
			playerListArr.push({
				name: Settings.highscoreName,
				state: Net.lobbyHostReady,
				platform: Net.getPlatform()
			});
		}
		if (Net.isClient) {
			playerListArr.push({
				name: Settings.highscoreName,
				state: Net.lobbyClientReady,
				platform: Net.getPlatform()
			});
		}
		if (Net.clientIdMap != null) {
			for (c => v in Net.clientIdMap) {
				playerListArr.push({
					name: v.name,
					state: v.lobbyReady,
					platform: v.platform
				});
			}
		}

		if (!showingCustoms)
			playerList.setTexts(playerListArr.map(player -> {
				return '<img src="${player.state ? "ready" : "notready"}"></img><img src="${platformToString(player.platform)}"></img>${player.name}';
			}));

		var pubCount = 1; // Self
		var privCount = 0;
		for (cid => cc in Net.clientIdMap) {
			if (cc.isPrivate) {
				privCount++;
			} else {
				pubCount++;
			}
		}

		if (Net.isHost) {
			updatePlayerCountFn(pubCount, privCount, Net.serverInfo.maxPlayers - Net.serverInfo.privateSlots, Net.serverInfo.privateSlots);
		}
	}

	public function updatePlayerCount(pub:Int, priv:Int, publicTotal:Int, privateTotal:Int) {
		updatePlayerCountFn(pub, priv, publicTotal, privateTotal);
	}

	public function addChatMessage(str:String) {
		this.chatWnd.addChatMessage(str);
	}

	override function dispose() {
		super.dispose();
		playSelectedLevel = null;
		setLevelFn = null;
	}

	override function update(dt:Float, mouseState:MouseState) {
		this.chatWnd.updateChat(dt);
		super.update(dt, mouseState);
	}
}
