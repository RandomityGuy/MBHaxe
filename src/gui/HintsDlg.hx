package gui;

import src.Mission;
import src.Http;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.Util;
import src.Marbleland;

class HintsDlg extends GuiControl {
	public function new(mission:Mission) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(800, 600);

		var ctrl = new GuiControl();
		ctrl.horizSizing = Center;
		ctrl.vertSizing = Center;
		ctrl.position = new Vector(0, 0);
		ctrl.extent = new Vector(640, 480);
		this.addChild(ctrl);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(56, 15);
		wnd.extent = new Vector(527, 450);
		ctrl.addChild(wnd);

		var hintIcon = new GuiImage(ResourceLoader.getResource("data/ui/loading/loading_helpbubble.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		hintIcon.position = new Vector(453, -12);
		hintIcon.extent = new Vector(118, 118);
		wnd.addChild(hintIcon);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont17 = whatneyFontB.toSdfFont(cast 15 * Settings.uiScale, MultiChannel);
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		var squatneyFontData = ResourceLoader.getFileEntry("data/font/squatney.fnt");
		var squatneyFontB = new BitmapFont(squatneyFontData.entry);
		@:privateAccess squatneyFontB.loader = ResourceLoader.loader;
		var squatneyFont24 = squatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		var hintsTitle = new GuiText(squishneyFont28);
		hintsTitle.text.textColor = 0x000000;
		hintsTitle.text.text = mission.title + ":";
		hintsTitle.position = new Vector(29, 39);
		hintsTitle.extent = new Vector(428, 32);
		wnd.addChild(hintsTitle);

		var closeButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		closeButton.position = new Vector(273, 393);
		closeButton.setExtent(new Vector(94, 45));
		closeButton.vertSizing = Bottom;
		closeButton.horizSizing = Right;
		closeButton.pressedAction = (sender) -> {
			MarbleGame.canvas.popDialog(this);
		}
		closeButton.txtCtrl.text.text = "Close";
		wnd.addChild(closeButton);

		var scroll = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/pqscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				top: new Vector(0, 39, 16, 7),
				bottom: new Vector(0, 56, 16, 7),
				fill: new Vector(0, 47, 16, 1),
				topPressed: new Vector(19, 39, 16, 7),
				bottomPressed: new Vector(19, 56, 16, 7),
				fillPressed: new Vector(19, 47, 16, 1),
				track: new Vector(0, 65, 16, 7),
				up: new Vector(0, 1, 16, 16),
				down: new Vector(0, 20, 16, 16),
				upPressed: new Vector(19, 1, 16, 16),
				downPressed: new Vector(19, 20, 16, 16),
				upDisabled: new Vector(38, 1, 16, 16),
				downDisabled: new Vector(38, 20, 16, 16)
			});
		scroll.position = new Vector(29, 72);
		scroll.extent = new Vector(481, 319);
		// scroll.childrenHandleScroll = true;
		wnd.addChild(scroll);

		function mlFontLoader(text:String) {
			switch (text) {
				case "title":
					return squishneyFont28;
				case "text":
					return whatneyFont17;
				case "condensed":
					return squatneyFont24;
				default:
					return null;
			}
		}

		var hintsContent = new GuiMLText(whatneyFont17, mlFontLoader);
		hintsContent.position = new Vector(0, 0);
		hintsContent.extent = new Vector(466, 328);
		hintsContent.text.textColor = 0;
		hintsContent.scrollable = true;
		hintsContent.text.lineSpacing = 4;
		hintsContent.text.text = "Loading hints, please wait.<br/>";

		var scores = Settings.getScores(mission.path);
		var progression = {
			beatPar: false,
			beatPlatinum: false,
			beatUltimate: false,
			beatAwesome: false
		};
		if (scores.length != 0)
			progression = mission.calculateProgression(scores[0].time, scores[0].type == 0 ? Time : Score);

		var hintText = "";

