package gui;

import h2d.filter.DropShadow;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.AudioManager;

class JukeboxDlg extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/jukebox/window.png");
		super(img.resource.toTile());

		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(39, 35);
		this.extent = new Vector(541, 409);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

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

		var currentPlayingSong = StringTools.replace(AudioManager.currentMusicName, ".ogg", "");
		selectedIdx = songList.indexOf(currentPlayingSong);

		var songTitle = new GuiMLText(markerFelt24, null);
		songTitle.position = new Vector(61, 262);
		songTitle.extent = new Vector(416, 22);
		songTitle.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		songTitle.text.textColor = 0xFFFFFF;
		songTitle.text.text = '<p align="center">Title: ${songList[selectedIdx]}</p>';
		this.addChild(songTitle);

		var songStatus = new GuiMLText(markerFelt24, null);
		songStatus.position = new Vector(56, 283);
		songStatus.extent = new Vector(421, 22);
		songStatus.text.dropShadow = {
			dx: 1,
			dy: 1,
			alpha: 0.5,
			color: 0
		};
		songStatus.text.textColor = 0xFFFFFF;
		songStatus.text.text = '<p align="center">${playing ? "Playing" : "Stopped"}</p>';
		this.addChild(songStatus);

		var scroll = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		scroll.position = new Vector(51, 39);
		scroll.extent = new Vector(439, 216);
		scroll.childrenHandleScroll = true;
		this.addChild(scroll);

		var songCtrl = new GuiTextListCtrl(markerFelt24, songList);
		songCtrl.position = new Vector(0, 0);
		songCtrl.extent = new Vector(423, 456);
		songCtrl.scrollable = true;
		songCtrl.textYOffset = -6;
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

		var stopBtn = new GuiButton(loadButtonImages("data/ui/jukebox/stop"));
		stopBtn.position = new Vector(219, 306);
		stopBtn.extent = new Vector(96, 45);
		this.addChild(stopBtn);

		var playBtn = new GuiButton(loadButtonImages("data/ui/jukebox/play"));
		playBtn.position = new Vector(219, 306);
		playBtn.extent = new Vector(96, 45);

		stopBtn.pressedAction = (e) -> {
			this.removeChild(stopBtn);
			this.addChild(playBtn);
			playBtn.render(MarbleGame.canvas.scene2d, @:privateAccess playBtn.parent._flow);
			playing = false;
			songStatus.text.text = '<p align="center">${playing ? "Playing" : "Stopped"}</p>';
			AudioManager.pauseMusic(true);
		};

		playBtn.pressedAction = (e) -> {
			this.removeChild(playBtn);
			this.addChild(stopBtn);
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

		var prevBtn = new GuiButton(loadButtonImages("data/ui/play/prev"));
		prevBtn.position = new Vector(145, 307);
		prevBtn.extent = new Vector(72, 43);
		prevBtn.pressedAction = (e) -> {
			if (selectedIdx >= 1) {
				setCurrentSong(selectedIdx - 1);
			} else {
				setCurrentSong(songList.length - 1);
			}
		}
		this.addChild(prevBtn);

		var nextBtn = new GuiButton(loadButtonImages("data/ui/play/next"));
		nextBtn.position = new Vector(317, 307);
		nextBtn.extent = new Vector(72, 43);
		nextBtn.pressedAction = (e) -> {
			if (selectedIdx < songList.length - 1) {
				setCurrentSong(selectedIdx + 1);
			} else {
				setCurrentSong(0);
			}
		}
		this.addChild(nextBtn);

		var closeBtn = new GuiButton(loadButtonImages("data/ui/jukebox/close"));
		closeBtn.position = new Vector(47, 307);
		closeBtn.extent = new Vector(94, 45);
		closeBtn.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(closeBtn);
	}
}
