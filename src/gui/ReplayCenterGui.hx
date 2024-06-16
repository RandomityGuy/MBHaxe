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
	public function new() {
		function chooseBg() {
			var rand = Math.random();
			if (rand >= 0 && rand <= 0.244)
				return ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
			if (rand > 0.244 && rand <= 0.816)
				return ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg');
			return ResourceLoader.getImage('data/ui/backgrounds/ultra/${cast (Math.floor(Util.lerp(1, 9, Math.random())), Int)}.jpg');
		}
		var img = chooseBg();
		super(img.resource.toTile());

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var wnd = new GuiImage(ResourceLoader.getResource("data/ui/replay/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		wnd.position = new Vector(0, 0);
		wnd.extent = new Vector(640, 480);
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		this.addChild(wnd);

		function loadButtonImages(path:String, hasDisabled:Bool = false) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = hasDisabled ? ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile() : null;
			return [normal, hover, pressed, disabled];
		}

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

		var playButton = new GuiButton(loadButtonImages('data/ui/replay/play', true));
		playButton.position = new Vector(323, 386);
		playButton.extent = new Vector(94, 46);
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
						MarbleGame.instance.watchMissionReplay(mi, repl);
					});
					playButton.disabled = true; // Don't let us play anything else
				} else {
					MarbleGame.instance.watchMissionReplay(mi, repl);
				}
			}
		}
		wnd.addChild(playButton);

		var homeButton = new GuiButton(loadButtonImages('data/ui/replay/home'));
		homeButton.position = new Vector(224, 386);
		homeButton.extent = new Vector(94, 46);
		homeButton.pressedAction = (e) -> {
			MarbleGame.canvas.setContent(new MainMenuGui());
		}
		wnd.addChild(homeButton);

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = h2d.Tile.fromBitmap(temprev);

		var pmPreview = new GuiImage(tmpprevtile);
		pmPreview.position = new Vector(360, 29);
		pmPreview.extent = new Vector(216, 150);
		wnd.addChild(pmPreview);

		var scrollCtrl = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		scrollCtrl.position = new Vector(30, 25);
		scrollCtrl.extent = new Vector(283, 346);
		wnd.addChild(scrollCtrl);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);
		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		var missionName = new GuiText(markerFelt24);
		missionName.position = new Vector(327, 181);
		missionName.extent = new Vector(278, 14);
		missionName.text.textColor = 0;
		missionName.justify = Center;
		wnd.addChild(missionName);

		var replayListBox = new GuiTextListCtrl(markerFelt24, replayList.map(x -> x.name));
		replayListBox.position = new Vector(0, 0);
		replayListBox.extent = new Vector(283, 346);
		replayListBox.textYOffset = -6;
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
			missionName.text.text = m.title;
			m.getPreviewImage((t) -> {
				pmPreview.bmp.tile = t;
			});
		}
		scrollCtrl.addChild(replayListBox);
		scrollCtrl.setScrollMax(replayListBox.calculateFullHeight());

		var replayFrame = new GuiImage(ResourceLoader.getResource("data/ui/replay/replayframe.png", ResourceLoader.getImage, this.imageResources).toTile());
		replayFrame.position = new Vector(351, 21);
		replayFrame.extent = new Vector(234, 168);
		wnd.addChild(replayFrame);
	}
}