		if (mission.missionInfo == null) {
			if (mission.isClaMission) {
				hintText = 'Loading hints, please wait.<br/>';
				Marbleland.getMissionInfo(mission.id, (minfo) -> {
					if (minfo != null) {
						if (isNullOrEmpty(minfo.generalhint) && isNullOrEmpty(minfo.trivia) && isNullOrEmpty(minfo.ultimatehint)
							&& isNullOrEmpty(minfo.awesomehint) && isNullOrEmpty(minfo.egghint) && isNullOrEmpty(minfo.easteregghint)) {
							hintText = 'No information or hints exist for ${StringTools.htmlEscape(mission.title)}.';
						} else {
							hintText = "";
							if (!isNullOrEmpty(minfo.generalhint))
								hintText += '<font face="condensed">Hints:<br/></font>${StringTools.htmlEscape(Util.formatMLText(minfo.generalhint))}<br/>';

							if (progression.beatPlatinum && !isNullOrEmpty(minfo.ultimatehint))
								hintText += '<font face="condensed">Ultimate Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(minfo.ultimatehint))}<br/>';
							if (progression.beatUltimate && !isNullOrEmpty(minfo.awesomehint))
								hintText += '<font face="condensed">Awesome Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(minfo.awesomehint))}<br/>';
							if (mission.hasEgg && !isNullOrEmpty(minfo.egghint))
								hintText += '<font face="condensed">Egg Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(minfo.egghint))}<br/>';
							if (mission.hasEgg && !isNullOrEmpty(minfo.easteregghint))
								hintText += '<font face="condensed">Easter Egg Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(minfo.easteregghint))}<br/>';

							if (!isNullOrEmpty(minfo.trivia))
								hintText += '<font face="condensed">Trivia:<br/></font>${StringTools.htmlEscape(Util.formatMLText(minfo.trivia))}<br/>';
						}
					} else {
						hintText = 'Failed to load hints for ${StringTools.htmlEscape(mission.title)}.';
					}

					hintsContent.text.text = hintText;
					scroll.setScrollMax(hintsContent.text.textHeight);
					scroll.setScrollPercentage(0);
				});
			} else {
				hintText = 'No information or hints exist for ${StringTools.htmlEscape(mission.title)}.';
			}
		} else {
			if (isNullOrEmpty(mission.missionInfo.generalhint)
				&& isNullOrEmpty(mission.missionInfo.trivia)
				&& isNullOrEmpty(mission.missionInfo.ultimatehint)
				&& isNullOrEmpty(mission.missionInfo.awesomehint)
				&& isNullOrEmpty(mission.missionInfo.egghint)
				&& isNullOrEmpty(mission.missionInfo.easteregghint)) {
				hintText = 'No information or hints exist for ${StringTools.htmlEscape(mission.title)}.';
			} else {
				if (!isNullOrEmpty(mission.missionInfo.generalhint))
					hintText += '<font face="condensed">Hints:<br/></font>${StringTools.htmlEscape(Util.formatMLText(mission.missionInfo.generalhint))}<br/>';

				if (progression.beatPlatinum && !isNullOrEmpty(mission.missionInfo.ultimatehint))
					hintText += '<font face="condensed">Ultimate Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(mission.missionInfo.ultimatehint))}<br/>';
				if (progression.beatUltimate && !isNullOrEmpty(mission.missionInfo.awesomehint))
					hintText += '<font face="condensed">Awesome Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(mission.missionInfo.awesomehint))}<br/>';
				if (mission.hasEgg && !isNullOrEmpty(mission.missionInfo.egghint))
					hintText += '<font face="condensed">Egg Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(mission.missionInfo.egghint))}<br/>';
				if (mission.hasEgg && !isNullOrEmpty(mission.missionInfo.easteregghint))
					hintText += '<font face="condensed">Easter Egg Hint:<br/></font>${StringTools.htmlEscape(Util.formatMLText(mission.missionInfo.easteregghint))}<br/>';

				if (!isNullOrEmpty(mission.missionInfo.trivia))
					hintText += '<font face="condensed">Trivia:<br/></font>${StringTools.htmlEscape(Util.formatMLText(mission.missionInfo.trivia))}<br/>';
			}
		}

		hintsContent.text.text = hintText;
		scroll.addChild(hintsContent);
		scroll.setScrollMax(hintsContent.text.textHeight);
		scroll.setScrollPercentage(0);
	}

	function isNullOrEmpty(s:String):Bool {
		return s == null || s == "";
	}
}
