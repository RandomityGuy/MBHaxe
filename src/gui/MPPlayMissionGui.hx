package gui;

import h2d.Scene;
import hxd.Key;
import gui.GuiControl.MouseState;
import h2d.Tile;
import hxd.BitmapData;
import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import src.MarbleGame;
import src.ResourceLoader;
import h3d.Vector;
import src.Util;
import src.Settings;
import src.Mission;
import src.MissionList;
import net.ClientConnection.NetPlatform;
import net.Net;
import net.NetCommands;

class MPPlayMissionGui extends GuiImage {
	static var currentSelectionStatic:Int = -1;
	static var currentCategoryStatic:String = "beginner";

	static var setLevelFn:(String, Int) -> Void;
	static var playSelectedLevel:(String, Int) -> Void;
	static var setLevelStr:String->Void;

	var currentSelection:Int = 0;
	var currentCategory:String = "beginner";
	var currentList:Array<Mission>;
	var setSelectedFunc:Int->Void;
	var setScoreHover:Bool->Void;
	var setCategoryFunc:(String, ?String, ?Bool) -> Void;
	var buttonHoldFunc:(dt:Float, mouseState:MouseState) -> Void;

	var buttonCooldown:Float = 0.5;
	var maxButtonCooldown:Float = 0.5;

	#if js
	var previewTimeoutHandle:Option<Int> = None;
	#end
	#if hl
	var previewToken:Int = 0;
	#end

	var playerListCtrl:GuiTextListCtrl;

