package gui;

import h2d.filter.DropShadow;
import src.Marbleland;
import h2d.Tile;
import hxd.BitmapData;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.MissionList;

class MPServerDlg extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/mp/settings/serversettings.png");
		super(img.resource.toTile());

		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(100, 17);
		this.extent = new Vector(440, 446);

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
		var markerFelt24 = markerFelt32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);
		var markerFelt20 = markerFelt32b.toSdfFont(cast 18.5 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);
		var markerFelt26 = markerFelt32b.toSdfFont(cast 22 * Settings.uiScale, MultiChannel);

		var cancelBtn = new GuiButton(loadButtonImages("data/ui/mp/join/cancel"));
		cancelBtn.vertSizing = Top;
		cancelBtn.horizSizing = Left;
		cancelBtn.position = new Vector(123, 384);
		cancelBtn.extent = new Vector(94, 45);
		cancelBtn.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(cancelBtn);

		var saveBtn = new GuiButton(loadButtonImages("data/ui/mp/join/save"));
		saveBtn.horizSizing = Left;
		saveBtn.vertSizing = Top;
		saveBtn.position = new Vector(223, 384);
		saveBtn.extent = new Vector(94, 45);
		this.addChild(saveBtn);

		var title = new GuiText(markerFelt32);
		title.text.text = "Server Settings";
		title.text.textColor = 0xFFFFFF;
		title.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		title.justify = Center;
		title.position = new Vector(11, 21);
		title.extent = new Vector(418, 14);
		title.horizSizing = Width;
		this.addChild(title);

		// var showPwdTitle = new GuiText(markerFelt18);
		// showPwdTitle.text.text = "Show Password";
		// showPwdTitle.text.textColor = 0xFFFFFF;
		// showPwdTitle.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		// showPwdTitle.position = new Vector(259, 94);
		// showPwdTitle.extent = new Vector(129, 14);
		// showPwdTitle.horizSizing = Left;
		// this.addChild(showPwdTitle);

		// var showPasswords = new GuiButton(loadButtonImages("data/ui/mp/lb_chkbx"));
		// showPasswords.buttonType = Toggle;
		// showPasswords.horizSizing = Left;
		// showPasswords.position = new Vector(389, 86);
		// showPasswords.extent = new Vector(31, 31);
		// this.addChild(showPasswords);

		var serverSettingsContainer = new GuiControl();
		serverSettingsContainer.vertSizing = Height;
		serverSettingsContainer.horizSizing = Left;
		serverSettingsContainer.position = new Vector(16, 65);
		serverSettingsContainer.extent = new Vector(390, 276);
		this.addChild(serverSettingsContainer);

		var serverName = new GuiText(markerFelt18);
		serverName.text.text = "Server Name:";
		serverName.text.textColor = 0xFFFFFF;
		serverName.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		serverName.position = new Vector(0, 0);
		serverName.extent = new Vector(206, 14);
		serverSettingsContainer.addChild(serverName);

		var serverNameEditBg = new GuiImage(ResourceLoader.getResource("data/ui/mp/settings/inputbg.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		serverNameEditBg.position = new Vector(93, 0);
		serverNameEditBg.extent = new Vector(297, 35);
		serverSettingsContainer.addChild(serverNameEditBg);

		var serverNameEdit = new GuiTextInput(markerFelt18);
		serverNameEdit.position = new Vector(3, 3);
		serverNameEdit.extent = new Vector(291, 29);
		serverNameEdit.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		serverNameEdit.horizSizing = Left;
		serverNameEditBg.addChild(serverNameEdit);

		var password = new GuiText(markerFelt18);
		password.text.text = "Password:";
		password.text.textColor = 0xFFFFFF;
		password.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		password.position = new Vector(0, 39);
		password.extent = new Vector(206, 14);
		serverSettingsContainer.addChild(password);

		var passwordEditBg = new GuiImage(ResourceLoader.getResource("data/ui/mp/settings/inputbg.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		passwordEditBg.position = new Vector(93, 6 + 29);
		passwordEditBg.extent = new Vector(297, 35);
		serverSettingsContainer.addChild(passwordEditBg);

		var passwordEdit = new GuiTextInput(markerFelt18);
		passwordEdit.position = new Vector(3, 3);
		passwordEdit.extent = new Vector(291, 29);
		passwordEdit.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		passwordEdit.horizSizing = Left;
		passwordEditBg.addChild(passwordEdit);

		var serverDescTitle = new GuiText(markerFelt18);
		serverDescTitle.text.text = "Server Info:";
		serverDescTitle.text.textColor = 0xFFFFFF;
		serverDescTitle.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		serverDescTitle.position = new Vector(0, 39 * 2);
		serverDescTitle.extent = new Vector(206, 14);
		serverSettingsContainer.addChild(serverDescTitle);

		var serverDescEditBg = new GuiImage(ResourceLoader.getResource("data/ui/mp/settings/inputbg.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		serverDescEditBg.position = new Vector(0, 39 * 3);
		serverDescEditBg.extent = new Vector(297 + 93, 35);
		serverSettingsContainer.addChild(serverDescEditBg);

		var serverDescEdit = new GuiTextInput(markerFelt18);
		serverDescEdit.position = new Vector(3, 3);
		serverDescEdit.extent = new Vector(291 + 93, 29);
		serverDescEdit.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		serverDescEdit.horizSizing = Left;
		serverDescEditBg.addChild(serverDescEdit);

		var maxPlayers = new GuiText(markerFelt18);
		maxPlayers.text.text = "Max Players: 8";
		maxPlayers.text.textColor = 0xFFFFFF;
		maxPlayers.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		maxPlayers.position = new Vector(0, 39 * 4);
		maxPlayers.extent = new Vector(206, 14);
		serverSettingsContainer.addChild(maxPlayers);

		var playerMinus = new GuiButton(loadButtonImages("data/ui/mp/settings/minus"));
		playerMinus.position = new Vector(331, 9 + 29 * 5);
		playerMinus.extent = new Vector(31, 31);
		playerMinus.pressedAction = (sender) -> {};
		serverSettingsContainer.addChild(playerMinus);

		var playerPlus = new GuiButton(loadButtonImages("data/ui/mp/settings/plus"));
		playerPlus.position = new Vector(359, 9 + 29 * 5);
		playerPlus.extent = new Vector(31, 31);
		playerPlus.pressedAction = (sender) -> {};
		serverSettingsContainer.addChild(playerPlus);

		var forceSpectators = new GuiText(markerFelt18);
		forceSpectators.text.text = "Force Spectators:";
		forceSpectators.text.textColor = 0xFFFFFF;
		forceSpectators.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		forceSpectators.position = new Vector(0, 39 * 5);
		forceSpectators.extent = new Vector(206, 14);
		serverSettingsContainer.addChild(forceSpectators);

		var forceSpectatorsChk = new GuiButton(loadButtonImages("data/ui/mp/lb_chkbx"));
		forceSpectatorsChk.position = new Vector(359, 9 * 2 + 29 * 6 + 2);
		forceSpectatorsChk.extent = new Vector(31, 31);
		forceSpectatorsChk.buttonType = Toggle;
		forceSpectatorsChk.pressedAction = (sender) -> {};
		serverSettingsContainer.addChild(forceSpectatorsChk);

		var quickRespawn = new GuiText(markerFelt18);
		quickRespawn.text.text = "Allow Quick Respawn:";
		quickRespawn.text.textColor = 0xFFFFFF;
		quickRespawn.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
		quickRespawn.position = new Vector(0, 39 * 6);
		quickRespawn.extent = new Vector(206, 14);
		serverSettingsContainer.addChild(quickRespawn);

		var quickRespawnChk = new GuiButton(loadButtonImages("data/ui/mp/lb_chkbx"));
		quickRespawnChk.position = new Vector(359, 9 * 3 + 29 * 7 + 4);
		quickRespawnChk.extent = new Vector(31, 31);
		quickRespawnChk.buttonType = Toggle;
		quickRespawnChk.pressedAction = (sender) -> {};
		serverSettingsContainer.addChild(quickRespawnChk);
	}
}
