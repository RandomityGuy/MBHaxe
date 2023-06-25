package gui;

import mis.MisParser;
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

class EndGameGui extends GuiImage {
	var mission:Mission;

	var scoreSubmitted:Bool = false;

	public function new(continueFunc:GuiControl->Void, restartFunc:GuiControl->Void, nextLevelFunc:GuiControl->Void, mission:Mission, timeState:TimeState) {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);
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

		var scene2d = MarbleGame.canvas.scene2d;

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var subX = 640 - (scene2d.width - offsetX) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY) * 480 / scene2d.height;

		var innerCtrl = new GuiControl();
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
		rootTitle.text.text = "LEVEL COMPLETE!";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var endGameWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/endGameWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		endGameWnd.horizSizing = Left;
		endGameWnd.vertSizing = Top;
		endGameWnd.position = new Vector(80 - offsetX, 170 - offsetY);
		endGameWnd.extent = new Vector(336, 150);
		innerCtrl.addChild(endGameWnd);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 22 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		var statIcon = new GuiImage(ResourceLoader.getResource("data/ui/xbox/statIcon.png", ResourceLoader.getImage, this.imageResources).toTile());
		statIcon.position = new Vector(38, 27);
		statIcon.extent = new Vector(20, 20);
		endGameWnd.addChild(statIcon);

		function mlFontLoader(text:String) {
			return arial14;
		}

		var beatPar = timeState.gameplayClock < mission.qualifyTime;

		var egResultLeft = new GuiMLText(arial14, mlFontLoader);
		egResultLeft.position = new Vector(28, 26);
		egResultLeft.extent = new Vector(180, 100);
		egResultLeft.text.text = '<p align="right"><font color="${beatPar ? "#8DFF8D" : "0xFF7575"}">Time:</font><br/><font color="#88BCEE">Par Time:</font><br/><font color="#EBEBEB">Rating:</font><br/><font color="#EBEBEB">My Best Time:</font></p>';
		endGameWnd.addChild(egResultLeft);
		var c0 = 0xEBEBEB;
		var c1 = 0x8DFF8D;
		var c2 = 0x88BCEE;
		var c3 = 0xFF7575;

		function calcRating(time:Float, parTime:Float, goldTime:Float, difficulty:Int):Int {
			var t = time - (time % 10);
			if (t == 0)
				return 0;
			var completionBonus = 1000;
			var timeBonus = 0;
			if (t < parTime)
				timeBonus = Math.floor(parTime / t) * 1000;
			else
				timeBonus = Math.floor(parTime / t) * 500;
			return (completionBonus + timeBonus) * difficulty;
		}

		var rating = calcRating(timeState.gameplayClock * 1000, mission.qualifyTime * 1000, mission.goldTime * 1000,
			Std.parseInt(mission.missionInfo.difficulty));

		var myScore = {name: "Player", time: timeState.gameplayClock};
		Settings.saveScore(mission.path, myScore);

		var scoreData:Array<Score> = Settings.getScores(mission.path);
		while (scoreData.length < 1) {
			scoreData.push({name: "Nardo Polo", time: 5999.999});
		}

		var bestScore = scoreData[0];

		var egResultRight = new GuiMLText(arial14, mlFontLoader);

		egResultRight.position = new Vector(214, 26);
		egResultRight.extent = new Vector(180, 100);
		egResultRight.text.text = '<font color="${beatPar ? "#8DFF8D" : "0xFF7575"}">${Util.formatTime(timeState.gameplayClock)}</font><br/><font color="#88BCEE">${Util.formatTime(mission.qualifyTime)}</font><br/><font color="#EBEBEB">${rating}</font><br/><font color="#EBEBEB">${Util.formatTime(bestScore.time)}</font>';
		endGameWnd.addChild(egResultRight);

		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var retryButton = new GuiXboxButton("Retry", 160);
		retryButton.position = new Vector(400, 0);
		retryButton.vertSizing = Bottom;
		retryButton.horizSizing = Right;
		retryButton.gamepadAccelerator = ["B"];
		retryButton.pressedAction = (e) -> restartFunc(retryButton);
		bottomBar.addChild(retryButton);

		var lbButton = new GuiXboxButton("Leaderboard", 220);
		lbButton.position = new Vector(750, 0);
		lbButton.vertSizing = Bottom;
		lbButton.horizSizing = Right;
		bottomBar.addChild(lbButton);

		var nextButton = new GuiXboxButton("Next", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.pressedAction = (e) -> continueFunc(nextButton);
		bottomBar.addChild(nextButton);
	}
}
