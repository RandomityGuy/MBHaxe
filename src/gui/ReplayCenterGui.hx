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

class ReplayCenterGui extends GuiControl {
	public function new() {
		super();

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(33, 24);
		wnd.extent = new Vector(574, 434);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);
		var whatneyFont14 = whatneyFontB.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);

		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		var selectedIdx = -1;

		var replayList = [];
		sys.FileSystem.createDirectory(haxe.io.Path.join([Settings.settingsDir, "data", "replays"]));
		var replayPath = haxe.io.Path.join([Settings.settingsDir, "data", "replays",]);
		#if (sys && !android && !ios)
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

		var playButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		playButton.position = new Vector(453, 362);
		playButton.setExtent(new Vector(94, 45));
		playButton.txtCtrl.text.text = "Play";
		playButton.disabled = true;
		playButton.pressedAction = (e) -> {
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
						MarbleGame.instance.watchMissionReplay(mi, repl, MainMenuGui);
					});
					playButton.disabled = true; // Don't let us play anything else
				} else {
					MarbleGame.instance.watchMissionReplay(mi, repl, MainMenuGui);
				}
			}
		}
		wnd.addChild(playButton);

		var homeButton = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		homeButton.position = new Vector(27, 362);
		homeButton.setExtent(new Vector(94, 45));
		homeButton.txtCtrl.text.text = "Close";
		homeButton.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		wnd.addChild(homeButton);

		var panelLeft = new GuiTransparencyCtrl("data/ui/transparency/75square");
		panelLeft.position = new Vector(22, 62);
		panelLeft.extent = new Vector(281, 306);
		wnd.addChild(panelLeft);

		var scrollCtrl = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/pqscroll.png", ResourceLoader.getImage, this.imageResources)
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
		scrollCtrl.position = new Vector(13, 13);
		scrollCtrl.extent = new Vector(255, 280);
		scrollCtrl.horizSizing = Width;
		scrollCtrl.vertSizing = Height;

		panelLeft.addChild(scrollCtrl);

		var panelRight = new GuiTransparencyCtrl("data/ui/transparency/75square");
		panelRight.position = new Vector(292, 62);
		panelRight.extent = new Vector(260, 306);
		wnd.addChild(panelRight);

		var missionName = new GuiText(whatneyFont);
		missionName.position = new Vector(15, 15);
		missionName.extent = new Vector(230, 14);
		missionName.text.textColor = 0;
		missionName.justify = Center;
		panelRight.addChild(missionName);

		var replayListBox = new GuiTextListCtrl(whatneyFont14, replayList.map(x -> x.name));
		replayListBox.position = new Vector(0, 0);
		replayListBox.extent = new Vector(239, 700);
		replayListBox.scrollable = true;
		replayListBox.onSelectedFunc = (idx) -> {
			if (idx < 0)
				return;
			selectedIdx = idx;
			playButton.disabled = false;
			var thisReplay = replayList[idx];
			var repmis = thisReplay.mission;
			if (!StringTools.contains(repmis, "data/"))
				repmis = "data/" + repmis;
			#if android
			repmis = StringTools.replace(repmis, "data/", "");
			#end
			if (MissionList.missions == null)
				MissionList.buildMissionList();
			var m = thisReplay.customId == 0 ? MissionList.missions.get(repmis) : Marbleland.missions.get(thisReplay.customId);
			if (m == null)
				missionName.text.text = "Mission: Unknown";
			else
				missionName.text.text = 'Mission: ${m.title}';
		}
		scrollCtrl.addChild(replayListBox);
		scrollCtrl.setScrollMax(replayListBox.calculateFullHeight());
	}
}
