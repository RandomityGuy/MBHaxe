package gui;

import hxd.BitmapData;
import h2d.Tile;
import src.MarbleGame;
import src.Settings.Score;
import src.Settings.Settings;
import src.Mission;
import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.TimeState;
import src.Util;

class EndGameGui extends GuiControl {
	var mission:Mission;

	var scoreSubmitted:Bool = false;

	public function new(continueFunc:GuiControl->Void, restartFunc:GuiControl->Void, mission:Mission, timeState:TimeState) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(640, 480);
		this.mission = mission;

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var pg = new GuiImage(ResourceLoader.getResource("data/ui/endgame/base.png", ResourceLoader.getImage, this.imageResources).toTile());
		pg.horizSizing = Center;
		pg.vertSizing = Center;
		pg.position = new Vector(28, 20);
		pg.extent = new Vector(584, 440);

		var continueButton = new GuiButton(loadButtonImages("data/ui/endgame/continue"));
		continueButton.horizSizing = Right;
		continueButton.vertSizing = Bottom;
		continueButton.position = new Vector(460, 307);
		continueButton.extent = new Vector(104, 54);
		continueButton.pressedAction = (e) -> continueFunc(continueButton);

		var restartButton = new GuiButton(loadButtonImages("data/ui/endgame/replay"));
		restartButton.horizSizing = Right;
		restartButton.vertSizing = Bottom;
		restartButton.position = new Vector(460, 363);
		restartButton.extent = new Vector(104, 54);
		restartButton.pressedAction = (e) -> restartFunc(restartButton);

		var nextLevel = new GuiControl();
		nextLevel.position = new Vector(326, 307);
		nextLevel.extent = new Vector(130, 110);

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = Tile.fromBitmap(temprev);

		var nextLevelPreview = new GuiImage(tmpprevtile);
		nextLevelPreview.position = new Vector(-15, 0);
		nextLevelPreview.extent = new Vector(160, 110);
		nextLevel.addChild(nextLevelPreview);

		mission.getNextMission().getPreviewImage(t -> {
			nextLevelPreview.bmp.tile = t;
		});

