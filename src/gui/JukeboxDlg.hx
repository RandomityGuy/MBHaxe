package gui;

import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.AudioManager;

class JukeboxDlg extends GuiControl {
	public function new() {
		super();

		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(0, 0);
		this.extent = new Vector(800, 600);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(57, 61);
		wnd.extent = new Vector(524, 357);
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

		#if hl
		var songPath = "data/sound/music";
		#end
		#if js
		var songPath = "sound/music";
		#end
		var songFiles = ResourceLoader.fileSystem.dir(songPath);
		var songList = songFiles.map(x -> StringTools.replace(x.name, ".ogg", ""));

		var playing:Bool = !AudioManager.currentMusicPaused;
		var selectedIdx:Int = 0;

		var currentPlayingSong = StringTools.replace(AudioManager.currentMusicName, ".ogg", "").toLowerCase();
		for (i in 0...songList.length)
			if (songList[i].toLowerCase() == currentPlayingSong) {
				selectedIdx = i;
				break;
			}

		var songTitle = new GuiMLText(squishneyFont28, null);
		songTitle.position = new Vector(54, 224);
		songTitle.extent = new Vector(416, 32);
		songTitle.horizSizing = Center;
		songTitle.text.textColor = 0;
		songTitle.text.text = '<p align="center">Title: ${songList[selectedIdx]}</p>';
		wnd.addChild(songTitle);

		var songStatus = new GuiMLText(whatneyFont, null);
		songStatus.horizSizing = Center;
		songStatus.position = new Vector(51, 253);
		songStatus.extent = new Vector(421, 27);
		songStatus.text.textColor = 0;
		songStatus.text.text = '<p align="center">${playing ? "Playing" : "Stopped"}</p>';
		wnd.addChild(songStatus);

		var panel = new GuiTransparencyCtrl("data/ui/transparency/75square");
		panel.position = new Vector(22, 22);
		panel.extent = new Vector(480, 197);
		wnd.addChild(panel);

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
		scroll.position = new Vector(13, 13);
		scroll.extent = new Vector(454, 171);
		// scroll.childrenHandleScroll = true;
		scroll.horizSizing = Width;
		scroll.vertSizing = Height;
		panel.addChild(scroll);

		var songCtrl = new GuiTextListCtrl(whatneyFont14, songList);
		songCtrl.position = new Vector(2, 0);
		songCtrl.extent = new Vector(434, 651);
		songCtrl.scrollable = true;
		songCtrl.textYOffset = 0;
		songCtrl.selectedColor = 0;
		songCtrl._prevSelected = selectedIdx;
		scroll.addChild(songCtrl);
		scroll.setScrollMax(songCtrl.calculateFullHeight());

		function setCurrentSong(idx:Int) {
			selectedIdx = idx;
			songCtrl._prevSelected = idx;
			songTitle.text.text = '<p align="center">Title: ${songList[idx]}</p>';
			songCtrl.redrawSelectionRect(songCtrl.getHitTestRect());

			if (playing) {
				songFiles[idx].load(() -> {
					var audiores = ResourceLoader.getAudio(songFiles[idx].path).resource;
					AudioManager.playMusic(audiores, songList[idx]);
				});
			}
		}

		songCtrl.onSelectedFunc = (idx) -> {
			setCurrentSong(idx);
		};

		var stopBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		stopBtn.position = new Vector(216, 285);
		stopBtn.setExtent(new Vector(94, 45));
		stopBtn.vertSizing = Top;
		stopBtn.horizSizing = Right;
		stopBtn.txtCtrl.text.text = "Stop";
		if (playing)
			wnd.addChild(stopBtn);

		var playBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		playBtn.position = new Vector(215, 285);
		playBtn.setExtent(new Vector(94, 45));
		playBtn.vertSizing = Top;
		playBtn.horizSizing = Center;
		playBtn.txtCtrl.text.text = "Play";
		if (!playing)
			wnd.addChild(playBtn);

		stopBtn.pressedAction = (e) -> {
			wnd.removeChild(stopBtn);
			wnd.addChild(playBtn);
			playBtn.render(MarbleGame.canvas.scene2d, @:privateAccess playBtn.parent._flow);
			playing = false;
			songStatus.text.text = '<p align="center">${playing ? "Playing" : "Stopped"}</p>';
			AudioManager.pauseMusic(true);
		};

		playBtn.pressedAction = (e) -> {
			wnd.removeChild(playBtn);
			wnd.addChild(stopBtn);
			stopBtn.render(MarbleGame.canvas.scene2d, @:privateAccess stopBtn.parent._flow);
			playing = true;
			songStatus.text.text = '<p align="center">${playing ? "Playing" : "Stopped"}</p>';
			if (AudioManager.currentMusicName != songList[selectedIdx]) {
				songFiles[selectedIdx].load(() -> {
					var audiores = ResourceLoader.getAudio(songFiles[selectedIdx].path).resource;
					AudioManager.playMusic(audiores, songList[selectedIdx]);
				});
			} else {
				AudioManager.pauseMusic(false);
			}
		};

		var prevBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		prevBtn.position = new Vector(121, 285);
		prevBtn.setExtent(new Vector(94, 45));
		prevBtn.vertSizing = Top;
		prevBtn.horizSizing = Right;
		prevBtn.txtCtrl.text.text = "Prev";
		prevBtn.pressedAction = (e) -> {
			if (selectedIdx >= 1) {
				setCurrentSong(selectedIdx - 1);
			} else {
				setCurrentSong(songList.length - 1);
			}
		}
		wnd.addChild(prevBtn);

		var nextBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		nextBtn.position = new Vector(309, 285);
		nextBtn.setExtent(new Vector(94, 45));
		nextBtn.vertSizing = Top;
		nextBtn.horizSizing = Right;
		nextBtn.txtCtrl.text.text = "Next";
		nextBtn.pressedAction = (e) -> {
			if (selectedIdx < songList.length - 1) {
				setCurrentSong(selectedIdx + 1);
			} else {
				setCurrentSong(0);
			}
		}
		wnd.addChild(nextBtn);

		var closeBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		closeBtn.position = new Vector(27, 285);
		closeBtn.setExtent(new Vector(94, 45));
		closeBtn.vertSizing = Top;
		closeBtn.horizSizing = Right;
		closeBtn.txtCtrl.text.text = "Close";
		closeBtn.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		wnd.addChild(closeBtn);
	}
}
