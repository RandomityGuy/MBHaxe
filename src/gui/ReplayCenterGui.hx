package gui;

import hxd.fs.BytesFileSystem.BytesFileEntry;
import src.Marbleland;
import src.Mission;
import hxd.BitmapData;
import hxd.res.BitmapFont;
import src.Replay;
import src.ResourceLoader;
import h3d.Vector;
import src.Util;
import src.MarbleGame;
import src.Settings;
import src.MissionList;

class ReplayCenterGui extends GuiImage {
	var innerCtrl:GuiControl;

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

		var scene2d = MarbleGame.canvas.scene2d;

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

		var coliseumfontdata = ResourceLoader.getFileEntry("data/font/ColiseumRR.fnt");
		var coliseumb = new BitmapFont(coliseumfontdata.entry);
		@:privateAccess coliseumb.loader = ResourceLoader.loader;
		var coliseum = coliseumb.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var rootTitle = new GuiText(coliseum);

		rootTitle.position = new Vector(100, 30);
		rootTitle.extent = new Vector(1120, 80);
		rootTitle.text.textColor = 0xFFFFFF;
		rootTitle.text.text = "REPLAY CENTRE";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var achievementsWnd = new GuiImage(ResourceLoader.getResource("data/ui/xbox/achievementWindow.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		achievementsWnd.horizSizing = Center;
		achievementsWnd.vertSizing = Center;
		achievementsWnd.position = new Vector(25, 58);
		achievementsWnd.extent = new Vector(600, 480);
		innerCtrl.addChild(achievementsWnd);

		var selectedIdx = -1;

		var replayList = [];
		sys.FileSystem.createDirectory(haxe.io.Path.join([Settings.settingsDir, "data", "replays"]));
		var replayPath = haxe.io.Path.join([Settings.settingsDir, "data", "replays",]);
		#if (sys && !android)
		var replayFiles = ResourceLoader.fileSystem.dir(replayPath);
		for (replayFile in replayFiles) {
			if (replayFile.extension == "mbr") {
				var replayF = new Replay(null);
				if (replayF.readHeader(replayFile.getBytes(), replayFile))
					replayList.push(replayF);
			}
		}
		#end
		// #if android
		var replayFiles = sys.FileSystem.readDirectory(replayPath);
		for (replayFile in replayFiles) {
			var extension = haxe.io.Path.extension(replayFile);
			trace('Replay file: ${replayFile}}');
			if (extension == "mbr") {
				var replayF = new Replay(null);
				var fullpath = haxe.io.Path.join([Settings.settingsDir, "data", "replays", replayFile]);
				trace('Replay file path: ${fullpath}}');
				var replayBytes = sys.io.File.getBytes(fullpath);
				var fe = new BytesFileEntry(fullpath, replayBytes);
				if (replayF.readHeader(replayBytes, fe))
					replayList.push(replayF);
			}
		}
		// #end

		var scrollCtrl = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/osxscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		scrollCtrl.position = new Vector(25, 22);
		scrollCtrl.extent = new Vector(550, 280);
		achievementsWnd.addChild(scrollCtrl);

		var replayListCtrl = new GuiTextListCtrl(arial14, replayList.map(x -> x.name));

		replayListCtrl.selectedColor = 0xF29515;
		replayListCtrl.selectedFillColor = 0xEBEBEB;
		replayListCtrl.position = new Vector(0, 0);
		replayListCtrl.extent = new Vector(550, 480);
		replayListCtrl.scrollable = true;
		replayListCtrl.onSelectedFunc = (sel) -> {
			selectedIdx = sel;
		}
		scrollCtrl.addChild(replayListCtrl);
		scrollCtrl.setScrollMax(replayListCtrl.calculateFullHeight());

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
		backButton.pressedAction = (e) -> MarbleGame.canvas.setContent(new MainMenuGui());
		bottomBar.addChild(backButton);

		var nextButton = new GuiXboxButton("Play", 160);
		nextButton.position = new Vector(960, 0);
		nextButton.vertSizing = Bottom;
		nextButton.horizSizing = Right;
		nextButton.pressedAction = (e) -> {
			if (selectedIdx != -1) {
				var repl = replayList[selectedIdx];
				if (repl.readFull()) {
					var repmis = repl.mission;
					if (!StringTools.contains(repmis, "data/"))
						repmis = "data/" + repmis;
					#if android
					repmis = StringTools.replace(repmis, "data/", "");
					#end
					var mi = repl.customId == 0 ? MissionList.missions.get(repmis) : Marbleland.missions.get(repl.customId);
					if (mi.isClaMission) {
						mi.download(() -> {
							MarbleGame.instance.watchMissionReplay(mi, repl);
						});
					} else {
						MarbleGame.instance.watchMissionReplay(mi, repl);
					}
				}
			}
		};
		bottomBar.addChild(nextButton);

		// var playButton = new GuiButton(loadButtonImages('data/ui/replay/play', true));
		// playButton.position = new Vector(323, 386);
		// playButton.extent = new Vector(94, 46);
		// playButton.disabled = true;
		// playButton.pressedAction = (e) -> {
		// 	var repl = replayList[selectedIdx];
		// 	if (repl.readFull()) {
		// 		var repmis = repl.mission;
		// 		if (!StringTools.contains(repmis, "data/"))
		// 			repmis = "data/" + repmis;
		// 		var mi = repl.customId == 0 ? MissionList.missions.get(repmis) : Marbleland.missions.get(repl.customId);
		// 		if (mi.isClaMission) {
		// 			mi.download(() -> {
		// 				MarbleGame.instance.watchMissionReplay(mi, repl);
		// 			});
		// 			playButton.disabled = true; // Don't let us play anything else
		// 		} else {
		// 			MarbleGame.instance.watchMissionReplay(mi, repl);
		// 		}
		// 	}
		// }
		// wnd.addChild(playButton);

		// var homeButton = new GuiButton(loadButtonImages('data/ui/replay/home'));
		// homeButton.position = new Vector(224, 386);
		// homeButton.extent = new Vector(94, 46);
		// homeButton.pressedAction = (e) -> {
		// 	MarbleGame.canvas.setContent(new MainMenuGui());
		// }
		// wnd.addChild(homeButton);

		// var scrollCtrl = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		// scrollCtrl.position = new Vector(30, 25);
		// scrollCtrl.extent = new Vector(283, 346);
		// scrollCtrl.childrenHandleScroll = true;
		// wnd.addChild(scrollCtrl);

		// var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		// var arial14b = new BitmapFont(arial14fontdata.entry);
		// @:privateAccess arial14b.loader = ResourceLoader.loader;
		// var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);
		// var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		// var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		// @:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		// var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		// var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		// var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		// var missionName = new GuiText(markerFelt24);
		// missionName.position = new Vector(327, 181);
		// missionName.extent = new Vector(278, 14);
		// missionName.text.textColor = 0;
		// missionName.justify = Center;
		// wnd.addChild(missionName);

		// var replayListBox = new GuiTextListCtrl(markerFelt24, replayList.map(x -> x.name));
		// replayListBox.position = new Vector(0, 0);
		// replayListBox.extent = new Vector(283, 346);
		// replayListBox.textYOffset = -6;
		// replayListBox.scrollable = true;
		// replayListBox.onSelectedFunc = (idx) -> {
		// 	if (idx < 0)
		// 		return;
		// 	selectedIdx = idx;
		// 	playButton.disabled = false;
		// 	var thisReplay = replayList[idx];
		// 	var repmis = thisReplay.mission;
		// 	if (!StringTools.contains(repmis, "data/"))
		// 		repmis = "data/" + repmis;
		// 	if (MissionList.missions == null)
		// 		MissionList.buildMissionList();
		// 	var m = thisReplay.customId == 0 ? MissionList.missions.get(repmis) : Marbleland.missions.get(thisReplay.customId);
		// 	missionName.text.text = m.title;
		// 	m.getPreviewImage((t) -> {
		// 		pmPreview.bmp.tile = t;
		// 	});
		// }
		// scrollCtrl.addChild(replayListBox);
		// scrollCtrl.setScrollMax(replayListBox.calculateFullHeight());

		// var replayFrame = new GuiImage(ResourceLoader.getResource("data/ui/replay/replayframe.png", ResourceLoader.getImage, this.imageResources).toTile());
		// replayFrame.position = new Vector(351, 21);
		// replayFrame.extent = new Vector(234, 168);
		// wnd.addChild(replayFrame);
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
