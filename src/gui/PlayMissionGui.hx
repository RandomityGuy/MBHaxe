package gui;

import net.ClientConnection.NetPlatform;
import src.Leaderboards.LeaderboardsKind;
import src.MarbleGame;
import src.Replay;
import haxe.ds.Option;
import hxd.Key;
import gui.GuiControl.MouseState;
import h3d.Matrix;
import h2d.filter.ColorMatrix;
import h2d.Tile;
import h3d.mat.Texture;
import h2d.Bitmap;
import hxd.BitmapData;
import src.AudioManager;
import src.Settings.Score;
import src.Settings.Settings;
import haxe.io.Path;
import h2d.Scene;
import h2d.Text;
import src.Mission;
import hxd.res.BitmapFont;
import src.ResourceLoader;
import h3d.Vector;
import src.Util;
import src.MissionList;
import src.Http;
import src.Leaderboards;
import src.Marbleland;
import src.MissionMapping;

class PlayMissionGui extends GuiImage {
	static var currentSelectionStatic:Int = -1;
	static var currentCategoryStatic:String = "beginner";
	static var currentSortType:Int = 1;

	var currentSelection:Int = 0;
	var currentCategory:String = "beginner";
	var currentList:Array<Mission>;

	var setSelectedFunc:Int->Void;
	var setCategoryFunc:(String, ?Bool) -> Void;
	var buttonHoldFunc:(dt:Float, mouseState:MouseState) -> Void;

	var buttonCooldown:Float = 0.5;
	var maxButtonCooldown:Float = 0.5;

	#if js
	var previewTimeoutHandle:Option<Int> = None;
	var lbRequest:Int = 0;
	#end

	#if hl
	var previewToken:Int = 0;
	var lbRequest:src.Http.HttpRequest = null;
	#end
	var lbToken:Int = 0;

	public function new() {
		MissionList.buildMissionList();

		if (currentSelectionStatic == -1)
			currentSelectionStatic = cast Math.min(MissionList.beginnerMissions.length - 1,
				Settings.progression[["beginner", "intermediate", "advanced"].indexOf(currentCategory)]);

		currentSelection = PlayMissionGui.currentSelectionStatic;
		currentCategory = PlayMissionGui.currentCategoryStatic;

		var img = ResourceLoader.getImage("data/ui/background.jpg");
		super(img.resource.toTile());

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

		function loadButtonImages(path:String, hasDisabled:Bool = true) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			if (hasDisabled) {
				var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
				return [normal, hover, pressed, disabled];
			} else {
				return [normal, hover, pressed];
			}
		}

