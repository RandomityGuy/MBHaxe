package gui;

import modes.GameMode.ScoreType;
import src.Marbleland;
import src.Console;
import net.Net;
import net.Net.ServerInfo;
import net.MasterServerClient;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Mission;
import src.MissionList;
import src.Util;

class SPCustomsGui extends GuiImage {
	var innerCtrl:GuiControl;
	var serverWnd:GuiImage;

	public function new() {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

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

		var custWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/helpWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		custWnd.horizSizing = Right;
		custWnd.vertSizing = Bottom;
		custWnd.position = new Vector(330, 58);
		custWnd.extent = new Vector(640, 330);
		innerCtrl.addChild(custWnd);

		var customListScroll = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/osxscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		customListScroll.position = new Vector(25, 22);
		customListScroll.extent = new Vector(600, 280);
		customListScroll.scrollToBottom = false;
		custWnd.addChild(customListScroll);

		var ultraMissions = Marbleland.ultraMissions;

		var curMission = ultraMissions[0];

		var customList = new GuiTextListCtrl(arial14, ultraMissions.map(x -> '${x.title} by ${x.artist}'), 0xFFFFFF);
		var custSelectedIdx = 0;
		customList.selectedColor = 0xF29515;
		customList.selectedFillColor = 0x858585;
		customList.textColor = 0xFFFFFF;
		customList.position = new Vector(0, 0);
		customList.extent = new Vector(550, 2880);
		customList.scrollable = true;
		customListScroll.addChild(customList);
		customListScroll.setScrollMax(customList.calculateFullHeight());

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
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new DifficultySelectGui());
		bottomBar.addChild(backButton);

		var recordButton = new GuiXboxButton("Record", 200);
		recordButton.position = new Vector(560, 0);
		recordButton.vertSizing = Bottom;
		recordButton.horizSizing = Right;
		recordButton.gamepadAccelerator = [Settings.gamepadSettings.alt1];
		recordButton.pressedAction = (e) -> {
			MarbleGame.instance.toRecord = true;
			MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("The next mission you play will be recorded."));
		}
		bottomBar.addChild(recordButton);

		var lbButton = new GuiXboxButton("Leaderboard", 220);
		lbButton.position = new Vector(750, 0);
		lbButton.vertSizing = Bottom;
		lbButton.gamepadAccelerator = [Settings.gamepadSettings.alt2];
		lbButton.horizSizing = Right;
		lbButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new LeaderboardsGui(curMission.id, "customs", true));
		bottomBar.addChild(lbButton);

		var nextButton = new GuiXboxButton("Play", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.accelerators = [hxd.Key.ENTER];
		nextButton.gamepadAccelerator = [Settings.gamepadSettings.alt1];
		nextButton.pressedAction = (e) -> {
			MarbleGame.instance.playMission(curMission);
		};
		bottomBar.addChild(nextButton);

		var levelWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/levelPreviewWindow.png", ResourceLoader.getImage, this.imageResources).toTile());
		levelWnd.position = new Vector(555, 469);
		levelWnd.extent = new Vector(535, 137);
		levelWnd.vertSizing = Bottom;
		levelWnd.horizSizing = Right;
		innerCtrl.addChild(levelWnd);

		var statIcon = new GuiImage(ResourceLoader.getResource("data/ui/xbox/statIcon.png", ResourceLoader.getImage, this.imageResources).toTile());
		statIcon.position = new Vector(29, 54);
		statIcon.extent = new Vector(20, 20);
		levelWnd.addChild(statIcon);

		var eggIcon = new GuiImage(ResourceLoader.getResource("data/ui/xbox/eggIcon.png", ResourceLoader.getImage, this.imageResources).toTile());
		eggIcon.position = new Vector(29, 79);
		eggIcon.extent = new Vector(20, 20);
		levelWnd.addChild(eggIcon);

		var c0 = 0xEBEBEB;
		var c1 = 0x8DFF8D;
		var c2 = 0x88BCEE;
		var c3 = 0xFF7575;

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);
		function mlFontLoader(text:String) {
			return arial14;
		}

		var levelInfoLeft = new GuiMLText(arial14, mlFontLoader);
		levelInfoLeft.position = new Vector(69, 54);
		levelInfoLeft.extent = new Vector(180, 100);
		levelInfoLeft.text.text = '<p align="right"><font color="#EBEBEB">My Best Time:</font><br/><font color="#EBEBEB">Par Time:</font></p>';
		levelInfoLeft.text.lineSpacing = 6;
		levelWnd.addChild(levelInfoLeft);

		var levelInfoMid = new GuiMLText(arial14, mlFontLoader);
		levelInfoMid.position = new Vector(269, 54);
		levelInfoMid.extent = new Vector(180, 100);
		levelInfoMid.text.text = '<p align="left"><font color="#EBEBEB">None</font><br/><font color="#88BCEE">99:59:99</font></p>';
		levelInfoMid.text.lineSpacing = 6;
		levelWnd.addChild(levelInfoMid);

		function setLevel(idx:Int) {
			curMission = ultraMissions[idx];
			custSelectedIdx = idx;
			var misPath = 'custom/mbu/${curMission.id}';
			if (Settings.easterEggs.exists(misPath))
				eggIcon.bmp.visible = true;
			else
				eggIcon.bmp.visible = false;

			var scoreType = curMission.customSource == "MPCustoms" ? ScoreType.Score : ScoreType.Time;

			var myScore = Settings.getScores(misPath);
			var scoreDisp = "None";
			if (myScore.length != 0)
				scoreDisp = scoreType == Time ? Util.formatTime(myScore[0].time) : Util.formatScore(myScore[0].time);
			var isPar = myScore.length != 0 && myScore[0].time < curMission.qualifyTime;
			var scoreColor = "#EBEBEB";
			if (isPar)
				scoreColor = "#8DFF8D";
			if (scoreType == Score && myScore.length == 0)
				scoreColor = "#EBEBEB";
			if (scoreType == Time) {
				levelInfoLeft.text.text = '<p align="right"><font color="#EBEBEB">My Best Time:</font><br/><font color="#EBEBEB">Par Time:</font></p>';
				levelInfoMid.text.text = '<p align="left"><font color="${scoreColor}">${scoreDisp}</font><br/><font color="#88BCEE">${Util.formatTime(curMission.qualifyTime)}</font></p>';
			}
			if (scoreType == Score) {
				levelInfoLeft.text.text = '<p align="right"><font color="#EBEBEB">My Best Score:</font></p>';
				levelInfoMid.text.text = '<p align="left"><font color="${scoreColor}">${scoreDisp}</font></p>';
			}
			return true;
		}

		var levelSelectOpts = new GuiXboxOptionsList(6, "Level", ultraMissions.map(x -> x.title));
		levelSelectOpts.position = new Vector(380, 435);
		levelSelectOpts.extent = new Vector(815, 94);
		levelSelectOpts.vertSizing = Bottom;
		levelSelectOpts.horizSizing = Right;
		levelSelectOpts.alwaysActive = true;
		levelSelectOpts.onChangeFunc = setLevel;
		levelSelectOpts.setCurrentOption(0);
		setLevel(0);
		innerCtrl.addChild(levelSelectOpts);

		customList.onSelectedFunc = (idx) -> {
			setLevel(idx);
			levelSelectOpts.setCurrentOption(idx);
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
}
