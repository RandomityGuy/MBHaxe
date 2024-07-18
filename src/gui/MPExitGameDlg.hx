package gui;

import net.NetCommands;
import h2d.filter.DropShadow;
import net.Net;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import hxd.Key;

class MPExitGameDlg extends GuiControl {
	public function new(resumeFunc:() -> Void, exitFunc:() -> Void) {
		super();

		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		function loadButtonImagesExt(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var dialogImg = new GuiImage(ResourceLoader.getResource("data/ui/mp/team/teamjoin.png", ResourceLoader.getImage, this.imageResources).toTile());
		dialogImg.horizSizing = Center;
		dialogImg.vertSizing = Center;
		dialogImg.position = new Vector(146, 115);
		dialogImg.extent = new Vector(347, 250);
		this.addChild(dialogImg);

		var partialRestart = new GuiButton(loadButtonImagesExt("data/ui/mp/exit/partial"));
		partialRestart.position = new Vector(133, 80);
		partialRestart.extent = new Vector(94, 45);
		partialRestart.vertSizing = Top;
		partialRestart.pressedAction = (e) -> {
			MarbleGame.instance.paused = false;
			NetCommands.partialRestartGame();
			MarbleGame.canvas.popDialog(this);
		}
		dialogImg.addChild(partialRestart);
		if (!Net.isHost) {
			partialRestart.disabled = true;
		}

		var disconnectBtn = new GuiButton(Net.isHost ? loadButtonImages("data/ui/mp/exit/levelselect") : loadButtonImages("data/ui/mp/exit/disconnect"));
		disconnectBtn.position = new Vector(22, 132);
		disconnectBtn.extent = new Vector(114, 45);
		disconnectBtn.vertSizing = Top;
		disconnectBtn.pressedAction = (e) -> exitFunc();
		dialogImg.addChild(disconnectBtn);

		var resumeBtn = new GuiButton(loadButtonImages("data/ui/mp/exit/resume"));
		resumeBtn.position = new Vector(133, 132);
		resumeBtn.extent = new Vector(94, 45);
		resumeBtn.vertSizing = Top;
		resumeBtn.pressedAction = (e) -> resumeFunc();
		dialogImg.addChild(resumeBtn);

		var serverSettingsBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/play/settings"));
		serverSettingsBtn.position = new Vector(155, 184);
		serverSettingsBtn.extent = new Vector(45, 45);
		serverSettingsBtn.vertSizing = Top;
		serverSettingsBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MPServerDlg());
		};
		dialogImg.addChild(serverSettingsBtn);
		if (!Net.isHost) {
			serverSettingsBtn.disabled = true;
		}

		var kickBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/play/kick"));
		kickBtn.position = new Vector(68, 184);
		kickBtn.extent = new Vector(45, 45);
		kickBtn.vertSizing = Top;
		kickBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new MPKickBanDlg());
		}
		dialogImg.addChild(kickBtn);
		if (!Net.isHost) {
			kickBtn.disabled = true;
		}

		var optionsBtn = new GuiButton(loadButtonImagesExt("data/ui/mp/play/playersettings"));
		optionsBtn.position = new Vector(242, 184);
		optionsBtn.extent = new Vector(45, 45);
		optionsBtn.vertSizing = Top;
		optionsBtn.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new OptionsDlg(true));
		}
		dialogImg.addChild(optionsBtn);

		var quickspawnBtn = new GuiButton(loadButtonImages("data/ui/mp/exit/respawn"));
		quickspawnBtn.position = new Vector(224, 132);
		quickspawnBtn.extent = new Vector(104, 45);
		quickspawnBtn.vertSizing = Top;
		quickspawnBtn.pressedAction = (e) -> {
			MarbleGame.instance.paused = false;
			@:privateAccess Key.keyPressed[Settings.controlsSettings.respawn] = Key.getFrame() - 1; // jank
			MarbleGame.canvas.popDialog(this);
		}
		dialogImg.addChild(quickspawnBtn);

		var completeRestart = new GuiButton(loadButtonImagesExt("data/ui/mp/exit/complete"));
		completeRestart.position = new Vector(224, 80);
		completeRestart.extent = new Vector(104, 45);
		completeRestart.vertSizing = Top;
		completeRestart.pressedAction = (e) -> {
			MarbleGame.instance.paused = false;
			NetCommands.completeRestartGame();
			MarbleGame.canvas.popDialog(this);
		}
		dialogImg.addChild(completeRestart);
		if (!Net.isHost) {
			completeRestart.disabled = true;
		}

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt38 = markerFelt32b.toSdfFont(cast 31 * Settings.uiScale, MultiChannel);

		var exitTitle = new GuiText(markerFelt38);
		exitTitle.position = new Vector(8, 28);
		exitTitle.extent = new Vector(331, 30);
		exitTitle.justify = Center;
		exitTitle.text.text = "Ingame Options";
		exitTitle.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		dialogImg.addChild(exitTitle);

		var restartTitle = new GuiText(markerFelt32);
		restartTitle.position = new Vector(20, 88);
		restartTitle.extent = new Vector(114, 14);
		restartTitle.justify = Center;
		restartTitle.text.text = "Restart:";
		restartTitle.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		};
		dialogImg.addChild(restartTitle);

		var jukeboxButton = new GuiButton(loadButtonImages("data/ui/jukebox/jb_pausemenu"));
		jukeboxButton.vertSizing = Top;
		jukeboxButton.horizSizing = Left;
		jukeboxButton.position = new Vector(439, 403);
		jukeboxButton.extent = new Vector(187, 65);
		jukeboxButton.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(new JukeboxDlg());
		}

		this.addChild(jukeboxButton);
	}
}
