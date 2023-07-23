package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Mission;
import src.MissionList;

class AchievementsGui extends GuiImage {
	var innerCtrl:GuiControl;
	var achievementsWnd:GuiImage;

	public function new(isPause:Bool = false) {
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
		#if js
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

		achievementsWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/achievementWindow.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		achievementsWnd.horizSizing = Right;
		achievementsWnd.vertSizing = Bottom;
		achievementsWnd.position = new Vector(innerCtrl.extent.x / 2 + 25, innerCtrl.extent.y / 3);
		achievementsWnd.extent = new Vector(640, 480);
		innerCtrl.addChild(achievementsWnd);

		function imgLoader(path:String) {
			switch (path) {
				case "locked":
					return ResourceLoader.getResource("data/ui/xbox/DemoOutOfTimeIcon.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unlocked":
					return ResourceLoader.getResource("data/ui/xbox/Ready.png", ResourceLoader.getImage, this.imageResources).toTile();
			}
			return null;
		}

		var curSelection = -1;

		check(); // Check achievements

		var achNameDisplays = [
			"<img src='locked'></img>Timely Marble",
			"<img src='locked'></img>Apprentice's Badge",
			"<img src='locked'></img>Journeyman's Badge",
			"<img src='locked'></img>Adept's Badge",
			"<img src='locked'></img>Marble-fu Initiate",
			"<img src='locked'></img>Marble-fu Master",
			"<img src='locked'></img>Marble-fu Transcendent",
			"<img src='locked'></img>Egg Seeker",
			"<img src='locked'></img>Egg Basket"
		];
		if (Settings.achievementProgression & 1 == 1)
			achNameDisplays[0] = "<img src='unlocked'></img>Timely Marble";
		if (Settings.achievementProgression & 2 == 2)
			achNameDisplays[1] = "<img src='unlocked'></img>Apprentice's Badge";
		if (Settings.achievementProgression & 4 == 4)
			achNameDisplays[2] = "<img src='unlocked'></img>Journeyman's Badge";
		if (Settings.achievementProgression & 8 == 8)
			achNameDisplays[3] = "<img src='unlocked'></img>Adept's Badge";
		if (Settings.achievementProgression & 16 == 16)
			achNameDisplays[4] = "<img src='unlocked'></img>Marble-fu Initiate";
		if (Settings.achievementProgression & 32 == 32)
			achNameDisplays[5] = "<img src='unlocked'></img>Marble-fu Master";
		if (Settings.achievementProgression & 64 == 64)
			achNameDisplays[6] = "<img src='unlocked'></img>Marble-fu Transcendent";
		if (Settings.achievementProgression & 128 == 128)
			achNameDisplays[7] = "<img src='unlocked'></img>Egg Seeker";
		if (Settings.achievementProgression & 256 == 256)
			achNameDisplays[8] = "<img src='unlocked'></img>Egg Basket";

		var achievementsList = new GuiMLTextListCtrl(arial14, achNameDisplays, imgLoader);

		achievementsList.selectedColor = 0xF29515;
		achievementsList.selectedFillColor = 0xEBEBEB;
		achievementsList.position = new Vector(25, 22);
		achievementsList.extent = new Vector(550, 480);
		achievementsList.scrollable = true;
		achievementsList.onSelectedFunc = (sel) -> {
			curSelection = sel;
		}
		achievementsWnd.addChild(achievementsList);

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
		backButton.gamepadAccelerator = ["B"];
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		if (isPause)
			backButton.pressedAction = (e) -> {
				MarbleGame.canvas.popDialog(this);
				MarbleGame.instance.showPauseUI();
			}
		else
			backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MainMenuGui());
		bottomBar.addChild(backButton);

		var nextButton = new GuiXboxButton("Details", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.accelerators = [hxd.Key.ENTER];
		nextButton.gamepadAccelerator = ["X"];
		nextButton.pressedAction = (e) -> {
			var desc = "Select an achievement from the list.";
			var selection = curSelection;
			switch (selection) {
				case 0: desc = "Finish any level under par time.";
				case 1: desc = "Complete all Beginner levels.";
				case 2: desc = "Complete all Intermediate levels.";
				case 3: desc = "Complete all Advanced levels.";
				case 4: desc = "Finish all Beginner levels under par time.";
				case 5: desc = "Finish all Intermediate levels under par time.";
				case 6: desc = "Finish all Advanced levels under par time.";
				case 7: desc = "Find any hidden easter egg.";
				case 8: desc = "Find all twenty easter eggs.";
				case 9: desc = "Get first place in a multiplayer match.";
				case 10: desc = "Get 75 points in a multiplayer match.";
				case 11: desc = "Collect 2,000 total points in multiplayer.";
				case 12: desc = "Complete all Bonus levels.";
				case 13: desc = "Finish all Bonus levels under par time.";
			}
			MarbleGame.canvas.pushDialog(new MessageBoxOkDlg(desc));
		};
		bottomBar.addChild(nextButton);
	}

	public static function check() {
		// Now do the actual achievement check logic
		var completions:Map<String, Array<{
			mission:Mission,
			beatPar:Bool,
			beaten:Bool
		}>> = [];

		var totalEggs = 0;
		var totalPars = 0;

		var notifies = 0;

		for (difficulty => missions in MissionList.missionList["ultra"]) {
			completions.set(difficulty, missions.map(mis -> {
				var misScores = Settings.getScores(mis.path);
				if (misScores.length == 0) {
					return {
						mission: mis,
						beatPar: false,
						beaten: false
					}
				}
				var bestTime = misScores[0];
				var beatPar = bestTime.time < mis.qualifyTime;
				if (beatPar)
					totalPars++;
				var beaten = true;

				if (Settings.easterEggs.exists(mis.path))
					totalEggs++;
				return {
					mission: mis,
					beatPar: beatPar,
					beaten: beaten
				};
			}));
		}

		// Timely marble
		if (Settings.achievementProgression & 1 != 1) {
			if (totalPars > 0) {
				Settings.achievementProgression |= 1;
				notifies |= 1;
			}
		}

		// All Beginners
		if (Settings.achievementProgression & 2 != 2) {
			if (completions.get("beginner")
				.filter(x -> x.beaten)
				.length == completions.get("beginner")
				.length) {
				Settings.achievementProgression |= 2;
				notifies |= 2;
			}
		}

		// All Intermediates
		if (Settings.achievementProgression & 4 != 4) {
			if (completions.get("intermediate")
				.filter(x -> x.beaten)
				.length == completions.get("intermediate")
				.length) {
				Settings.achievementProgression |= 4;
				notifies |= 4;
			}
		}

		// All Advanced
		if (Settings.achievementProgression & 8 != 8) {
			if (completions.get("advanced")
				.filter(x -> x.beaten)
				.length == completions.get("advanced")
				.length) {
				Settings.achievementProgression |= 8;
				notifies |= 8;
			}
		}

		// All Beginner pars
		if (Settings.achievementProgression & 16 != 16) {
			if (completions.get("beginner")
				.filter(x -> x.beatPar)
				.length == completions.get("beginner")
				.length) {
				Settings.achievementProgression |= 16;
				notifies |= 16;
			}
		}

		// All Intermediate pars
		if (Settings.achievementProgression & 32 != 32) {
			if (completions.get("intermediate")
				.filter(x -> x.beatPar)
				.length == completions.get("intermediate")
				.length) {
				Settings.achievementProgression |= 32;
				notifies |= 32;
			}
		}

		// All Advanced pars
		if (Settings.achievementProgression & 64 != 64) {
			if (completions.get("advanced")
				.filter(x -> x.beatPar)
				.length == completions.get("advanced")
				.length) {
				Settings.achievementProgression |= 64;
				notifies |= 64;
			}
		}

		// Egg Seeker
		if (Settings.achievementProgression & 128 != 128) {
			if (totalEggs >= 1) {
				Settings.achievementProgression |= 128;
				notifies |= 128;
			}
		}

		// Egg Basket
		if (Settings.achievementProgression & 256 != 256) {
			if (totalEggs >= 20) {
				Settings.achievementProgression |= 256;
				notifies |= 256;
			}
		}

		var showdlgs = [];
		for (i in 0...9) {
			if (notifies & (1 << i) > 0) {
				var popup = new AchievementPopupDlg(i + 1);
				showdlgs.push(popup);
			}
		}
		if (showdlgs.length > 1) {
			for (i in 0...showdlgs.length - 1) {
				showdlgs[i].onFinish = () -> {
					MarbleGame.canvas.pushDialog(showdlgs[i + 1]);
				}
			}
		}
		if (showdlgs.length != 0)
			MarbleGame.canvas.pushDialog(showdlgs[0]); // Start off!

		return notifies;
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		achievementsWnd.position = new Vector(innerCtrl.extent.x / 2 + 25, innerCtrl.extent.y / 3);

		super.onResize(width, height);
	}
}