	public function new(isHost:Bool = true) {
		MissionList.buildMissionList();
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

		if (currentSelectionStatic == -1) {
			currentSelectionStatic = 0;
		}

		// currentSelection = PlayMissionGui.currentSelectionStatic;
		currentCategory = PlayMissionGui.currentCategoryStatic;

		MarbleGame.instance.toRecord = false;

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

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual24b = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24b.loader = ResourceLoader.loader;
		var domcasual24 = domcasual24b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		var domcasual32 = domcasual24b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var arialb14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arialb14b = new BitmapFont(arialb14fontdata.entry);
		@:privateAccess arialb14b.loader = ResourceLoader.loader;
		var arialBold14 = arialb14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);
		var markerFelt20 = markerFelt32b.toSdfFont(cast 18.5 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);
		var markerFelt26 = markerFelt32b.toSdfFont(cast 22 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual24":
					return domcasual24;
				case "Arial14":
					return arial14;
				case "ArialBold14":
					return arialBold14;
				case "MarkerFelt32":
					return markerFelt32;
				case "MarkerFelt24":
					return markerFelt24;
				case "MarkerFelt18":
					return markerFelt18;
				case "MarkerFelt20":
					return markerFelt20;
				case "MarkerFelt26":
					return markerFelt26;
				default:
					return null;
			}
		}

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var window = new GuiImage(ResourceLoader.getResource("data/ui/mp/play/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		window.horizSizing = Center;
		window.vertSizing = Center;
		window.position = new Vector(-60, 5);
		window.extent = new Vector(800, 600);

		var leaveBtn = new GuiButton(loadButtonImages("data/ui/mp/play/leave"));
		leaveBtn.position = new Vector(59, 514);
		leaveBtn.extent = new Vector(93, 44);
		leaveBtn.pressedAction = (e) -> {
			MarbleGame.canvas.setContent(new JoinServerGui());
		}
		window.addChild(leaveBtn);

		var searchBtn = new GuiButton(loadButtonImages("data/ui/mp/play/search"));
		searchBtn.position = new Vector(255, 514);
		searchBtn.extent = new Vector(44, 44);
		searchBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MPSearchGui(false));
		}
		if (Net.isHost)
			window.addChild(searchBtn);

		var kickBtn = new GuiButton(loadButtonImages("data/ui/mp/play/kick"));
		kickBtn.position = new Vector(304, 514);
		kickBtn.extent = new Vector(44, 44);
		kickBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MPKickBanDlg());
		}
		if (Net.isHost)
			window.addChild(kickBtn);

		var serverSettingsBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/play/settings"));
		serverSettingsBtn.position = new Vector(157, 514);
		serverSettingsBtn.extent = new Vector(44, 44);
		serverSettingsBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MPServerDlg());
		}
		if (Net.isHost)
			window.addChild(serverSettingsBtn);

		var marbleSelectBtn = new GuiButton(loadButtonImages("data/ui/mp/play/marble"));
		marbleSelectBtn.position = new Vector(206, 514);
		marbleSelectBtn.extent = new Vector(44, 44);
		marbleSelectBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MPMarbleSelectGui());
		}
		window.addChild(marbleSelectBtn);

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = Tile.fromBitmap(temprev);

		var pmPreview = new GuiImage(tmpprevtile);
		pmPreview.position = new Vector(485, 44);
		pmPreview.extent = new Vector(248, 187);
		window.addChild(pmPreview);

		var difficultyPopover = new GuiControl();
		difficultyPopover.horizSizing = Width;
		difficultyPopover.vertSizing = Height;
		difficultyPopover.position = new Vector();
		difficultyPopover.extent = new Vector(640, 480);

		var difficultyPopoverInner = new GuiImage(tmpprevtile);
		difficultyPopoverInner.horizSizing = Center;
		difficultyPopoverInner.vertSizing = Center;
		difficultyPopoverInner.position = new Vector();
		difficultyPopoverInner.extent = new Vector(800, 600);
		difficultyPopoverInner.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(difficultyPopover, false);
		}
		difficultyPopover.addChild(difficultyPopoverInner);

		var difficultySelector = new GuiButton(loadButtonImages("data/ui/mp/play/difficulty_beginner"));
		difficultySelector.position = new Vector(161, 47);
		difficultySelector.extent = new Vector(204, 44);
		if (isHost)
			difficultySelector.pressedAction = (e) -> {
				MarbleGame.canvas.pushDialog(difficultyPopover);
			};
		else
			difficultySelector.disabled = true;
		window.addChild(difficultySelector);

		var difficultyCloseButton = new GuiButton(loadButtonImages("data/ui/mp/play/difficultymenu"));
		difficultyCloseButton.position = new Vector(129, 61);
		difficultyCloseButton.extent = new Vector(268, 193);
		difficultyPopoverInner.addChild(difficultyCloseButton);

		var catFuncBuilder = (cat:String) -> {
			return () -> {
				currentList = MissionList.missionList["multiplayer"][cat];
				currentCategory = cat;
				setCategoryFunc(cat);
			}
		}
		var beginnerFn = catFuncBuilder("beginner");
		var intermediateFn = catFuncBuilder("intermediate");
		var advancedFn = catFuncBuilder("advanced");
		var customFn = catFuncBuilder("custom");

		var difficulty0 = new GuiButtonText(loadButtonImages("data/ui/mp/play/difficultysel"), markerFelt24);
		difficulty0.position = new Vector(43, 42);
		difficulty0.ratio = -1 / 16;
		difficulty0.setExtent(new Vector(180, 31));
		difficulty0.txtCtrl.text.text = "Intermediate";
		difficulty0.pressedAction = (e) -> {
			intermediateFn();
		}
		difficultyCloseButton.addChild(difficulty0);

		var difficulty1 = new GuiButtonText(loadButtonImages("data/ui/mp/play/difficultysel"), markerFelt24);
		difficulty1.position = new Vector(43, 72);
		difficulty1.ratio = -1 / 16;
		difficulty1.setExtent(new Vector(180, 31));
		difficulty1.txtCtrl.text.text = "Advanced";
		difficulty1.pressedAction = (e) -> {
			advancedFn();
		}
		difficultyCloseButton.addChild(difficulty1);

		var difficulty2 = new GuiButtonText(loadButtonImages("data/ui/mp/play/difficultysel"), markerFelt24);
		difficulty2.position = new Vector(43, 116);
		difficulty2.ratio = -1 / 16;
		difficulty2.setExtent(new Vector(180, 31));
		difficulty2.txtCtrl.text.text = "Custom";
		difficulty2.pressedAction = (e) -> {
			customFn();
		}
		difficultyCloseButton.addChild(difficulty2);

		var pmPreviewFrame = new GuiImage(ResourceLoader.getResource('data/ui/mp/play/levelframe.png', ResourceLoader.getImage, this.imageResources).toTile());
		pmPreviewFrame.position = new Vector(0, 0);
		pmPreviewFrame.extent = new Vector(248, 187);
		pmPreview.addChild(pmPreviewFrame);

		var prevBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/play/prev"));
		prevBtn.position = new Vector(491, 514);
		prevBtn.extent = new Vector(73, 44);
		prevBtn.gamepadAccelerator = ["dpadLeft"];
		prevBtn.pressedAction = (sender) -> {
			NetCommands.setLobbyLevelIndex(currentCategory, currentSelection - 1);
		}
		if (isHost)
			window.addChild(prevBtn);

		var nextBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/play/next"));
		nextBtn.position = new Vector(659, 514);
		nextBtn.extent = new Vector(73, 44);
		nextBtn.gamepadAccelerator = ["dpadRight"];

		nextBtn.pressedAction = (sender) -> {
			NetCommands.setLobbyLevelIndex(currentCategory, currentSelection + 1);
		}
		if (isHost)
			window.addChild(nextBtn);

		var playBtn = new GuiButton(loadButtonImages("data/ui/mp/play/play"));
		playBtn.position = new Vector(565, 514);
		playBtn.extent = new Vector(93, 44);
		playBtn.pressedAction = (sender) -> {
			NetCommands.toggleReadiness(Net.isClient ? Net.clientId : 0);
			// MarbleGame.instance.playMission(currentList[currentSelection], true);
		}
		window.addChild(playBtn);

		var pmDescContainer = new GuiControl();
		pmDescContainer.position = new Vector(43, 99);
		pmDescContainer.extent = new Vector(427, 99);
		window.addChild(pmDescContainer);

		var pmDesc = new GuiMLText(markerFelt18, mlFontLoader);
		pmDesc.position = new Vector(0, 0);
		pmDesc.extent = new Vector(427, 99);
		pmDesc.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		pmDesc.text.lineSpacing = -1;
		pmDescContainer.addChild(pmDesc);

		var parTime = new GuiMLText(markerFelt18, mlFontLoader);
		parTime.position = new Vector(43, 190);
		parTime.extent = new Vector(416, 44);
		parTime.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		parTime.text.lineSpacing = -1;
		window.addChild(parTime);

		var playersBox = new GuiControl();
		playersBox.position = new Vector(463, 279);
		playersBox.extent = new Vector(305, 229);
		window.addChild(playersBox);

		playerListCtrl = new GuiTextListCtrl(markerFelt18, [], 0xFFFFFF);
		playerListCtrl.position = new Vector(0, 26);
		playerListCtrl.extent = new Vector(305, 203);
		playerListCtrl.scrollable = true;
		playerListCtrl.textYOffset = -6;
		playersBox.addChild(playerListCtrl);

		var playerListTitle = new GuiText(markerFelt24);
		playerListTitle.position = new Vector(7, 0);
		playerListTitle.extent = new Vector(275, 22);
		playerListTitle.text.text = "Players";
		playerListTitle.text.textColor = 0xBDCFE4;
		playerListTitle.justify = Center;
		playerListTitle.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		playersBox.addChild(playerListTitle);

		this.addChild(window);

		buttonHoldFunc = (dt:Float, mouseState:MouseState) -> {
			var prevBox = prevBtn.getRenderRectangle();
			var nextBox = nextBtn.getRenderRectangle();

			if (prevBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					prevBtn.pressedAction(new GuiEvent(prevBtn));
					buttonCooldown = maxButtonCooldown;
					maxButtonCooldown *= 0.75;
				}
			}

			if (nextBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					nextBtn.pressedAction(new GuiEvent(nextBtn));
					buttonCooldown = maxButtonCooldown;
					maxButtonCooldown *= 0.75;
				}
			}

			if (buttonCooldown > 0 && mouseState.button == Key.MOUSE_LEFT)
				buttonCooldown -= dt;

			if (mouseState.button != Key.MOUSE_LEFT) {
				maxButtonCooldown = 0.5;
				buttonCooldown = maxButtonCooldown;
			}
		}

		setCategoryFunc = function(category:String, ?sort:String = null, ?doRender:Bool = true) {
			currentList = MissionList.missionList["multiplayer"][category];

			@:privateAccess difficultySelector.anim.frames = loadButtonImages('data/ui/mp/play/difficulty_${category}');

			if (category == "beginner") {
				difficulty0.txtCtrl.text.text = "Intermediate";
				difficulty1.txtCtrl.text.text = "Advanced";
				difficulty2.txtCtrl.text.text = "Custom";
				difficulty0.pressedAction = (e) -> {
					intermediateFn();
				}
				difficulty1.pressedAction = (e) -> {
					advancedFn();
				}
				difficulty2.pressedAction = (e) -> {
					customFn();
				}
			}
			if (category == "intermediate") {
				difficulty0.txtCtrl.text.text = "Beginner";
				difficulty1.txtCtrl.text.text = "Advanced";
				difficulty2.txtCtrl.text.text = "Custom";
				difficulty0.pressedAction = (e) -> {
					beginnerFn();
				}
				difficulty1.pressedAction = (e) -> {
					advancedFn();
				}
				difficulty2.pressedAction = (e) -> {
					customFn();
				}
			}
			if (category == "custom") {
				difficulty0.txtCtrl.text.text = "Beginner";
				difficulty1.txtCtrl.text.text = "Intermediate";
				difficulty2.txtCtrl.text.text = "Advanced";
				difficulty0.pressedAction = (e) -> {
					beginnerFn();
				}
				difficulty1.pressedAction = (e) -> {
					intermediateFn();
				}
				difficulty2.pressedAction = (e) -> {
					advancedFn();
				}
			}

			if (sort != null) {
				currentList = currentList.copy(); // Don't modify the originals
				if (sort == "alpha") {
					currentList.sort((x, y) -> x.title > y.title ? 1 : (x.title < y.title ? -1 : 0));
				}
				if (sort == "date") {
					currentList.sort((x, y) -> x.addedAt > y.addedAt ? 1 : (x.addedAt < y.addedAt ? -1 : 0));
				}
			}

			currentCategoryStatic = currentCategory;

			NetCommands.setLobbyLevelIndex(category, currentList.length - 1);
			// if (doRender)
			//	this.render(cast(this.parent, Canvas).scene2d);
		}

		setSelectedFunc = function setSelected(index:Int) {
			if (index > currentList.length - 1) {
				index = currentList.length - 1;
			}
			if (index < 0) {
				index = 0;
			}

			currentSelection = index;
			currentSelectionStatic = currentSelection;

			var currentMission = currentList[currentSelection];

			if (index == 0) {
				prevBtn.disabled = true;
			} else
				prevBtn.disabled = false;
			if (index == Math.max(currentList.length - 1, 0)) {
				nextBtn.disabled = true;
			} else
				nextBtn.disabled = false;

			// if (currentCategory != "custom"
			// 	&& Settings.progression[["beginner", "intermediate", "advanced", "expert"].indexOf(currentCategory)] < currentSelection) {
			// 	noQualText.text.visible = true;
			// 	filt.matrix.identity();
			// 	filt.matrix.colorGain(0, 96 / 255);
			// 	pmPlay.disabled = true;
			// } else {
			playBtn.disabled = false;
			// }

			if (currentMission == null) {
				currentMission = new Mission();
				currentMission.title = "";
				currentMission.description = "";
				currentMission.path = "bruh";
				currentSelection = -1;
			}

			pmDesc.text.text = '<font face="MarkerFelt32" color="#E3F3FF"><p align="center">#${currentSelection + 1}: ${currentMission.title}</p></font>'
				+ '<font face="MarkerFelt18" color="#CEE0F4">${currentMission.description}</font>';

			parTime.text.text = '<font face="MarkerFelt24" color="#E3F3FF">Duration: <font color="#FFFFFF">${Util.formatTime(currentMission.qualifyTime)}</font></font><br/>'
				+ '<font face="MarkerFelt24" color="#E3F3FF">Author: <font color="#FFFFFF">${currentMission.artist}</font></font>';

			// pmPreview.bmp.tile = tmpprevtile;
			#if js
			switch (previewTimeoutHandle) {
				case None:
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						var prevpath = currentMission.getPreviewImage(prevImg -> {
							pmPreview.bmp.tile = prevImg;
						});
						if (prevpath != pmPreview.bmp.tile.getTexture().name) {
							pmPreview.bmp.tile = tmpprevtile;
						}
					}, 75));
				case Some(previewTimeoutHandle_id):
					js.Browser.window.clearTimeout(previewTimeoutHandle_id);
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						var prevpath = currentMission.getPreviewImage(prevImg -> {
							pmPreview.bmp.tile = prevImg;
						});
						if (prevpath != pmPreview.bmp.tile.getTexture().name) {
							pmPreview.bmp.tile = tmpprevtile;
						}
					}, 75));
			}
			#end
			#if hl
			var pTok = previewToken++;
			var prevpath = currentMission.getPreviewImage(prevImg -> {
				if (pTok + 1 != previewToken)
					return;
				pmPreview.bmp.tile = prevImg;
			}); // Shit be sync
			if (prevpath != pmPreview.bmp.tile.getTexture().name) {
				pmPreview.bmp.tile = tmpprevtile;
			}
			#end
		}

		playSelectedLevel = (cat:String, index:Int) -> {
			// if (custSelected) {
			// 	NetCommands.playCustomLevel(MPCustoms.missionList[custSelectedIdx].path);
			// } else {
			var curMission = MissionList.missionList["multiplayer"][cat][index]; //  mission[index];
			MarbleGame.instance.playMission(curMission, true);
			// }
		}

		setLevelFn = (cat:String, index:Int) -> {
			if (currentCategory != cat) {
				currentCategory = cat;
				setCategoryFunc(cat);
			}
			setSelectedFunc(index);
		}

		currentList = MissionList.missionList["multiplayer"]["beginner"];

		setCategoryFunc(currentCategoryStatic, null, false);
		updateLobbyNames();
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		super.render(scene2d, parent);
		setSelectedFunc(currentSelectionStatic);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);

		buttonHoldFunc(dt, mouseState);

		if (Key.isPressed(Key.LEFT))
			setSelectedFunc(currentSelection - 1);
		if (Key.isPressed(Key.RIGHT))
			setSelectedFunc(currentSelection + 1);
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
				platform: Net.getPlatform()
			});
		}
		if (Net.isClient) {
			playerListArr.push({
				name: Settings.highscoreName,
				platform: Net.getPlatform()
			});
		}
		if (Net.clientIdMap != null) {
			for (c => v in Net.clientIdMap) {
				playerListArr.push({
					name: v.name,
					platform: v.platform
				});
			}
		}

		var playerListCompiled = playerListArr.map(player -> player.name);
		playerListCtrl.setTexts(playerListCompiled);

		// if (!showingCustoms)
		// 	playerList.setTexts(playerListArr.map(player -> {
		// 		return '<img src="${player.state ? "ready" : "notready"}"></img><img src="${platformToString(player.platform)}"></img>${player.name}';
		// 	}));
	}
}
