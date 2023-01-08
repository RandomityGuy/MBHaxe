package gui;

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

class PlayMissionGui extends GuiImage {
	static var currentSelectionStatic:Int = -1;
	static var currentCategoryStatic:String = "beginner";

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
	#end

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

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var tabAdvanced = new GuiImage(ResourceLoader.getResource("data/ui/play/tab_adv.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabAdvanced.position = new Vector(410, 21);
		tabAdvanced.extent = new Vector(166, 43);
		tabAdvanced.pressedAction = (sender) -> {
			currentList = MissionList.advancedMissions;
			currentCategory = "advanced";
			setCategoryFunc("advanced");
		}
		localContainer.addChild(tabAdvanced);

		var tabIntermediate = new GuiImage(ResourceLoader.getResource("data/ui/play/tab_inter.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabIntermediate.position = new Vector(213, 6);
		tabIntermediate.extent = new Vector(205, 58);
		tabIntermediate.pressedAction = (sender) -> {
			currentList = MissionList.intermediateMissions;
			currentCategory = "intermediate";
			setCategoryFunc("intermediate");
		}
		localContainer.addChild(tabIntermediate);

		var tabCustom = new GuiImage(ResourceLoader.getResource("data/ui/play/cust_tab.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabCustom.position = new Vector(589, 91);
		tabCustom.extent = new Vector(52, 198);
		tabCustom.pressedAction = (sender) -> {
			currentList = MissionList.customMissions;
			currentCategory = "custom";
			setCategoryFunc("custom");
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
		pmPreview.bmp.filter = filt;

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
						#if js
						repmis = StringTools.replace(repmis, "data/", "");
						#end
						var playMis = MissionList.missions.get(repmis);
						if (playMis != null) {
							cast(this.parent, Canvas).marbleGame.watchMissionReplay(playMis, replay);
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
		pmPrev.pressedAction = (sender) -> {
			setSelectedFunc(currentSelection - 1);
		}
		pmBox.addChild(pmPrev);

		var pmNext = new GuiButton(loadButtonImages("data/ui/play/next"));
		pmNext.position = new Vector(507, 262);
		pmNext.extent = new Vector(75, 60);
		pmNext.pressedAction = (sender) -> {
			setSelectedFunc(currentSelection + 1);
		}
		pmBox.addChild(pmNext);

		buttonHoldFunc = (dt:Float, mouseState:MouseState) -> {
			var prevBox = pmPrev.getRenderRectangle();
			var nextBox = pmNext.getRenderRectangle();

			if (prevBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					pmPrev.pressedAction(pmPrev);
					buttonCooldown = maxButtonCooldown;
					maxButtonCooldown *= 0.75;
				}
			}

			if (nextBox.inRect(mouseState.position) && mouseState.button == Key.MOUSE_LEFT) {
				if (buttonCooldown <= 0) {
					pmNext.pressedAction(pmNext);
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

		var pmDescription = new GuiMLText(arial14, mlFontLoader);
		pmDescription.position = new Vector(61, 52);
		pmDescription.extent = new Vector(215, 174);
		pmDescription.text.textColor = 0x000000;
		// We're gonna use Â to align shit lmao, its too hacky i know
		var descText = '<font face="DomCasual24" color="#000000">Learn The Super Speed </font><br/><br/>' + 'ÂTest Align';
		descText += '<br/><br/><font face="DomCasual24">Best Times:</font><br/>';
		for (i in 0...3) {
			descText += '<br/>ÂÂ<font face="ArialBold14">${i + 1}. Nardo Polo</font>';
		}
		pmDescription.text.text = descText;
		pmBox.addChild(pmDescription);

		// Oh god this is yet another hack cause I cant do that tab thing torque does so thats bruh
		var pmDescriptionOther = new GuiMLText(arial14, mlFontLoader);
		pmDescriptionOther.position = new Vector(61, 52);
		pmDescriptionOther.extent = new Vector(215, 174);
		pmDescriptionOther.text.textColor = 0x000000;
		var descText2 = '<br/><br/>' + '<font opacity="0">ÂTest Align</font>';
		descText2 += '<br/><br/><br/>';
		for (i in 0...3) {
			descText2 += '<br/>ÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂ<font face="ArialBold14">99:59.999</font>';
		}
		pmDescriptionOther.text.text = descText2;
		pmBox.addChild(pmDescriptionOther);

		var tabBeginner = new GuiImage(ResourceLoader.getResource("data/ui/play/tab_begin.png", ResourceLoader.getImage, this.imageResources).toTile());
		tabBeginner.position = new Vector(29, 2);
		tabBeginner.extent = new Vector(184, 55);
		tabBeginner.pressedAction = (sender) -> {
			currentList = MissionList.beginnerMissions;
			currentCategory = "beginner";
			setSelectedFunc(cast Math.min(Settings.progression[0], currentList.length - 1));
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
				currentList = MissionList.customMissions;
			}
			currentCategoryStatic = currentCategory;
			if (currentCategory != "custom")
				setSelectedFunc(cast Math.min(currentList.length - 1,
					Settings.progression[["beginner", "intermediate", "advanced"].indexOf(currentCategory)]));
			else
				setSelectedFunc(currentList.length - 1);
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

		var goldBadge = ResourceLoader.getResource("data/ui/play/goldscore.png", ResourceLoader.getImage, this.imageResources).toTile();
		goldBadge.dy = 2.5 * Settings.uiScale;
		goldBadge.dx = 8 * Settings.uiScale;
		var gbWidth = goldBadge.width;
		var gbHeight = goldBadge.height;

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
				filt.matrix.identity();
				filt.matrix.colorGain(0, 96 / 255);
				pmPlay.disabled = true;
			} else {
				noQualText.text.visible = false;
				filt.matrix.identity();
				pmPlay.disabled = false;
			}

			if (currentMission == null) {
				noQualText.text.visible = true;
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

			var descText = '<font face="DomCasual24" color="#000000">${currentMission.title}</font><br/><br/>'
				+ splitTextWithPadding(pmDescription.text, StringTools.htmlEscape(Util.unescape(currentMission.description)));
			if (currentMission.qualifyTime != Math.POSITIVE_INFINITY) {
				descText += '<font face="DomCasual24"><br/>Time To Qualify: ${Util.formatTime(currentMission.qualifyTime)}</font>';
			}
			descText += '<br/><br/><font face="DomCasual24">Best Times:</font><br/>';
			for (i in 0...3) {
				descText += '<br/>ÂÂ<font face="ArialBold14">${i + 1}. ${scoreData[i].name}</font>';
			}
			pmDescription.text.text = descText;

			var descText2 = '<br/><br/>'
				+
				'<font opacity="0">${splitTextWithPadding(pmDescriptionOther.text, StringTools.htmlEscape(Util.unescape(currentMission.description)))}</font>';
			descText2 += '<br/><br/>';
			if (currentMission.qualifyTime != Math.POSITIVE_INFINITY) {
				descText2 += '<font face="DomCasual24" opacity="0"><br/>Time To Qualify: ${Util.formatTime(currentMission.qualifyTime)}</font>';
			}
			descText2 += '<br/>';
			for (i in 0...3) {
				descText2 += '<br/>ÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂÂ<font face="ArialBold14">${Util.formatTime(scoreData[i].time)}</font>';
				if (scoreData[i].time < currentMission.goldTime) {
					descText2 += '<img src="goldBadge.png"></img>';
				}
			}
			pmDescriptionOther.text.lineHeightMode = TextOnly;
			pmDescriptionOther.text.text = descText2;
			pmDescriptionOther.text.loadImage = (name) -> goldBadge;
			goldBadge.scaleToSize((gbWidth / gbHeight) * arialBold14.lineHeight, arialBold14.lineHeight);
			pmDescription.text.lineSpacing = pmDescriptionOther.text.lineSpacing;

			#if android
			pmPreview.bmp.tile = currentMission.getPreviewImageSync();
			#else
			pmPreview.bmp.tile = tmpprevtile;
			#end
			#if js
			switch (previewTimeoutHandle) {
				case None:
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						currentMission.getPreviewImage(prevImg -> {
							pmPreview.bmp.tile = prevImg;
						});
					}, 75));
				case Some(previewTimeoutHandle_id):
					js.Browser.window.clearTimeout(previewTimeoutHandle_id);
					previewTimeoutHandle = Some(js.Browser.window.setTimeout(() -> {
						currentMission.getPreviewImage(prevImg -> {
							pmPreview.bmp.tile = prevImg;
						});
					}, 75));
			}
			#end
			#if (hl && !android)
			currentMission.getPreviewImage(prevImg -> {
				pmPreview.bmp.tile = prevImg;
			}); // Shit be sync
			#end

			levelBkgnd.text.text = currentCategory.charAt(0).toUpperCase() + currentCategory.substr(1) + ' Level ${currentSelection + 1}';

			levelFgnd.text.text = currentCategory.charAt(0).toUpperCase() + currentCategory.substr(1) + ' Level ${currentSelection + 1}';
		}

		setCategoryFunc(currentCategoryStatic, false);
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);
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
}
