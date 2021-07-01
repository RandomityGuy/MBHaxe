package gui;

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
	var currentSelection:Int = 0;
	var currentCategory:String = "beginner";
	var currentList:Array<Mission>;

	var setSelectedFunc:Int->Void;

	public function new() {
		super(ResourceLoader.getImage("data/ui/background.jpg").toTile());

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.extent = new Vector(640, 480);
		this.position = new Vector(0, 0);

		MissionList.buildMissionList();

		var localContainer = new GuiControl();
		localContainer.horizSizing = Center;
		localContainer.vertSizing = Center;
		localContainer.position = new Vector(-1, 44);
		localContainer.extent = new Vector(651, 392);
		this.addChild(localContainer);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getImage('${path}_n.png').toTile();
			var hover = ResourceLoader.getImage('${path}_h.png').toTile();
			var pressed = ResourceLoader.getImage('${path}_d.png').toTile();
			var disabled = ResourceLoader.getImage('${path}_i.png').toTile();
			return [normal, hover, pressed, disabled];
		}

		var setCategoryFunc:String->Void = null;

		var tabAdvanced = new GuiImage(ResourceLoader.getImage("data/ui/play/tab_adv.png").toTile());
		tabAdvanced.position = new Vector(410, 21);
		tabAdvanced.extent = new Vector(166, 43);
		tabAdvanced.pressedAction = (sender) -> {
			currentList = MissionList.advancedMissions;
			currentCategory = "advanced";
			setSelectedFunc(0);
			setCategoryFunc("advanced");
		}
		localContainer.addChild(tabAdvanced);

		var tabIntermediate = new GuiImage(ResourceLoader.getImage("data/ui/play/tab_inter.png").toTile());
		tabIntermediate.position = new Vector(213, 4);
		tabIntermediate.extent = new Vector(205, 58);
		tabIntermediate.pressedAction = (sender) -> {
			currentList = MissionList.intermediateMissions;
			currentCategory = "intermediate";
			setSelectedFunc(0);
			setCategoryFunc("intermediate");
		}
		localContainer.addChild(tabIntermediate);

		var tabCustom = new GuiImage(ResourceLoader.getImage("data/ui/play/cust_tab.png").toTile());
		tabCustom.position = new Vector(589, 91);
		tabCustom.extent = new Vector(52, 198);
		localContainer.addChild(tabCustom);

		var pmBox = new GuiImage(ResourceLoader.getImage("data/ui/play/playgui.png").toTile());
		pmBox.position = new Vector(0, 42);
		pmBox.extent = new Vector(610, 351);
		pmBox.horizSizing = Width;
		pmBox.vertSizing = Height;
		localContainer.addChild(pmBox);

		var textWnd = new GuiImage(ResourceLoader.getImage("data/ui/play/text_window.png").toTile());
		textWnd.horizSizing = Width;
		textWnd.vertSizing = Height;
		textWnd.position = new Vector(31, 29);
		textWnd.extent = new Vector(276, 229);
		pmBox.addChild(textWnd);

		var pmPreview = new GuiImage(ResourceLoader.getImage("data/missions/beginner/superspeed.jpg").toTile());
		pmPreview.position = new Vector(312, 42);
		pmPreview.extent = new Vector(258, 193);
		pmBox.addChild(pmPreview);

		var levelWnd = new GuiImage(ResourceLoader.getImage("data/ui/play/level_window.png").toTile());
		levelWnd.position = new Vector();
		levelWnd.extent = new Vector(258, 194);
		pmPreview.addChild(levelWnd);

		var domcasual24fontdata = ResourceLoader.loader.load("data/font/DomCasual24px.fnt");
		var domcasual24 = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24.loader = ResourceLoader.loader;

		var domcasual32fontdata = ResourceLoader.loader.load("data/font/DomCasual24px.fnt");
		var domcasual32 = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32.loader = ResourceLoader.loader;

		var arial14fontdata = ResourceLoader.loader.load("data/font/Arial14.fnt");
		var arial14 = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14.loader = ResourceLoader.loader;

		var arialBold14fontdata = ResourceLoader.loader.load("data/font/ArialBold14px.fnt");
		var arialBold14 = new BitmapFont(arialBold14fontdata.entry);
		@:privateAccess arialBold14.loader = ResourceLoader.loader;

		// TODO texts
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
		noQualText.text.text = "Not qualified!";
		levelWnd.addChild(noQualText);

		var pmPlay = new GuiButton(loadButtonImages("data/ui/play/play"));
		pmPlay.position = new Vector(391, 257);
		pmPlay.extent = new Vector(121, 62);
		pmPlay.pressedAction = (sender) -> {
			// Wacky hacks
			currentList[currentSelection].index = currentSelection;
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

		var pmBack = new GuiButton(loadButtonImages("data/ui/play/back"));
		pmBack.position = new Vector(102, 260);
		pmBack.extent = new Vector(79, 61);
		pmBack.pressedAction = (sender) -> {
			cast(this.parent, Canvas).setContent(new MainMenuGui());
		};
		pmBox.addChild(pmBack);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual24":
					return domcasual32.toFont();
				case "Arial14":
					return arial14.toFont();
				case "ArialBold14":
					return arialBold14.toFont();
				default:
					return null;
			}
		}

		// TODO Pm description
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

		var tabBeginner = new GuiImage(ResourceLoader.getImage("data/ui/play/tab_begin.png").toTile());
		tabBeginner.position = new Vector(29, 2);
		tabBeginner.extent = new Vector(184, 55);
		tabBeginner.pressedAction = (sender) -> {
			currentList = MissionList.beginnerMissions;
			currentCategory = "beginner";
			setSelectedFunc(0);
			setCategoryFunc("beginner");
		}
		localContainer.addChild(tabBeginner);

		currentList = MissionList.beginnerMissions;

		setCategoryFunc = function(category:String) {
			localContainer.removeChild(tabBeginner);
			localContainer.removeChild(tabIntermediate);
			localContainer.removeChild(tabAdvanced);
			localContainer.removeChild(tabCustom);
			localContainer.removeChild(pmBox);
			AudioManager.playSound(ResourceLoader.getAudio("data/sound/buttonpress.wav"));
			if (category == "beginner") {
				localContainer.addChild(tabIntermediate);
				localContainer.addChild(tabAdvanced);
				localContainer.addChild(tabCustom);
				localContainer.addChild(pmBox);
				localContainer.addChild(tabBeginner);
			}
			if (category == "intermediate") {
				localContainer.addChild(tabBeginner);
				localContainer.addChild(tabAdvanced);
				localContainer.addChild(tabCustom);
				localContainer.addChild(pmBox);
				localContainer.addChild(tabIntermediate);
			}
			if (category == "advanced") {
				localContainer.addChild(tabBeginner);
				localContainer.addChild(tabIntermediate);
				localContainer.addChild(tabCustom);
				localContainer.addChild(pmBox);
				localContainer.addChild(tabAdvanced);
			}
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

		var goldBadge = ResourceLoader.getImage("data/ui/play/goldscore.png").toTile();
		goldBadge.dy = 2.5;
		goldBadge.dx = 8;

		setSelectedFunc = function setSelected(index:Int) {
			if (index > currentList.length - 1) {
				index = currentList.length - 1;
			}
			if (index < 0) {
				index = 0;
			}

			currentSelection = index;

			if (index == 0) {
				pmPrev.disabled = true;
			} else
				pmPrev.disabled = false;
			if (index == currentList.length - 1) {
				pmNext.disabled = true;
			} else
				pmNext.disabled = false;

			var currentMission = currentList[currentSelection];

			var scoreData:Array<Score> = Settings.getScores(currentMission.path);
			while (scoreData.length < 3) {
				scoreData.push({name: "Nardo Polo", time: 5999.999});
			}

			var descText = '<font face="DomCasual24" color="#000000">${currentMission.title}</font><br/><br/>'
				+ splitTextWithPadding(pmDescription.text, Util.unescape(currentMission.description));
			if (currentMission.qualifyTime != Math.POSITIVE_INFINITY) {
				descText += '<font face="DomCasual24"><br/>Time To Qualify: ${Util.formatTime(currentMission.qualifyTime)}</font>';
			}
			descText += '<br/><br/><font face="DomCasual24">Best Times:</font><br/>';
			for (i in 0...3) {
				descText += '<br/>ÂÂ<font face="ArialBold14">${i + 1}. ${scoreData[i].name}</font>';
			}
			pmDescription.text.text = descText;

			var descText2 = '<br/><br/>'
				+ '<font opacity="0">${splitTextWithPadding(pmDescriptionOther.text, Util.unescape(currentMission.description))}</font>';
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
			pmDescriptionOther.text.text = descText2;
			pmDescriptionOther.text.loadImage = (name) -> goldBadge;

			pmPreview.bmp.tile = currentMission.getPreviewImage();

			levelBkgnd.text.text = currentCategory.charAt(0).toUpperCase() + currentCategory.substr(1) + ' Level ${currentSelection + 1}';
			levelFgnd.text.text = currentCategory.charAt(0).toUpperCase() + currentCategory.substr(1) + ' Level ${currentSelection + 1}';

			noQualText.text.visible = false;
		}
	}

	public override function render(scene2d:Scene) {
		super.render(scene2d);
		setSelectedFunc(0);
	}
}