		var nextLevelBtn = new GuiButton(loadButtonImages('data/ui/endgame/level_window'));
		nextLevelBtn.horizSizing = Width;
		nextLevelBtn.vertSizing = Height;
		nextLevelBtn.position = new Vector(0, 0);
		nextLevelBtn.extent = new Vector(130, 110);
		nextLevelBtn.pressedAction = (e) -> {
			var nextMission = mission.getNextMission();
			if (nextMission != null) {
				cast(this.parent, Canvas).marbleGame.playMission(nextMission);
			}
		};
		nextLevel.addChild(nextLevelBtn);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);
		var domcasual64 = domcasual32b.toSdfFont(cast 58 * Settings.uiScale, MultiChannel);
		var domcasual24 = domcasual32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		var expo50fontdata = ResourceLoader.getFileEntry("data/font/EXPON.fnt");
		var expo50b = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50b.loader = ResourceLoader.loader;
		var expo50 = expo50b.toSdfFont(cast 35 * Settings.uiScale, MultiChannel);
		var expo32 = expo50b.toSdfFont(cast 24 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual24":
					return domcasual24;
				case "DomCasual32":
					return domcasual32;
				case "DomCasual64":
					return domcasual64;
				case "Arial14":
					return arial14;
				case "Expo32":
					return expo32;
				default:
					return null;
			}
		}

		var egResult = new GuiMLText(domcasual32, mlFontLoader);
		egResult.position = new Vector(313, 54);
		egResult.extent = new Vector(244, 69);
		egResult.text.text = '<font face="DomCasual64" color="#FFFFFF"><p align="right">${Util.formatTime(timeState.gameplayClock)}</p></font>';
		egResult.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0, 0.4, 1, true);
		pg.addChild(egResult);

		var egFirstLine = new GuiMLText(domcasual24, mlFontLoader);
		egFirstLine.position = new Vector(340, 150);
		egFirstLine.extent = new Vector(210, 25);
		egFirstLine.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egFirstLine);

		var egSecondLine = new GuiMLText(domcasual24, mlFontLoader);
		egSecondLine.position = new Vector(341, 178);
		egSecondLine.extent = new Vector(209, 25);
		egSecondLine.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egSecondLine);

		var egThirdLine = new GuiMLText(domcasual24, mlFontLoader);
		egThirdLine.position = new Vector(341, 206);
		egThirdLine.extent = new Vector(209, 25);
		egThirdLine.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egThirdLine);

		var egFourthLine = new GuiMLText(domcasual24, mlFontLoader);
		egFourthLine.position = new Vector(341, 234);
		egFourthLine.extent = new Vector(209, 25);
		egFourthLine.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egFourthLine);

		var egFifthLine = new GuiMLText(domcasual24, mlFontLoader);
		egFifthLine.position = new Vector(341, 262);
		egFifthLine.extent = new Vector(209, 25);
		egFifthLine.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egFifthLine);

		var egFirstLineScore = new GuiMLText(domcasual24, mlFontLoader);
		egFirstLineScore.position = new Vector(475, 150);
		egFirstLineScore.extent = new Vector(210, 25);
		egFirstLineScore.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egFirstLineScore);

		var egSecondLineScore = new GuiMLText(domcasual24, mlFontLoader);
		egSecondLineScore.position = new Vector(476, 178);
		egSecondLineScore.extent = new Vector(209, 25);
		egSecondLineScore.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egSecondLineScore);

		var egThirdLineScore = new GuiMLText(domcasual24, mlFontLoader);
		egThirdLineScore.position = new Vector(476, 206);
		egThirdLineScore.extent = new Vector(209, 25);
		egThirdLineScore.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egThirdLineScore);

		var egFourthLineScore = new GuiMLText(domcasual24, mlFontLoader);
		egFourthLineScore.position = new Vector(476, 234);
		egFourthLineScore.extent = new Vector(209, 25);
		egFourthLineScore.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egFourthLineScore);

		var egFifthLineScore = new GuiMLText(domcasual24, mlFontLoader);
		egFifthLineScore.position = new Vector(476, 262);
		egFifthLineScore.extent = new Vector(209, 25);
		egFifthLineScore.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		pg.addChild(egFifthLineScore);

		var egTitleText = new GuiMLText(expo50, mlFontLoader);
		egTitleText.text.textColor = 0xffff00;
		egTitleText.text.text = '<font color="#FFFFFF" face="DomCasual64">Your Time:</font>';
		egTitleText.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0, 0.4, 1, true);
		egTitleText.position = new Vector(34, 54);
		egTitleText.extent = new Vector(247, 69);
		pg.addChild(egTitleText);

		var egTopThreeText = new GuiMLText(domcasual32, mlFontLoader);
		egTopThreeText.position = new Vector(341, 114);
		egTopThreeText.extent = new Vector(209, 34);
		egTopThreeText.text.text = '<font face="DomCasual32" color="#FFFFFF">Top 5 Times:</font>'; // Make toggleable 3-5
		egTopThreeText.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0, 0.4, 1, true);
		pg.addChild(egTopThreeText);

		var text = '<font color="#FFFFFF" face="DomCasual32"><p align="center">';
		// Check for ultimate time TODO
		if (mission.ultimateTime > 0 && timeState.gameplayClock < mission.ultimateTime) {
			text += 'You beat the <font color="#FFDD22">Ultimate</font> Time!';
		} else {
			if (mission.goldTime > 0 && timeState.gameplayClock < mission.goldTime) {
				if (mission.game == "gold" || mission.game.toLowerCase() == "ultra")
					text += 'You beat the <font color="#FFCC00">Gold</font> Time!';
				else
					text += 'You beat the <font color="#CCCCCC">Platinum</font> Time!';
			} else {
				if (mission.qualifyTime > timeState.gameplayClock) {
					text += "You beat the Par Time!";
				} else {
					text += '<font color="#F55555">You didn\'nt pass the Par Time!</font>';
				}
			}
		}
		text += '</p></font>';

		var finishMessage = new GuiMLText(expo32, mlFontLoader);
		finishMessage.text.textColor = 0x00ff00;
		finishMessage.text.text = text;
		finishMessage.text.filter = new DropShadow(1, 0.785, 0, 1, 0, 0.4, 1, true);
		// finishMessage.justify = Center;
		finishMessage.position = new Vector(25, 120);
		finishMessage.extent = new Vector(293, 211);
		pg.addChild(finishMessage);

		var qualified = mission.qualifyTime > timeState.gameplayClock;

		var scoreData:Array<Score> = Settings.getScores(mission.path);
		while (scoreData.length < 5) {
			scoreData.push({name: "Matan W.", time: 5999.999});
		}

		egFirstLine.text.text = '<p align="left"><font color="#EEC884">1. </font>${scoreData[0].name}</p>';
		egSecondLine.text.text = '<p align="left"><font color="#CDCDCD">2. </font>${scoreData[1].name}</p>';
		egThirdLine.text.text = '<p align="left"><font color="#C9AFA0">3. </font>${scoreData[2].name}</p>';
		egFourthLine.text.text = '<p align="left"><font color="#A4A4A4">4. </font>${scoreData[3].name}</p>';
		egFifthLine.text.text = '<p align="left"><font color="#949494">5. </font>${scoreData[4].name}</p>';

		var lineelems = [
			egFirstLineScore,
			egSecondLineScore,
			egThirdLineScore,
			egFourthLineScore,
			egFifthLineScore
		];

		for (i in 0...5) {
			if (scoreData[i].time < mission.ultimateTime) {
				lineelems[i].text.text = '<font color="#FFDD22">${Util.formatTime(scoreData[i].time)}</font>';
			} else {
				if (scoreData[i].time < mission.goldTime) {
					if (mission.game == "gold" || mission.game.toLowerCase() == "ultra")
						lineelems[i].text.text = '<font color="#FFCC00">${Util.formatTime(scoreData[i].time)}</font>';
					else
						lineelems[i].text.text = '<font color="#CCCCCC">${Util.formatTime(scoreData[i].time)}</font>';
				} else {
					lineelems[i].text.text = '${Util.formatTime(scoreData[i].time)}';
				}
			}
		}

		var leftColumn = new GuiMLText(domcasual24, mlFontLoader);
		leftColumn.text.lineSpacing = 5;
		leftColumn.text.textColor = 0xFFFFFF;
		leftColumn.text.text = 'Par Time:<br/>${mission.game == "gold" || mission.game.toLowerCase() == "ultra" ? '<font color="#FFCC00">Gold Time:</font>' : '<font color="#CCCCCC">Platinum Time:</font>'}<br/>${mission.ultimateTime != 0 ? '<font color="#FFDD22">Ultimate Time:</font><br/>' : ''}<font face="Arial14"><br/></font><font color="#FFFFFF" face="DomCasual24">Time Passed:<br/>Clock Bonuses:</font>';
		leftColumn.text.filter = new DropShadow(1.414, 0.785, 0x7777777F, 1, 0, 0.4, 1, true);
		leftColumn.position = new Vector(25, 165);
		leftColumn.extent = new Vector(293, 211);
		pg.addChild(leftColumn);

		var elapsedTime = Math.max(timeState.currentAttemptTime - 3.5, 0);
		var bonusTime = Math.max(0, elapsedTime - timeState.gameplayClock);

		var rightColumn = new GuiMLText(domcasual24, mlFontLoader);
		rightColumn.text.lineSpacing = 5;
		rightColumn.text.textColor = 0xFFFFFF;
		rightColumn.text.text = '${Util.formatTime(mission.qualifyTime == Math.POSITIVE_INFINITY ? 5999.999 : mission.qualifyTime)}<br/><font color="${mission.game == "gold" || mission.game.toLowerCase() == "ultra" ? '#FFCC00' : '#CCCCCC'}">${Util.formatTime(mission.goldTime)}</font><br/>${mission.ultimateTime != 0 ? '<font color="#FFDD22">${Util.formatTime(mission.ultimateTime)}</font><br/>' : ''}<font face="Arial14"><br/></font><font color="#FFFFFF" face="DomCasual24">${Util.formatTime(elapsedTime)}<br/>${Util.formatTime(bonusTime)}</font>';
		rightColumn.text.filter = new DropShadow(1.414, 0.785, 0xffffff, 1, 0, 0.4, 1, true);
		rightColumn.position = new Vector(235, 165);
		rightColumn.extent = new Vector(293, 211);
		pg.addChild(rightColumn);

		pg.addChild(continueButton);
		pg.addChild(restartButton);
		pg.addChild(nextLevel);
		pg.addChild(egFirstLine);
		pg.addChild(egSecondLine);
		pg.addChild(egThirdLine);
		pg.addChild(egFourthLine);
		pg.addChild(egFifthLine);

		this.addChild(pg);

		var scoreTimes = scoreData.map(x -> x.time).concat([timeState.gameplayClock]);
		scoreTimes.sort((a, b) -> a == b ? 0 : (a > b ? 1 : -1));

		var idx = scoreTimes.indexOf(timeState.gameplayClock);

		// if (Settings.progression[mission.difficultyIndex] == mission.index && qualified) {
		// 	Settings.progression[mission.difficultyIndex]++;
		// }
		Settings.save();

		if (idx <= 4) {
			var end = new EnterNameDlg(idx, (name) -> {
				if (scoreSubmitted)
					return;

				var myScore = {name: name, time: timeState.gameplayClock};
				scoreData.push(myScore);
				scoreData.sort((a, b) -> a.time == b.time ? 0 : (a.time > b.time ? 1 : -1));

				egFirstLine.text.text = '<p align="left"><font color="#EEC884">1. </font>${scoreData[0].name}</p>';
				egSecondLine.text.text = '<p align="left"><font color="#CDCDCD">2. </font>${scoreData[1].name}</p>';
				egThirdLine.text.text = '<p align="left"><font color="#C9AFA0">3. </font>${scoreData[2].name}</p>';
				egFourthLine.text.text = '<p align="left"><font color="#A4A4A4">4. </font>${scoreData[3].name}</p>';
				egFifthLine.text.text = '<p align="left"><font color="#949494">5. </font>${scoreData[4].name}</p>';

				for (i in 0...5) {
					if (scoreData[i].time < mission.ultimateTime) {
						lineelems[i].text.text = '<font color="#FFDD22">${Util.formatTime(scoreData[i].time)}</font>';
					} else {
						if (scoreData[i].time < mission.goldTime) {
							lineelems[i].text.text = '<font color="${mission.game == "gold" || mission.game.toLowerCase() == "ultra" ? '#FFCC00' : '#CCCCCC'}">${Util.formatTime(scoreData[i].time)}</font>';
						} else {
							lineelems[i].text.text = '${Util.formatTime(scoreData[i].time)}';
						}
					}
				}

				Settings.saveScore(mission.path, myScore);

				scoreSubmitted = true;
			});
			this.addChild(end);
		}
	}
}