		var tabAdvanced = new GuiImage(ResourceLoader.getResource("data/ui/play/tab_adv.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabAdvanced.position = new Vector(410, 21);
		tabAdvanced.extent = new Vector(166, 43);
		tabAdvanced.pressedAction = (sender) -> {
			currentList = MissionList.advancedMissions;
			setCategoryFunc("advanced");
		}
		localContainer.addChild(tabAdvanced);

		var tabIntermediate = new GuiImage(ResourceLoader.getResource("data/ui/play/tab_inter.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabIntermediate.position = new Vector(213, 6);
		tabIntermediate.extent = new Vector(205, 58);
		tabIntermediate.pressedAction = (sender) -> {
			currentList = MissionList.intermediateMissions;
			setCategoryFunc("intermediate");
		}
		localContainer.addChild(tabIntermediate);

		var tabCustom = new GuiImage(ResourceLoader.getResource("data/ui/play/cust_tab.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabCustom.position = new Vector(589, 91);
		tabCustom.extent = new Vector(52, 198);
		tabCustom.pressedAction = (sender) -> {
			if (Marbleland.goldMissions.length == 0) {
				var mbo = new MessageBoxOkDlg("Level list has not been downloaded yet. Please try again later");
				MarbleGame.canvas.pushDialog(mbo);
			} else {
				setCategoryFunc("custom");
			}

			// #if (js || android)
			// var mbo = new MessageBoxYesNoDlg("The custom level browser is not available in this game.\n Please play Marble Blast Platinum to get access to 7000+ community made customs of both Marble Blast Gold and Marble Blast Platinum. Visit download link?",
			// 	() -> {
			// 		#if sys
			// 		hxd.System.openURL("https://github.com/RandomityGuy/MBHaxe");
			// 		#end
			// 		#if js
			// 		js.Browser.window.open("https://github.com/RandomityGuy/MBHaxe");
			// 		#end
			// 	}, () -> {});

			// MarbleGame.canvas.pushDialog(mbo);
			// #else
			// currentList = MissionList.customMissions;
			// currentCategory = "custom";
			// setCategoryFunc("custom");
			// #end
		}
		localContainer.addChild(tabCustom);

		var pmBox = new GuiImage(ResourceLoader.getResource("data/ui/play/playgui.png", ResourceLoader.getImage, this.imageResources).toTile());
		pmBox.position = new Vector(0, 42);
		pmBox.extent = new Vector(610, 351);
		pmBox.horizSizing = Width;
		pmBox.vertSizing = Height;
		localContainer.addChild(pmBox);

		var textWnd = new GuiImage(ResourceLoader.getResource("data/ui/play/text_window.png", ResourceLoader.getImage, this.imageResources).toTile());
		textWnd.horizSizing = Width;
		textWnd.vertSizing = Height;
		textWnd.position = new Vector(31, 29);
		textWnd.extent = new Vector(276, 229);
		pmBox.addChild(textWnd);

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = Tile.fromBitmap(temprev);

		var pmPreview = new GuiImage(tmpprevtile);
		pmPreview.position = new Vector(312, 42);
		pmPreview.extent = new Vector(258, 193);
		pmBox.addChild(pmPreview);
		var filt = new ColorMatrix(Matrix.I());

		var replayPlayButton = new GuiImage(ResourceLoader.getResource("data/ui/play/playback.png", ResourceLoader.getImage, this.imageResources).toTile());
		replayPlayButton.position = new Vector(38, 315);
		replayPlayButton.extent = new Vector(18, 18);
		replayPlayButton.pressedAction = (sender) -> {
			hxd.File.browse((replayToLoad) -> {
				replayToLoad.load((replayData) -> {
					var replay = new Replay("");
					if (!replay.read(replayData)) {
						cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("Cannot load replay."));
						// Idk do something to notify the user here
					} else {
						var repmis = replay.mission;

						// Strip data/ from the mission name
						if (StringTools.startsWith(repmis, "data/")) {
							repmis = repmis.substr(5);
						}

						var mi = MissionList.missions.get(repmis);

						// try with data/ added
						if (mi == null) {
							if (!StringTools.contains(repmis, "data/"))
								repmis = "data/" + repmis;
							mi = MissionList.missions.get(repmis);
						}

						var playMis = mi;
						if (playMis != null) {
							cast(this.parent, Canvas).marbleGame.watchMissionReplay(playMis, replay, PlayMissionGui);
						} else {
							cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("Cannot load replay."));
						}
					}
				});
			}, {
				title: "Select replay file",
				fileTypes: [
					{
						name: "Replay (*.mbr)",
						extensions: ["mbr"]
					}
				],
			});
		};
		pmBox.addChild(replayPlayButton);

		var replayRecordButton = new GuiImage(ResourceLoader.getResource("data/ui/play/record.png", ResourceLoader.getImage, this.imageResources).toTile());
		replayRecordButton.position = new Vector(56, 315);
		replayRecordButton.extent = new Vector(18, 18);
		replayRecordButton.pressedAction = (sender) -> {
			cast(this.parent, Canvas).marbleGame.toRecord = true;
			cast(this.parent, Canvas).pushDialog(new MessageBoxOkDlg("The next mission you play will be recorded."));
		};
		pmBox.addChild(replayRecordButton);

		var levelWnd = new GuiImage(ResourceLoader.getResource("data/ui/play/level_window.png", ResourceLoader.getImage, this.imageResources).toTile());
		levelWnd.position = new Vector();
		levelWnd.extent = new Vector(258, 194);
		pmPreview.addChild(levelWnd);

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

		var levelBkgnd = new GuiText(domcasual24);
		levelBkgnd.position = new Vector(5, 156);
		levelBkgnd.extent = new Vector(254, 24);
		levelBkgnd.text.textColor = 0x000000;
		levelBkgnd.justify = Center;
		levelBkgnd.text.text = "Beginner Level 3";
		levelWnd.addChild(levelBkgnd);

		var levelFgnd = new GuiText(domcasual24);
		levelFgnd.position = new Vector(4, 155);
		levelFgnd.extent = new Vector(254, 24);
		levelFgnd.text.textColor = 0xFFFFFF;
		levelFgnd.justify = Center;
		levelFgnd.text.text = "Beginner Level 3";
		levelWnd.addChild(levelFgnd);

		var noQualText = new GuiText(domcasual32);
		noQualText.position = new Vector(0, 84);
		noQualText.extent = new Vector(254, 32);
		noQualText.text.textColor = 0xCCCCCC;
		noQualText.justify = Center;
		noQualText.text.text = "Not Qualified!";
		levelWnd.addChild(noQualText);

		var pmPlay = new GuiButton(loadButtonImages("data/ui/play/play"));
		pmPlay.position = new Vector(391, 257);
		pmPlay.extent = new Vector(121, 62);
		pmPlay.gamepadAccelerator = ["A"];
		pmPlay.pressedAction = (sender) -> {
			// Wacky hacks
			currentList[currentSelection].index = currentSelection;
			currentList[currentSelection].difficultyIndex = ["beginner", "intermediate", "advanced"].indexOf(currentCategory);
			currentSelectionStatic = currentSelection;
			currentCategoryStatic = currentCategory;
			cast(this.parent, Canvas).marbleGame.playMission(currentList[currentSelection]);
		}
		pmBox.addChild(pmPlay);

		var pmPrev = new GuiButton(loadButtonImages("data/ui/play/prev"));
		pmPrev.position = new Vector(321, 260);
		pmPrev.extent = new Vector(77, 58);
		pmPrev.gamepadAccelerator = ["dpadLeft"];
		pmPrev.pressedAction = (sender) -> {
			setSelectedFunc(currentSelection - 1);
		}
		pmBox.addChild(pmPrev);

		var pmNext = new GuiButton(loadButtonImages("data/ui/play/next"));
		pmNext.position = new Vector(507, 262);
		pmNext.extent = new Vector(75, 60);
		pmNext.gamepadAccelerator = ["dpadRight"];
		pmNext.pressedAction = (sender) -> {
			setSelectedFunc(currentSelection + 1);
		}
		pmBox.addChild(pmNext);

		buttonHoldFunc = (dt:Float, mouseState:MouseState) -> {
			var prevBox = pmPrev.getRenderRectangle();
			var nextBox = pmNext.getRenderRectangle();

			if (prevBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					pmPrev.pressedAction(new GuiEvent(pmPrev));
					buttonCooldown = maxButtonCooldown;
					maxButtonCooldown *= 0.75;
				}
			}

			if (nextBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					pmNext.pressedAction(new GuiEvent(pmNext));
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

		var pmBack = new GuiButton(loadButtonImages("data/ui/play/back"));
		pmBack.position = new Vector(102, 260);
		pmBack.extent = new Vector(79, 61);
		pmBack.gamepadAccelerator = ["B"];
		pmBack.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new MainMenuGui());
		};
		pmBox.addChild(pmBack);

		var transparentbmp = new hxd.BitmapData(1, 1);
		transparentbmp.setPixel(0, 0, 0);
		var transparentTile = Tile.fromBitmap(transparentbmp);

		var skipButton = new GuiButton([transparentTile, transparentTile, transparentTile]);
		skipButton.horizSizing = Left;
		skipButton.vertSizing = Top;
		skipButton.position = new Vector(625, 465);
		skipButton.extent = new Vector(18, 19);
		skipButton.pressedAction = (sender) -> {
			var currentDifficulty = ["beginner", "intermediate", "advanced"].indexOf(currentCategory);
			if (currentDifficulty == -1)
				return;
			var currentProgression = Settings.progression[currentDifficulty];
			if (currentProgression + 1 == currentSelection) {
				Settings.progression[currentDifficulty]++;
			}
			setSelectedFunc(currentSelection);
		};
		this.addChild(skipButton);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual24":
					return domcasual24;
				case "Arial14":
					return arial14;
				case "ArialBold14":
					return arialBold14;
				default:
					return null;
			}
		}

		var goldBadge = ResourceLoader.getResource("data/ui/play/goldscore.png", ResourceLoader.getImage, this.imageResources).toTile();
		goldBadge.dy = 2.5 * Settings.uiScale;
		goldBadge.dx = 8 * Settings.uiScale;
		var gbWidth = goldBadge.width;
		var gbHeight = goldBadge.height;

		function imgLoader(path:String) {
			var t = switch (path) {
				case "pc":
					ResourceLoader.getResource("data/ui/play/platform_desktop.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "mac":
					ResourceLoader.getResource("data/ui/play/platform_mac.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "web":
					ResourceLoader.getResource("data/ui/play/platform_web.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "android":
					ResourceLoader.getResource("data/ui/play/platform_android.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					ResourceLoader.getResource("data/ui/play/platform_unknown.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "rewind":
					ResourceLoader.getResource("data/ui/play/rewind_ico_black.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "watch":
					ResourceLoader.getResource("data/ui/play/record.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "goldBadge.png":
					return goldBadge;
				case _:
					return null;
			};
			if (t != null)
				t.scaleToSize(t.width * (Settings.uiScale), t.height * (Settings.uiScale));
			return t;
		}

		var pmDescription = new GuiMLText(arial14, mlFontLoader);
		pmDescription.position = new Vector(61, 52);
		pmDescription.extent = new Vector(215, 174);
		pmDescription.text.textColor = 0x000000;
		pmDescription.text.lineHeightMode = TextOnly;
		pmDescription.text.loadImage = imgLoader;
		pmDescription.text.imageVerticalAlign = Middle;
		pmDescription.text.maxWidth = 215;

		goldBadge.scaleToSize((gbWidth / gbHeight) * arialBold14.lineHeight, arialBold14.lineHeight);
		// We're gonna use Â to align shit lmao, its too hacky i know
		var descText = '<font face="DomCasual24" color="#000000">Learn The Super Speed </font><br/><br/>' + 'ÂTest Align';
		descText += '<br/><br/><font face="DomCasual24">Best Times:</font><br/>';
		for (i in 0...3) {
			descText += '<br/>ÂÂ<font face="ArialBold14">${i + 1}. Nardo Polo</font>';
		}
		pmDescription.text.text = descText;
		pmBox.addChild(pmDescription);

		var scoreView:LeaderboardsKind = All;
		var showLBs = false;

		var infoButtonImages = loadButtonImages("data/ui/play/info", false);
		var leaderboardButtonImages = loadButtonImages("data/ui/play/leaderboards", false);

		var pmLeaderboards = new GuiButton(leaderboardButtonImages);
		pmLeaderboards.position = new Vector(181, 260);
		pmLeaderboards.extent = new Vector(64, 64);
		pmLeaderboards.gamepadAccelerator = [];
		pmLeaderboards.pressedAction = (sender) -> {
			showLBs = !showLBs;
			if (showLBs) {
				@:privateAccess pmLeaderboards.anim.frames = infoButtonImages;
			} else {
				@:privateAccess pmLeaderboards.anim.frames = leaderboardButtonImages;
			}
			setSelectedFunc(currentSelection);
		};
		pmBox.addChild(pmLeaderboards);

		var sortAlphaButtonImages = loadButtonImages("data/ui/play/sort_alpha", false);
		var sortTimeButtonImages = loadButtonImages("data/ui/play/sort_time", false);

		var pmSort = new GuiButton(sortTimeButtonImages);
		pmSort.position = new Vector(245, 260);
		pmSort.extent = new Vector(64, 64);
		pmSort.gamepadAccelerator = [];
		pmSort.pressedAction = (sender) -> {
			currentSortType = (currentSortType + 1) % 2;
			if (currentSortType == 0) {
				@:privateAccess pmSort.anim.frames = sortAlphaButtonImages;
			}
			if (currentSortType == 1) {
				@:privateAccess pmSort.anim.frames = sortTimeButtonImages;
			}
			setCategoryFunc(currentCategoryStatic, false);
			this.render(cast(this.parent, Canvas).scene2d);
		};

		if (currentSortType == 0) {
			@:privateAccess pmSort.anim.frames = sortAlphaButtonImages;
		}
		if (currentSortType == 1) {
			@:privateAccess pmSort.anim.frames = sortTimeButtonImages;
		}

		if (currentCategory == "custom") {
			pmSort.anim.visible = true;
			pmSort.disabled = false;
		} else {
			pmSort.anim.visible = false;
			pmSort.disabled = true;
		}

		pmBox.addChild(pmSort);

		pmDescription.text.onHyperlink = (url) -> {
			if (url == "watch") {
				var currentMission = currentList[currentSelection];
				var lbPath = currentMission.path;
				if (currentMission.isClaMission)
					lbPath = 'custom/${currentMission.id}';
				Leaderboards.watchTopReplay(lbPath, scoreView, (b) -> {
					if (b != null) {
						var replayF = new Replay("");
						if (replayF.read(b)) {
							var repmis = replayF.mission;
							// Strip data/ from the mission name
							if (StringTools.startsWith(repmis, "data/")) {
								repmis = repmis.substr(5);
							}

							// do the mapping

							if (!StringTools.startsWith(repmis, 'custom/')) {
								repmis = repmis.substr(repmis.indexOf('missions'));
								repmis = repmis.substr(repmis.indexOf('/') + 1);
								if (MissionMapping.mbpToMbg.exists(repmis))
									repmis = 'missions/' + MissionMapping.mbpToMbg.get(repmis);
							}

							var mi = replayF.customId == 0 ? MissionList.missions.get(repmis) : Marbleland.missions.get(replayF.customId);

							// try with data/ added
							if (mi == null && replayF.customId == 0) {
								if (!StringTools.contains(repmis, "data/"))
									repmis = "data/" + repmis;
								mi = MissionList.missions.get(repmis);
							}

							if (mi.isClaMission) {
								mi.download(() -> {
									MarbleGame.instance.watchMissionReplay(mi, replayF, PlayMissionGui);
								});
							} else {
								MarbleGame.instance.watchMissionReplay(mi, replayF, PlayMissionGui);
							}
						} else {
							MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Could not load replay for this level."));
						}
					} else {
						MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("No top replay found for this level."));
					}
				});
			}
			if (url == "changeScore") {
				scoreView = cast((cast(scoreView, Int) + 1) % 3);
				setSelectedFunc(currentSelection);
			}
		}

		var tabBeginner = new GuiImage(ResourceLoader.getResource("data/ui/play/tab_begin.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabBeginner.position = new Vector(29, 2);
		tabBeginner.extent = new Vector(184, 55);
		tabBeginner.pressedAction = (sender) -> {
			currentList = MissionList.beginnerMissions;
			setCategoryFunc("beginner");
		}
		localContainer.addChild(tabBeginner);

		currentList = MissionList.beginnerMissions;

		setCategoryFunc = function(category:String, ?doRender:Bool = true) {
			localContainer.removeChild(tabBeginner);
			localContainer.removeChild(tabIntermediate);
			localContainer.removeChild(tabAdvanced);
			localContainer.removeChild(tabCustom);
			localContainer.removeChild(pmBox);
			if (doRender)
				AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonpress.wav", ResourceLoader.getAudio, this.soundResources));

			pmSort.disabled = true;
			pmSort.anim.visible = false;

			if (category == "beginner") {
				localContainer.addChild(tabIntermediate);
				localContainer.addChild(tabAdvanced);
				localContainer.addChild(tabCustom);
				localContainer.addChild(pmBox);
				localContainer.addChild(tabBeginner);
				currentList = MissionList.beginnerMissions;
			}
			if (category == "intermediate") {
				localContainer.addChild(tabBeginner);
				localContainer.addChild(tabAdvanced);
				localContainer.addChild(tabCustom);
				localContainer.addChild(pmBox);
				localContainer.addChild(tabIntermediate);
				currentList = MissionList.intermediateMissions;
			}
			if (category == "advanced") {
				localContainer.addChild(tabBeginner);
				localContainer.addChild(tabIntermediate);
				localContainer.addChild(tabCustom);
				localContainer.addChild(pmBox);
				localContainer.addChild(tabAdvanced);
				currentList = MissionList.advancedMissions;
			}
			if (category == "custom") {
				localContainer.addChild(tabBeginner);
				localContainer.addChild(tabIntermediate);
				localContainer.addChild(tabAdvanced);
				localContainer.addChild(pmBox);
				localContainer.addChild(tabCustom);
				pmSort.disabled = false;
				pmSort.anim.visible = true;
				currentList = Marbleland.goldMissions;

				currentList = currentList.copy(); // Don't modify the originals
				if (currentSortType == 0) {
					currentList.sort((x, y) -> x.title > y.title ? 1 : (x.title < y.title ? -1 : 0));
				}
				if (currentSortType == 1) {
					currentList.sort((x, y) -> x.addedAt > y.addedAt ? 1 : (x.addedAt < y.addedAt ? -1 : 0));
				}
			}

			var lastCategory = currentCategory;

			currentCategoryStatic = currentCategory = category;
			if (lastCategory != currentCategory) {
				if (currentCategory != "custom")
					setSelectedFunc(cast Math.min(currentList.length - 1,
						Settings.progression[["beginner", "intermediate", "advanced"].indexOf(currentCategory)]));
				else
					setSelectedFunc(currentList.length - 1);
			} else {
				setSelectedFunc(currentSelection);
			}
			if (doRender)
				this.render(cast(this.parent, Canvas).scene2d);
		}

		function splitTextWithPadding(textElement:Text, textStr:String) {
			var maxWidth = textElement.maxWidth;
			textElement.maxWidth = null;
			var splits = [];
			var currentText = "Â";
			var textSplit = textStr.split(" ");
			for (i in 0...textSplit.length) {
				var prevText = currentText;
				currentText += textSplit[i];
				if (i != textSplit.length - 1)
					currentText += " ";
				textElement.text = currentText;
				if (textElement.textWidth > maxWidth) {
					splits.push(StringTools.trim(prevText));
					currentText = "Â" + textSplit[i];
					if (i != textSplit.length - 1)
						currentText += " ";
				}
			}
			textElement.maxWidth = maxWidth;
			splits.push(currentText);
			return splits.join('\n');
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
				pmPrev.disabled = true;
			} else
				pmPrev.disabled = false;
			if (index == Math.max(currentList.length - 1, 0)) {
				pmNext.disabled = true;
			} else
				pmNext.disabled = false;

			if (currentCategory != "custom"
				&& Settings.progression[["beginner", "intermediate", "advanced"].indexOf(currentCategory)] < currentSelection) {
				noQualText.text.visible = true;
				pmPreview.bmp.filter = filt;
				filt.matrix.identity();
				filt.matrix.colorGain(0, 96 / 255);
				pmPlay.disabled = true;
			} else {
				noQualText.text.visible = false;
				pmPreview.bmp.filter = null;
				filt.matrix.identity();
				pmPlay.disabled = false;
			}

			if (currentMission == null) {
				noQualText.text.visible = true;
				pmPreview.bmp.filter = filt;
				filt.matrix.identity();
				filt.matrix.colorGain(0, 96 / 255);
				pmPlay.disabled = true;
			}

			if (currentMission == null) {
				currentMission = new Mission();
				currentMission.title = "";
				currentMission.description = "";
				currentMission.path = "bruh";
				currentSelection = -1;
			}

			var scoreData:Array<Score> = Settings.getScores(currentMission.path);
			while (scoreData.length < 3) {
				scoreData.push({name: "Nardo Polo", time: 5999.999});
			}

			var descText = '<font face="DomCasual24" color="#000000">${currentMission.title}</font><br/><br/>';

			if (showLBs) {
				descText += '<font face="DomCasual24">Leaderboards:<br/></font>';
				descText += '<offset value="8">Loading</offset>';

				#if hl
				if (lbRequest != null)
					Http.cancel(lbRequest);
				#end
				#if js
				if (lbRequest != 0)
					Http.cancel(lbRequest);
				#end
				var lTok = lbToken++;
				var lbPath = currentMission.path;
				if (currentMission.isClaMission)
					lbPath = 'custom/${currentMission.id}';

				var req = Leaderboards.getScores(lbPath, scoreView, (scoreList) -> {
					if (lTok + 1 != lbToken || !showLBs)
						return;
					var sFmt = [];
					var i = 1;
					for (score in scoreList) {
						sFmt.push('<offset value="16"><font face="ArialBold14">${i}. ${StringTools.htmlEscape(score.name.substr(0, 12))}</font></offset>
						<offset value="128"><font face="ArialBold14">${Util.formatTime(score.score)}</font></offset>
						<offset value="185"><img src="${platformToString(score.platform)}" deltaY="-2" scale="0.9" /></offset>
						${score.rewind == 1 ? '<offset value="205"><img src="rewind" deltaY="-2" scale="0.9"  /></offset> ' : ""}');
						i++;
					}

					descText = '<font face="DomCasual24" color="#000000">${currentMission.title}</font><br/><br/>';
					descText += '<font face="DomCasual24">Leaderboards:';
					if (scoreList.length == 0) {
						descText += '<br/></font><offset value="8">No scores!</offset>';
					} else {
						descText += '<offset value="120">Top Replay:<a href="watch"><img src="watch" deltaY="-2" scale="0.9"/></a></offset><br/></font>';
						descText += sFmt.join('<br/>');
					}

					var kindList = ["All Scores", "Rewind Only", "No Rewind"];

					descText += '<br/><br/><font face="ArialBold14">Showing: <font color="#ff6060"><a href="changeScore">${kindList[cast(scoreView, Int)]}</a></font></font>';

					pmDescription.text.text = descText;

					// scoreBox.text.text = '<font color="#FDFEFE" face="MarkerFelt18">Leaderboards</font>
					// ${scoreList.length != 0 ? '<offset value="220">Top Replay:<a href="watch"><img src="watch" /></a></offset>' : ""}
					// <br/>'
					// 	+ sFmt.join('<br/>');
				});
				lbRequest = req;
			} else {
				descText += '<offset value="8">' + StringTools.htmlEscape(Util.unescape(currentMission.description)) + "</offset>";
				if (currentMission.qualifyTime != Math.POSITIVE_INFINITY) {
					descText += '<font face="DomCasual24"><br/>Time To Qualify: ${Util.formatTime(currentMission.qualifyTime)}</font>';
				}
				if (currentMission.qualifyTime != Math.POSITIVE_INFINITY) {
					descText += '<font face="DomCasual24" opacity="0"><br/>Time To Qualify: ${Util.formatTime(currentMission.qualifyTime)}</font>';
				} else {
					descText += '<br/>';
				}
				descText += '<br/><font face="DomCasual24">Best Times:</font><br/>';
				for (i in 0...3) {
					descText += '<br/><offset value="16"><font face="ArialBold14">${i + 1}. ${scoreData[i].name}</font></offset>';
					descText += '<offset value="128"><font face="ArialBold14">${Util.formatTime(scoreData[i].time)}</font>';
					if (scoreData[i].time < currentMission.goldTime) {
						descText += '<img src="goldBadge.png"></img>';
					}
					descText += "</offset>";
				}
			}
			pmDescription.text.text = descText;

			pmPreview.bmp.tile = tmpprevtile;
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

			levelBkgnd.text.text = currentCategory.charAt(0).toUpperCase() + currentCategory.substr(1) + ' Level ${currentSelection + 1}';

			levelFgnd.text.text = currentCategory.charAt(0).toUpperCase() + currentCategory.substr(1) + ' Level ${currentSelection + 1}';
		}

		setCategoryFunc(currentCategoryStatic, false);

		#if js
		var kofi = new GuiButton(loadButtonImages("data/ui/kofi1"));
		kofi.horizSizing = Left;
		kofi.vertSizing = Top;
		kofi.position = new Vector(473, 424);
		kofi.extent = new Vector(143, 36);
		kofi.pressedAction = (sender) -> {
			#if sys
			hxd.System.openURL("https://ko-fi.com/H2H5FRTTL");
			#end
			#if js
			js.Browser.window.open("https://ko-fi.com/H2H5FRTTL");
			#end
		}
		this.addChild(kofi);
		#end
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
}
