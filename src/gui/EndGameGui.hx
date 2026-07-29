package gui;

import h2d.Scene;
import h2d.Flow;
import modes.GameMode.ScoreType;
import src.Leaderboards;
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
import shapes.TimeTravel;

class EndGameGui extends GuiControl {
	var mission:Mission;

	var scoreSubmitted:Bool = false;

	public function new(score:Float, scoreType:ScoreType, continueFunc:GuiControl->Void, restartFunc:GuiControl->Void, nextLevelFunc:GuiControl->Void,
			mission:Mission, timeState:TimeState, replayData:haxe.io.Bytes) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector(0, 0);
		this.extent = new Vector(800, 600);
		this.mission = mission;

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Right;
		wnd.vertSizing = Height;
		wnd.position = new Vector(128, -14);
		wnd.extent = new Vector(469, 796);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);
		var whatneyFont26 = whatneyFontB.toSdfFont(cast 23 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);

		var squishneyFont30 = squishneyFontB.toSdfFont(cast 27 * Settings.uiScale, MultiChannel);
		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);
		var squishneyFont48 = squishneyFontB.toSdfFont(cast 43 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "bold28":
					return squishneyFont30;
				case "bold30":
					return squishneyFont28;
				case "font26":
					return whatneyFont26;
				default:
					return null;
			}
		}

		var endGameBox = new GuiControl();
		endGameBox.horizSizing = Width;
		endGameBox.vertSizing = Center;
		endGameBox.position = new Vector(0, 38);
		endGameBox.extent = new Vector(469, 720);
		wnd.addChild(endGameBox);

		var egTitleText = new GuiMLText(squishneyFont48, null);
		egTitleText.position = new Vector(20, 10);
		egTitleText.extent = new Vector(247, 56);
		egTitleText.text.text = 'Your ${scoreType == Score ? "Score" : "Time"}';
		egTitleText.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x777777
		};
		egTitleText.text.textColor = 0;
		endGameBox.addChild(egTitleText);

		var beatPar = false;
		var beatPlatinum = false;
		var beatUltimate = false;
		var beatAwesome = false;

		switch (scoreType) {
			case Score:
				if (score >= mission.qualifyingScore)
					beatPar = true;
				if (score >= mission.goldScore)
					beatPlatinum = true;
				if (score >= mission.ultimateScore)
					beatUltimate = true;
				if (score >= mission.awesomeScore)
					beatAwesome = true;
			case Time:
				if (score < mission.qualifyTime)
					beatPar = true;
				if (score < mission.goldTime)
					beatPlatinum = true;
				if (score < mission.ultimateTime)
					beatUltimate = true;
				if (score < mission.awesomeTime)
					beatAwesome = true;
		}
		var scoreColor = "#000000";
		if (beatAwesome)
			scoreColor = "#FF4444";
		else if (beatUltimate)
			scoreColor = "#FFCC33";
		else if (beatPlatinum)
			scoreColor = mission.game == "gold" ? "#FFEE11" : "#CCCCCC";

		var scoreFmt = scoreType == Score ? '${Util.formatScore(Std.int(score))}' : '${Util.formatTime(score)}';

		var egResult = new GuiMLText(squishneyFont48, mlFontLoader);
		egResult.horizSizing = Left;
		egResult.position = new Vector(256, 14);
		egResult.extent = new Vector(194, 56);
		egResult.text.text = '<p align="right"><font color="${scoreColor}">${scoreFmt}</font></p>';
		egResult.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x777777,
		};
		endGameBox.addChild(egResult);

		var continueButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont26);
		continueButton.position = new Vector(325, 507);
		continueButton.setExtent(new Vector(112, 55));
		continueButton.vertSizing = Top;
		continueButton.horizSizing = Left;
		continueButton.gamepadAccelerator = ["A"];
		continueButton.pressedAction = (e) -> continueFunc(continueButton);
		continueButton.txtCtrl.text.text = "Menu";
		endGameBox.addChild(continueButton);

		var restartButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont26);
		restartButton.position = new Vector(27, 507);
		restartButton.setExtent(new Vector(112, 55));
		restartButton.vertSizing = Top;
		restartButton.horizSizing = Right;
		restartButton.gamepadAccelerator = ["B"];
		restartButton.pressedAction = (e) -> restartFunc(restartButton);
		restartButton.txtCtrl.text.text = "Restart";
		endGameBox.addChild(restartButton);

		var nextLevelButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont26);
		nextLevelButton.position = new Vector(177, 507);
		nextLevelButton.setExtent(new Vector(112, 55));
		nextLevelButton.vertSizing = Top;
		nextLevelButton.horizSizing = Center;
		nextLevelButton.gamepadAccelerator = ["X"];
		nextLevelButton.pressedAction = (e) -> nextLevelFunc(nextLevelButton);
		nextLevelButton.txtCtrl.text.text = "Next";
		endGameBox.addChild(nextLevelButton);

		var container = new GuiControl();
		container.horizSizing = Right;
		container.vertSizing = Height;
		container.position = new Vector(36, 62);
		container.extent = new Vector(409, 579);
		endGameBox.addChild(container);

		var text = '<font color="#000000" face="bold30"><p align="center">';
		// Check for ultimate time TODO
		if (MarbleGame.instance.world.cheatsUsed)
			text += "Nice Cheats!";
		else {
			if (beatAwesome)
				text += 'Who\'s Awesome? <font color="#FF3333">You\'re</font> Awesome!';
			else if (beatUltimate)
				text += 'You beat the <font color="#FFCC33">Ultimate</font> ${scoreType == Score ? "Score" : "Time"}!';
			else if (beatPlatinum) {
				if (mission.game == "gold" || mission.game.toLowerCase() == "ultra")
					text += 'You beat the <font color="#FFEE11">Gold</font> ${scoreType == Score ? "Score" : "Time"}!';
				else
					text += 'You beat the <font color="#CCCCCC">Platinum</font> ${scoreType == Score ? "Score" : "Time"}!';
			} else if (beatPar) {
				if (mission.game == "gold")
					text += 'You\'ve Qualified';
				else
					text += 'You beat the Par ${scoreType == Score ? "Score" : "Time"}!';
			} else {
				if (mission.game == "gold")
					text += '<font color="F55555">You didn\'t pass the Qualify ${scoreType == Score ? "Score" : "Time"}</font>';
				else
					text += '<font color="F55555">You didn\'t pass the Par ${scoreType == Score ? "Score" : "Time"}</font>';
			}
		}
		text += '</p></font>';

		var descriptionTop = text;

		var goldTimeLabel = mission.goldTime != 0 ? Util.formatTime(mission.goldTime) : "N/A";
		var ultimateTimeLabel = mission.ultimateTime != 0 ? Util.formatTime(mission.ultimateTime) : "N/A";
		var awesomeTimeLabel = mission.awesomeTime != 0 ? Util.formatTime(mission.awesomeTime) : "N/A";
		var goldScoreLabel = mission.goldScore != 0 ? Util.formatScore(mission.goldScore) : "N/A";
		var ultimateScoreLabel = mission.ultimateScore != 0 ? Util.formatScore(mission.ultimateScore) : "N/A";
		var awesomeScoreLabel = mission.awesomeScore != 0 ? Util.formatScore(mission.awesomeScore) : "N/A";

		var goldLabel = goldTimeLabel == "N/A" ? goldScoreLabel : goldTimeLabel;
		var ultimateLabel = ultimateTimeLabel == "N/A" ? ultimateScoreLabel : ultimateTimeLabel;
		var awesomeLabel = awesomeTimeLabel == "N/A" ? awesomeScoreLabel : awesomeTimeLabel;

		var goldType = goldTimeLabel == "N/A" ? ScoreType.Score : ScoreType.Time;
		var ultimateType = ultimateTimeLabel == "N/A" ? ScoreType.Score : ScoreType.Time;
		var awesomeType = awesomeTimeLabel == "N/A" ? ScoreType.Score : ScoreType.Time;

		var parTimeLabel = mission.qualifyTime != Math.POSITIVE_INFINITY ? Util.formatTime(mission.qualifyTime) : "N/A";
		var parScoreLabel = mission.qualifyingScore != 0 ? Util.formatScore(mission.qualifyingScore) : "N/A";
		var parLabel = scoreType == Time ? parTimeLabel : parScoreLabel;
		var parType = scoreType == Time ? "Time" : "Score";

		var parTitle = mission.game == "gold" ? 'Qualify ${scoreType == Score ? "Score" : "Time"}' : 'Par ${scoreType == Score ? "Score" : "Time"}';
		var goldTitle = mission.game == "gold" ? '<font color="#FFEE11">Gold ${scoreType == Score ? "Score" : "Time"}:</font>' : '<font color="#CCCCCC">Platinum ${scoreType == Score ? "Score" : "Time"}:</font>';
		var ultimateTitle = '<font color="#FFCC33">Ultimate ${scoreType == Score ? "Score" : "Time"}:</font>';
		var awesomeTitle = '<font color="#FF3333">Awesome ${scoreType == Score ? "Score" : "Time"}:</font>';

		var textLeft = '<font face="font26">';
		var textRight = '<font face="font26">';

		textLeft += '<p align="left">${parTitle}</p>';
		textRight += '<p align="right">${parLabel}</p>';

		if (goldLabel != "N/A") {
			textLeft += '<p align="left">${goldTitle}</p>';
			textRight += '<p align="right"><font color="#FFEE11">${goldLabel}</font></p>';
		}
		if (ultimateLabel != "N/A") {
			textLeft += '<p align="left">${ultimateTitle}</p>';
			textRight += '<p align="right"><font color="#FFCC33">${ultimateLabel}</font></p>';
		}
		if (awesomeLabel != "N/A" && beatAwesome) {
			textLeft += '<p align="left">${awesomeTitle}</p>';
			textRight += '<p align="right"><font color="#FF3333">${awesomeLabel}</font></p>';
		}

		var totalTTs = 0;
		var pickedUp = 0;
		for (dts in MarbleGame.instance.world.powerUps) {
			if (dts is TimeTravel && dts.cooldownDuration == 1e8) {
				var tt:TimeTravel = cast dts;
				if (tt.timeBonus > 0) {
					totalTTs += 1;
					if (dts.currentOpacity == 0.0)
						pickedUp += 1;
				}
			}
		}

		var elapsedTime = Math.max(timeState.currentAttemptTime - 3.5, 0);

		textLeft += '<p align="left">Time Passed:</p>';
		textRight += '<p align="right">${Util.formatTime(elapsedTime)}</p>';

		var textTTs = "";
		if (totalTTs != 0) {
			var plural = totalTTs > 1 ? "s" : "";
			textTTs = '<font color="#00FF00">(${pickedUp}/${totalTTs} TT${plural})</font>';
		}

		textLeft += '<p align="left">Clock Bonuses:</p>';
		textRight += '<p align="right">${Util.formatTime(MarbleGame.instance.world.collectedBonusTime)} ${textTTs}</p>';

		textLeft += "</font>";
		textRight += "</font>";

		var egDescriptionTop = new GuiMLText(squishneyFont48, mlFontLoader);
		egDescriptionTop.horizSizing = Width;
		egDescriptionTop.position = new Vector(0, 0);
		egDescriptionTop.extent = new Vector(397, 252);
		egDescriptionTop.text.text = descriptionTop;
		egDescriptionTop.text.textColor = 0;
		egDescriptionTop.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x000000,
		};
		container.addChild(egDescriptionTop);

		var egDescriptionLeft = new GuiMLText(squishneyFont48, mlFontLoader);
		egDescriptionLeft.horizSizing = Width;
		egDescriptionLeft.position = new Vector(0, 60);
		egDescriptionLeft.extent = new Vector(397, 252);
		egDescriptionLeft.text.text = textLeft;
		egDescriptionLeft.text.textColor = 0;
		egDescriptionLeft.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x000000,
		};
		container.addChild(egDescriptionLeft);

		var egDescriptionRight = new GuiMLText(squishneyFont48, mlFontLoader);
		egDescriptionRight.horizSizing = Width;
		egDescriptionRight.position = new Vector(0, 60);
		egDescriptionRight.extent = new Vector(397, 252);
		egDescriptionRight.text.text = textRight;
		egDescriptionRight.text.textColor = 0;
		egDescriptionRight.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x000000,
		};
		container.addChild(egDescriptionRight);

		var egTopTimesTextTop = new GuiMLText(squishneyFont48, mlFontLoader);
		egTopTimesTextTop.horizSizing = Width;
		egTopTimesTextTop.vertSizing = Top;
		egTopTimesTextTop.position = new Vector(0, 257);
		egTopTimesTextTop.extent = new Vector(397, 186);
		egTopTimesTextTop.text.text = '';
		egTopTimesTextTop.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x777777,
		};
		container.addChild(egTopTimesTextTop);

		var egTopTimesTextLeft = new GuiMLText(squishneyFont48, mlFontLoader);
		egTopTimesTextLeft.horizSizing = Width;
		egTopTimesTextLeft.vertSizing = Top;
		egTopTimesTextLeft.position = new Vector(0, 257);
		egTopTimesTextLeft.extent = new Vector(397, 186);
		egTopTimesTextLeft.text.text = '';
		egTopTimesTextLeft.text.textColor = 0;
		egTopTimesTextLeft.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x777777,
		};
		container.addChild(egTopTimesTextLeft);

		var egTopTimesTextRight = new GuiMLText(squishneyFont48, mlFontLoader);
		egTopTimesTextRight.horizSizing = Width;
		egTopTimesTextRight.vertSizing = Top;
		egTopTimesTextRight.position = new Vector(0, 257);
		egTopTimesTextRight.extent = new Vector(397, 186);
		egTopTimesTextRight.text.text = '';
		egTopTimesTextRight.text.textColor = 0;
		egTopTimesTextRight.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0x777777,
		};
		container.addChild(egTopTimesTextRight);

		function reformatScoreList() {
			var scoreData:Array<Score> = Settings.getScores(mission.path);
			var scoreCount = Math.min(scoreData.length, 5);
			while (scoreData.length < 5) {
				scoreData.push({name: "Matan W.", time: scoreType == Time ? 5999.999 : 0, type: scoreType == Time ? 0 : 1});
			}

			// find our score index
			var idx = -1;
			for (i in 0...5) {
				if (scoreData[i].time == score && scoreData[i].type == (scoreType == Score ? 1 : 0)) {
					idx = i;
					break;
				}
			}

			var scoreText = '<font face="bold28" color="#000000"><p align="center">${mission.title}, Top ${scoreCount}</p></font>';

			egTopTimesTextTop.text.text = scoreText;

			var scoreLeft = '<font face="bold28" color="#000000">\n</font><font face="font26">';
			var scoreRight = '<font face="bold28" color="#000000">\n</font><font face="font26">';

			for (i in 0...5) {
				if (i == idx) {
					scoreLeft += '<p align="left"><font color="#00DD00">${i + 1}. </font>${scoreData[i].name}</p>';
				} else {
					switch (i) {
						case 0:
							scoreLeft += '<p align="left"><font color="#EEC884">1. </font>${scoreData[i].name}</p>';
						case 1:
							scoreLeft += '<p align="left"><font color="#CDCDCD">2. </font>${scoreData[i].name}</p>';
						case 2:
							scoreLeft += '<p align="left"><font color="#C9AFA0">3. </font>${scoreData[i].name}</p>';
						case 3:
							scoreLeft += '<p align="left"><font color="#A4A4A4">4. </font>${scoreData[i].name}</p>';
						case 4:
							scoreLeft += '<p align="left"><font color="#949494">5. </font>${scoreData[i].name}</p>';
					}
				}

				var scoreColor = Util.getScoreColor(scoreData[i].time, scoreData[i].type == 1 ? Score : Time, mission);
				var formatted = scoreType == Time ? Util.formatTime(scoreData[i].time) : Util.formatScore(Std.int(scoreData[i].time));

				if (i == idx)
					scoreColor = "#00DD00";

				scoreRight += '<p align="right"><font color="${scoreColor}">${formatted}</font></p>';
			}

			scoreLeft += "</font>";
			scoreRight += "</font>";

			egTopTimesTextLeft.text.text = scoreLeft;
			egTopTimesTextRight.text.text = scoreRight;
		}

		reformatScoreList();

		function setButtonStates(enabled:Bool) {
			nextLevelButton.disabled = !enabled;
			continueButton.disabled = !enabled;
			restartButton.disabled = !enabled;
		}
		// if (Settings.progression[mission.difficultyIndex] == mission.index && qualified) {
		// 	Settings.progression[mission.difficultyIndex]++;
		// }
		Settings.save();

		var rewindUsed = MarbleGame.instance.world.rewindUsed;
		var cheatsUsed = MarbleGame.instance.world.cheatsUsed;

		var scoreData:Array<Score> = Settings.getScores(mission.path);
		// add our score to get the index
		scoreData.push({name: Settings.highscoreName, type: scoreType == Score ? 1 : 0, time: score});
		// sort

		scoreData.sort((a, b) -> {
			if (a.type == b.type) {
				if (a.type == 0) // time
					return a.time == b.time ? 0 : (a.time > b.time ? 1 : -1);
				else
					return a.time == b.time ? 0 : (a.time > b.time ? -1 : 1);
			} else {
				return a.type > b.type ? 1 : -1;
			}
		});

		// find our score index
		var idx = -1;
		for (i in 0...5) {
			if (scoreData[i].time == score && scoreData[i].type == (scoreType == Score ? 1 : 0)) {
				idx = i;
				break;
			}
		}

		if (idx <= 4) {
			setButtonStates(false);
			var end = new EnterNameDlg(idx, (name) -> {
				setButtonStates(true);
				if (scoreSubmitted)
					return;

				if (!cheatsUsed) { // dont submit or save if we have cheated
					Settings.saveScore(mission.path, {name: name, type: scoreType == Score ? 1 : 0, time: score});
					reformatScoreList();
					var lbPath = mission.path;
					if (mission.isClaMission)
						lbPath = 'custom/${mission.id}';
					Leaderboards.submitScore(lbPath, score, rewindUsed, (sendReplay, rowId) -> {
						if (sendReplay && !mission.isClaMission) {
							Leaderboards.submitReplay(rowId, replayData);
						}
					});
				}

				scoreSubmitted = true;
			});
			this.addChild(end);
		} else {
			// Check if we can submit LB scores
			var lbPath = mission.path;
			if (mission.isClaMission)
				lbPath = 'custom/${mission.id}';
			Leaderboards.getScores(lbPath, All, (scores) -> {
				var hasMyScore = false;
				var myTopScoreLB = 0.0;
				for (score in scores) {
					if (score.name == Settings.highscoreName) {
						hasMyScore = true;
						myTopScoreLB = score.score;
						break;
					}
				}
				if (!cheatsUsed) {
					if (!hasMyScore || (hasMyScore && myTopScoreLB > timeState.gameplayClock)) {
						Leaderboards.submitScore(lbPath, timeState.gameplayClock, rewindUsed, (sendReplay, rowId) -> {
							if (sendReplay && !mission.isClaMission) {
								Leaderboards.submitReplay(rowId, replayData);
							}
						});
					}
				}
			});
		}
	}
}
