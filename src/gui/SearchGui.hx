package gui;

import src.Util;
import src.Marbleland;
import h2d.Tile;
import hxd.BitmapData;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.MissionList;

class SearchGui extends GuiControl {
	public function new(game:String, isCustom:Bool) {
		super();

		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(0, 0);
		this.extent = new Vector(800, 600);

		var wnd = new GuiTransparencyCtrl("data/ui/transparency/pqwindow");
		wnd.horizSizing = Center;
		wnd.vertSizing = Center;
		wnd.position = new Vector(146, 58);
		wnd.extent = new Vector(707, 483);
		this.addChild(wnd);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);
		var whatneyFont16 = whatneyFontB.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);
		var whatneyFont18 = whatneyFontB.toSdfFont(cast 16 * Settings.uiScale, MultiChannel);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel);
		var squishneyFont18 = squishneyFontB.toSdfFont(cast 16 * Settings.uiScale, MultiChannel);
		var squishney20 = squishneyFontB.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);
		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel);

		function mlFontLoader(font:String) {
			switch (font) {
				case "bold20":
					return squishney20;
				case "bold18":
					return squishneyFont18;
				case "font18":
					return whatneyFont18;
				case "font16":
					return whatneyFont16;
			}
			return null;
		}

		var toppanel = new GuiTransparencyCtrl("data/ui/transparency/75square");
		toppanel.position = new Vector(22, 22);
		toppanel.extent = new Vector(413, 55);
		wnd.addChild(toppanel);

		var searchTitle = new GuiMLText(whatneyFont, null);
		searchTitle.text.textColor = 0x696969;
		searchTitle.text.text = "Search:";
		searchTitle.position = new Vector(16, 14);
		searchTitle.extent = new Vector(400, 14);
		toppanel.addChild(searchTitle);

		var searchLevelImage = new GuiImage(ResourceLoader.getResource("data/ui/play/missingicon.png", ResourceLoader.getImage, this.imageResources).toTile());
		searchLevelImage.position = new Vector(435, 67);
		searchLevelImage.extent = new Vector(240, 170);
		wnd.addChild(searchLevelImage);

		var descpanel = new GuiTransparencyCtrl("data/ui/transparency/75square");
		descpanel.position = new Vector(423, 235);
		descpanel.extent = new Vector(262, 181);
		wnd.addChild(descpanel);

		var descScrollCtrl = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/pqscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				top: new Vector(1, 39, 15, 7),
				bottom: new Vector(1, 56, 15, 7),
				fill: new Vector(1, 47, 15, 1),
				topPressed: new Vector(20, 39, 15, 7),
				bottomPressed: new Vector(20, 56, 15, 7),
				fillPressed: new Vector(20, 47, 15, 1),
				track: new Vector(0, 65, 16, 7),
				up: new Vector(0, 1, 16, 16),
				down: new Vector(0, 20, 16, 16),
				upPressed: new Vector(19, 1, 16, 16),
				downPressed: new Vector(19, 20, 16, 16),
				upDisabled: new Vector(38, 1, 16, 16),
				downDisabled: new Vector(38, 20, 16, 16)
			});
		descScrollCtrl.position = new Vector(13, 13);
		descScrollCtrl.extent = new Vector(234, 152);
		descScrollCtrl.horizSizing = Width;
		descScrollCtrl.vertSizing = Height;
		descpanel.addChild(descScrollCtrl);

		var searchLevelDesc = new GuiMLText(squishneyFont18, mlFontLoader);
		searchLevelDesc.text.textColor = 0x000000;
		searchLevelDesc.text.text = "Name";
		searchLevelDesc.text.lineSpacing = 4;
		searchLevelDesc.position = new Vector(2, 2);
		searchLevelDesc.extent = new Vector(213, 14);
		searchLevelDesc.scrollable = true;
		descScrollCtrl.addChild(searchLevelDesc);

		var missionList = [];
		if (!isCustom) {
			for (diff in MissionList.missionList[game]) {
				for (mis in diff) {
					missionList.push({
						mis: mis,
						name: mis.title,
						artist: mis.artist,
						path: mis.path
					});
				}
			}
		} else {
			var customsList = Marbleland.pqMissions;
			for (mis in customsList) {
				missionList.push({
					mis: mis,
					name: mis.title,
					artist: mis.artist,
					path: mis.path
				});
			}
		}

		var displayList = missionList.map(x -> x.name);
		displayList.sort((x, y) -> (x > y) ? 1 : (x == y ? 0 : -1));
		missionList.sort((x, y) -> x.name > y.name ? 1 : (x.name == y.name ? 0 : -1));
		var retrieveMissionList = missionList;

		var searchMissionList:GuiTextListCtrl = null;
		var scrollCtrl:GuiConsoleScrollCtrl = null;

		var currentSortBy = "title";

		function sortBy(type:String, txt:String = "") {
			retrieveMissionList = missionList.filter(x -> StringTools.contains(x.name.toLowerCase(), txt.toLowerCase())
				|| StringTools.contains(x.artist.toLowerCase(), txt.toLowerCase())
				|| StringTools.contains(x.path.toLowerCase(), txt.toLowerCase()));
			displayList = retrieveMissionList.map(x -> x.name);
			displayList.sort((x, y) -> (x > y) ? 1 : (x == y ? 0 : -1));
			retrieveMissionList.sort((x, y) -> x.name > y.name ? 1 : (x.name == y.name ? 0 : -1));
			searchMissionList.setTexts(displayList);
			scrollCtrl.setScrollMax(searchMissionList.calculateFullHeight());
			scrollCtrl.setScrollPercentage(0);
		}

		function setSelectedLevel(idx:Int) {
			var selectedLevel = retrieveMissionList[idx];
			selectedLevel.mis.getPreviewImage(prev -> {
				searchLevelImage.bmp.tile = prev;
			});

			var mis = selectedLevel.mis;
			var descText = '<font face="bold20">${mis.title}</font><br/>';
			descText += '<font face="bold18">Author:</font> ${mis.artist}<br/>';
			descText += '<font face="bold18">Description:</font><br/>';
			descText += '<font face="font16">${mis.description}</font><br/>';
			descText += '<font face="bold18">Has Easter Egg: </font> ${mis.hasEgg ? "Yes" : "No"}<br/>';
			if (mis.qualifyTime != Math.POSITIVE_INFINITY)
				descText += '<font face="bold18">Qualifying Time: </font> ${Util.formatTime(mis.qualifyTime)}<br/>';
			if (mis.goldTime != 0)
				if (mis.game == "gold" || mis.game.toLowerCase() == "ultra")
					descText += '<font face="bold18">Gold Time: </font> ${Util.formatTime(mis.goldTime)}<br/>';
				else
					descText += '<font face="bold18">Platinum Time: </font> ${Util.formatTime(mis.goldTime)}<br/>';
			if (mis.ultimateTime != 0)
				descText += '<font face="bold18">Ultimate Time: </font> ${Util.formatTime(mis.ultimateTime)}<br/>';
			if (mis.qualifyingScore != 0)
				descText += '<font face="bold18">Qualifying Score: </font> ${mis.qualifyingScore}<br/>';
			if (mis.goldScore != 0)
				if (mis.game == "gold" || mis.game.toLowerCase() == "ultra")
					descText += '<font face="bold18">Gold Score: </font> ${mis.goldScore}<br/>';
				else
					descText += '<font face="bold18">Platinum Score: </font> ${mis.goldScore}<br/>';
			if (mis.ultimateScore != 0)
				descText += '<font face="bold18">Ultimate Score: </font> ${mis.ultimateScore}';

			searchLevelDesc.text.text = descText;
			descScrollCtrl.setScrollMax(searchLevelDesc.text.textHeight);
			descScrollCtrl.setScrollPercentage(0);
		}

		var searchCancel = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		searchCancel.position = new Vector(27, 411);
		searchCancel.setExtent(new Vector(94, 45));
		searchCancel.vertSizing = Top;
		searchCancel.horizSizing = Right;
		searchCancel.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		searchCancel.txtCtrl.text.text = "Close";
		wnd.addChild(searchCancel);

		var selectedIdx:Int = -1;

		var searchPlay = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		searchPlay.position = new Vector(428, 411);
		searchPlay.setExtent(new Vector(252, 45));
		searchPlay.vertSizing = Bottom;
		searchPlay.horizSizing = Right;
		searchPlay.pressedAction = (e) -> {
			if (selectedIdx != -1) {
				var mis = retrieveMissionList[selectedIdx];
				cast(this.parent, Canvas).marbleGame.playMission(mis.mis);
			}
		}
		searchPlay.txtCtrl.text.text = "Play";
		wnd.addChild(searchPlay);

		var searchRandom = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		searchRandom.position = new Vector(121, 411);
		searchRandom.setExtent(new Vector(94, 45));
		searchRandom.vertSizing = Top;
		searchRandom.horizSizing = Right;
		searchRandom.pressedAction = (e) -> {
			var mis = missionList[Math.floor(Math.random() * missionList.length)];
			cast(this.parent, Canvas).marbleGame.playMission(mis.mis);
		}
		searchRandom.txtCtrl.text.text = "Random";
		wnd.addChild(searchRandom);

		var searchEdit = new GuiTextInput(whatneyFont);
		searchEdit.text.textColor = 0;
		searchEdit.text.selectionColor.setColor(0xFFFFFFFF);
		searchEdit.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(searchEdit.text.font.lineHeight));
		searchEdit.position = new Vector(81, 12);
		searchEdit.extent = new Vector(369, 31);
		searchEdit.onTextChange = (txt) -> {
			sortBy(currentSortBy, txt);
		};
		toppanel.addChild(searchEdit);

		var listpanel = new GuiTransparencyCtrl("data/ui/transparency/75square");
		listpanel.position = new Vector(22, 55);
		listpanel.extent = new Vector(413, 361);
		wnd.addChild(listpanel);

		var searchHeader = new GuiMLText(squishneyFont18, null);
		searchHeader.text.textColor = 0x000000;
		searchHeader.text.text = "Name";
		searchHeader.position = new Vector(17, 13);
		searchHeader.extent = new Vector(446, 14);
		listpanel.addChild(searchHeader);

		scrollCtrl = new GuiConsoleScrollCtrl(ResourceLoader.getResource("data/ui/common/pqscroll.png", ResourceLoader.getImage, this.imageResources)
			.toTile(), {
				top: new Vector(1, 39, 15, 7),
				bottom: new Vector(1, 56, 15, 7),
				fill: new Vector(1, 47, 15, 1),
				topPressed: new Vector(20, 39, 15, 7),
				bottomPressed: new Vector(20, 56, 15, 7),
				fillPressed: new Vector(20, 47, 15, 1),
				track: new Vector(0, 65, 16, 7),
				up: new Vector(0, 1, 16, 16),
				down: new Vector(0, 20, 16, 16),
				upPressed: new Vector(19, 1, 16, 16),
				downPressed: new Vector(19, 20, 16, 16),
				upDisabled: new Vector(38, 1, 16, 16),
				downDisabled: new Vector(38, 20, 16, 16)
			});
		scrollCtrl.position = new Vector(13, 33);
		scrollCtrl.extent = new Vector(387, 315);
		listpanel.addChild(scrollCtrl);

		searchMissionList = new GuiTextListCtrl(whatneyFont16, displayList);
		searchMissionList.selectedColor = 0;
		searchMissionList.horizSizing = Width;
		searchMissionList.position = new Vector(0, 0);
		searchMissionList.extent = new Vector(421, 2880);
		searchMissionList.scrollable = true;
		searchMissionList.onSelectedFunc = (sel) -> {
			selectedIdx = sel;
			if (retrieveMissionList.length <= selectedIdx || selectedIdx < 0) {
				searchPlay.disabled = true;
			} else {
				searchPlay.disabled = false;
				setSelectedLevel(selectedIdx);
			}
		}
		scrollCtrl.addChild(searchMissionList);
		scrollCtrl.setScrollMax(searchMissionList.calculateFullHeight());
		scrollCtrl.setScrollPercentage(0);
	}
}
