package gui;

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

		var pg = new GuiImage(ResourceLoader.getResource("data/ui/play/playgui.png", ResourceLoader.getImage, this.imageResources).toTile());
		pg.horizSizing = Center;
		pg.vertSizing = Center;
		pg.position = new Vector(77, 9);
		pg.extent = new Vector(485, 461);

		var continueButton = new GuiButton(loadButtonImages("data/ui/endgame/continue"));
		continueButton.horizSizing = Right;
		continueButton.vertSizing = Bottom;
		continueButton.position = new Vector(333, 386);
		continueButton.extent = new Vector(113, 47);
		continueButton.accelerator = hxd.Key.ENTER;
		continueButton.pressedAction = continueFunc;

		var restartButton = new GuiButton(loadButtonImages("data/ui/endgame/replay"));
		restartButton.horizSizing = Right;
		restartButton.vertSizing = Bottom;
		restartButton.position = new Vector(51, 388);
		restartButton.extent = new Vector(104, 48);
		restartButton.pressedAction = restartFunc;

		function setButtonStates(enabled:Bool) {
			continueButton.disabled = !enabled;
			restartButton.disabled = !enabled;
		}

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var expo50fontdata = ResourceLoader.getFileEntry("data/font/EXPON.fnt");
		var expo50b = new BitmapFont(expo50fontdata.entry);
		@:privateAccess expo50b.loader = ResourceLoader.loader;
		var expo50 = expo50b.toSdfFont(cast 35 * Settings.uiScale, MultiChannel);
		var expo32 = expo50b.toSdfFont(cast 24 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual32":
					return domcasual32;
				case "Arial14":
					return arial14;
				case "Expo32":
					return expo32;
				default:
					return null;
			}
		}

		var congrats = new GuiMLText(expo50, mlFontLoader);
		congrats.text.textColor = 0xffff00;
		congrats.text.text = 'Final Time: <font color="#FFF090">${Util.formatTime(timeState.gameplayClock)}</font>';
		congrats.text.filter = new DropShadow(1.414, 0.785, 0, 1, 0, 0.4, 1, true);
		congrats.position = new Vector(43, 24);
		congrats.extent = new Vector(408, 50);
		pg.addChild(congrats);

		var finishMessage = new GuiMLText(expo32, mlFontLoader);
		finishMessage.text.textColor = 0x00ff00;
		var qualified = mission.qualifyTime > timeState.gameplayClock;
		if (qualified)
			finishMessage.text.text = timeState.gameplayClock < mission.goldTime ? 'You beat the <font color="#FFFF00">GOLD</font> time!' : "You've qualified!";
		else
			finishMessage.text.text = '<font color="#FF0000">You failed to qualify!</font>';
		finishMessage.text.filter = new DropShadow(1, 0.785, 0, 1, 0, 0.4, 1, true);
		// finishMessage.justify = Center;
		finishMessage.position = new Vector(155, 74);
		if (timeState.gameplayClock < mission.goldTime) {
			finishMessage.position.x = 110;
		}
		if (!qualified)
			finishMessage.position.x = 125;
		finishMessage.extent = new Vector(400, 100);
		pg.addChild(finishMessage);

		var scoreData:Array<Score> = Settings.getScores(mission.path);
		while (scoreData.length < 3) {
			scoreData.push({name: "Nardo Polo", time: 5999.999});
		}

		var leftColumn = new GuiMLText(domcasual32, mlFontLoader);
		leftColumn.text.lineSpacing = 5;
		leftColumn.text.textColor = 0x000000;
		leftColumn.text.text = 'Qualify Time:<br/>Gold Time:<br/>Elapsed Time:<br/>Bonus Time:<br/><font face="Arial14"><br/></font>Best Times:<br/>';
		for (i in 0...3) {
			leftColumn.text.text += '${i + 1}. ${scoreData[i].name}<br/>';
		}
		leftColumn.text.filter = new DropShadow(1.414, 0.785, 0xffffff, 1, 0, 0.4, 1, true);
		leftColumn.position = new Vector(108, 113);
		leftColumn.extent = new Vector(208, 50);
		pg.addChild(leftColumn);

		var elapsedTime = Math.max(timeState.currentAttemptTime - 3.5, 0);
		var bonusTime = Math.max(0, elapsedTime - timeState.gameplayClock);

		var rightColumn = new GuiMLText(domcasual32, mlFontLoader);
		rightColumn.text.lineSpacing = 5;
		rightColumn.text.textColor = 0x000000;
		rightColumn.text.text = '${Util.formatTime(mission.qualifyTime == Math.POSITIVE_INFINITY ? 5999.999 : mission.qualifyTime)}<br/><br/>${Util.formatTime(elapsedTime)}<br/>${Util.formatTime(bonusTime)}<br/><font face="Arial14"><br/></font><br/>';
		for (i in 0...3) {
			if (scoreData[i].time < mission.goldTime)
				rightColumn.text.text += '<br/>';
			else
				rightColumn.text.text += '${Util.formatTime(scoreData[i].time)}<br/>';
		}
		rightColumn.text.filter = new DropShadow(1.414, 0.785, 0xffffff, 1, 0, 0.4, 1, true);
		rightColumn.position = new Vector(274, 113);
		rightColumn.extent = new Vector(208, 50);
		pg.addChild(rightColumn);

		var rightColumnGold = new GuiMLText(domcasual32, mlFontLoader);
		rightColumnGold.text.lineSpacing = 5;
		rightColumnGold.text.textColor = 0xFFFF00;
		rightColumnGold.text.text = '<br/>${Util.formatTime(mission.goldTime)}<br/><br/><br/><font face="Arial14"><br/></font><br/>';
		for (i in 0...3) {
			if (scoreData[i].time < mission.goldTime)
				rightColumnGold.text.text += '${Util.formatTime(scoreData[i].time)}<br/>';
			else
				rightColumnGold.text.text += '<br/>';
		}
		rightColumnGold.text.filter = new DropShadow(1.414, 0.785, 0x00000, 1, 0, 0.4, 1, true);
		rightColumnGold.position = new Vector(274, 113);
		rightColumnGold.extent = new Vector(208, 50);
		pg.addChild(rightColumnGold);

		pg.addChild(continueButton);
		pg.addChild(restartButton);

		this.addChild(pg);

		var scoreTimes = scoreData.map(x -> x.time).concat([timeState.gameplayClock]);
		scoreTimes.sort((a, b) -> a == b ? 0 : (a > b ? 1 : -1));

		var idx = scoreTimes.indexOf(timeState.gameplayClock);

		if (Settings.progression[mission.difficultyIndex] == mission.index && qualified) {
			Settings.progression[mission.difficultyIndex]++;
		}
		Settings.save();

		if (idx <= 2) {
			setButtonStates(false);
			var end = new EnterNameDlg(idx, (name) -> {
				setButtonStates(true);
				if (scoreSubmitted)
					return;

				var myScore = {name: name, time: timeState.gameplayClock};
				scoreData.push(myScore);
				scoreData.sort((a, b) -> a.time == b.time ? 0 : (a.time > b.time ? 1 : -1));

				leftColumn.text.text = 'Qualify Time:<br/>Gold Time:<br/>Elapsed Time:<br/>Bonus Time:<br/><font face="Arial14"><br/></font>Best Times:<br/>';
				for (i in 0...3) {
					leftColumn.text.text += '${i + 1}. ${scoreData[i].name}<br/>';
				}

				rightColumn.text.text = '${Util.formatTime(mission.qualifyTime == Math.POSITIVE_INFINITY ? 5999.999 : mission.qualifyTime)}<br/><br/>${Util.formatTime(elapsedTime)}<br/>${Util.formatTime(bonusTime)}<br/><font face="Arial14"><br/></font><br/>';
				for (i in 0...3) {
					if (scoreData[i].time < mission.goldTime)
						rightColumn.text.text += '<br/>';
					else
						rightColumn.text.text += '${Util.formatTime(scoreData[i].time)}<br/>';
				}

				rightColumnGold.text.text = '<br/>${Util.formatTime(mission.goldTime)}<br/><br/><br/><font face="Arial14"><br/></font><br/>';
				for (i in 0...3) {
					if (scoreData[i].time < mission.goldTime)
						rightColumnGold.text.text += '${Util.formatTime(scoreData[i].time)}<br/>';
					else
						rightColumnGold.text.text += '<br/>';
				}

				Settings.saveScore(mission.path, myScore);

				scoreSubmitted = true;
			});
			this.addChild(end);
		}
	}
}
