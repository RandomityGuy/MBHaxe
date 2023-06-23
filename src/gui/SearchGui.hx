package gui;

import src.Marbleland;
import h2d.Tile;
import hxd.BitmapData;
import src.MarbleGame;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.MissionList;

class SearchGui extends GuiImage {
	public function new(game:String, isCustom:Bool) {
		var img = ResourceLoader.getImage("data/ui/search/window.png");
		super(img.resource.toTile());

		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(76, 8);
		this.extent = new Vector(487, 463);

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
			var customsList = switch (game) {
				case 'gold':
					Marbleland.goldMissions;
				case 'platinum':
					Marbleland.platinumMissions;
				case 'ultra':
					Marbleland.ultraMissions;
				default:
					MissionList.customMissions;
			};
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
		var scrollCtrl:GuiScrollCtrl = null;

		var currentSortBy = "title";

		function sortBy(type:String, txt:String = "") {
			if (type == "title") {
				retrieveMissionList = missionList.filter(x -> StringTools.contains(x.name.toLowerCase(), txt.toLowerCase()));
				displayList = retrieveMissionList.map(x -> x.name);
				displayList.sort((x, y) -> (x > y) ? 1 : (x == y ? 0 : -1));
				retrieveMissionList.sort((x, y) -> x.name > y.name ? 1 : (x.name == y.name ? 0 : -1));
			}
			if (type == "artist") {
				retrieveMissionList = missionList.filter(x -> StringTools.contains(x.artist.toLowerCase(), txt.toLowerCase()));
				retrieveMissionList.sort((x, y) -> x.artist > y.artist ? 1 : (x.artist == y.artist ? 0 : -1));
				displayList = retrieveMissionList.map(x -> '${x.name} By ${x.artist}');
			}
			if (type == "file") {
				retrieveMissionList = missionList.filter(x -> StringTools.contains(x.path.toLowerCase(), txt.toLowerCase()));
				retrieveMissionList.sort((x, y) -> x.path > y.path ? 1 : (x.path == y.path ? 0 : -1));
				var idxofslash = 0;
				displayList = retrieveMissionList.map(x -> {
					var idxofslash = 0;
					var slashcount = 0;
					for (i in 0...x.path.length) {
						if (x.path.charCodeAt(x.path.length - i - 1) == '/'.code) {
							slashcount++;
							if (slashcount == 2) {
								idxofslash = x.path.length - i - 1;
								break;
							}
						}
					}
					return '${x.path.substr(idxofslash + 1)}';
				});
			}
			searchMissionList.setTexts(displayList);
			scrollCtrl.setScrollMax(searchMissionList.calculateFullHeight());
		}

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabledObj = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources);
			var disabled = disabledObj != null ? disabledObj.toTile() : null;
			return [normal, hover, pressed, disabled];
		}

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var domcasual64 = domcasual32b.toSdfFont(cast 58 * Settings.uiScale, MultiChannel);
		var domcasual24 = domcasual32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		var searchCancel = new GuiButton(loadButtonImages("data/ui/search/cancel"));
		searchCancel.vertSizing = Top;
		searchCancel.position = new Vector(21, 395);
		searchCancel.extent = new Vector(94, 45);
		searchCancel.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(searchCancel);

		var selectedIdx:Int = -1;

		var searchPlay = new GuiButton(loadButtonImages("data/ui/search/play"));
		searchPlay.position = new Vector(370, 395);
		searchPlay.extent = new Vector(94, 45);
		searchPlay.disabled = true;
		searchPlay.pressedAction = (e) -> {
			if (selectedIdx != -1) {
				var mis = retrieveMissionList[selectedIdx];
				cast(this.parent, Canvas).marbleGame.playMission(mis.mis);
			}
		}
		this.addChild(searchPlay);

		var searchTitle = new GuiText(domcasual24);
		searchTitle.position = new Vector(52, 19);
		searchTitle.extent = new Vector(64, 25);
		searchTitle.text.textColor = 0x696969;
		searchTitle.text.text = "Title:";
		this.addChild(searchTitle);

		var searchEdit = new GuiTextInput(domcasual24);
		searchEdit.text.textColor = 0;
		searchEdit.text.selectionColor.setColor(0xFFFFFFFF);
		searchEdit.text.selectionTile = h2d.Tile.fromColor(0x808080, 0, hxd.Math.ceil(searchEdit.text.font.lineHeight));
		searchEdit.position = new Vector(91, 19);
		searchEdit.extent = new Vector(373, 29);
		searchEdit.onTextChange = (txt) -> {
			sortBy(currentSortBy, txt);
		};
		this.addChild(searchEdit);

		scrollCtrl = new GuiScrollCtrl(ResourceLoader.getResource("data/ui/common/philscroll.png", ResourceLoader.getImage, this.imageResources).toTile());
		scrollCtrl.position = new Vector(19, 65);
		scrollCtrl.extent = new Vector(447, 317);
		this.addChild(scrollCtrl);

		searchMissionList = new GuiTextListCtrl(markerFelt24, displayList);
		searchMissionList.selectedColor = 0;
		searchMissionList.horizSizing = Width;
		searchMissionList.position = new Vector(4, -1);
		searchMissionList.extent = new Vector(432, 2880);
		searchMissionList.textYOffset = -6;
		searchMissionList.scrollable = true;
		searchMissionList.onSelectedFunc = (sel) -> {
			selectedIdx = sel;
			if (retrieveMissionList.length <= selectedIdx || selectedIdx < 0) {
				searchPlay.disabled = true;
			} else {
				searchPlay.disabled = false;
			}
		}
		scrollCtrl.addChild(searchMissionList);
		scrollCtrl.setScrollMax(searchMissionList.calculateFullHeight());

		var optionsPopup:GuiButton = null;

		var searchOptions = new GuiButton(loadButtonImages("data/ui/search/options"));
		searchOptions.vertSizing = Top;
		searchOptions.horizSizing = Right;
		searchOptions.position = new Vector(121, 395);
		searchOptions.extent = new Vector(94, 45);
		searchOptions.pressedAction = (e) -> {
			MarbleGame.canvas.pushDialog(optionsPopup);
		}
		this.addChild(searchOptions);

		var temprev = new BitmapData(1, 1);
		temprev.setPixel(0, 0, 0);
		var tmpprevtile = Tile.fromBitmap(temprev);

		optionsPopup = new GuiButton([tmpprevtile, tmpprevtile, tmpprevtile]);
		optionsPopup.horizSizing = Width;
		optionsPopup.vertSizing = Height;
		optionsPopup.position = new Vector(0, 0);
		optionsPopup.extent = new Vector(640, 480);
		optionsPopup.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(optionsPopup, false);
		}

		var optionsPopupInner = new GuiControl();
		optionsPopupInner.horizSizing = Center;
		optionsPopupInner.vertSizing = Center;
		optionsPopupInner.position = new Vector(80, 7);
		optionsPopupInner.extent = new Vector(480, 465);
		optionsPopup.addChild(optionsPopupInner);

		var optionsBgR = ResourceLoader.getResource('data/ui/search/more.png', ResourceLoader.getImage, this.imageResources).toTile();

		var optionsBg = new GuiImage(optionsBgR);
		optionsBg.position = new Vector(0, 281);
		optionsBg.extent = new Vector(348, 148);
		optionsPopupInner.addChild(optionsBg);

		var searchByFile = new GuiButton(loadButtonImages("data/ui/search/file"));
		searchByFile.buttonType = Radio;
		searchByFile.position = new Vector(229, 32);
		searchByFile.extent = new Vector(68, 45);
		searchByFile.pressedAction = (e) -> {
			searchTitle.text.text = "File:";
			currentSortBy = "file";
			sortBy("file");
		};
		optionsBg.addChild(searchByFile);

		var searchByartist = new GuiButton(loadButtonImages("data/ui/search/artist"));
		searchByartist.buttonType = Radio;
		searchByartist.position = new Vector(159, 32);
		searchByartist.extent = new Vector(72, 45);
		searchByartist.pressedAction = (e) -> {
			searchTitle.text.text = "Artist:";
			currentSortBy = "artist";
			sortBy("artist");
		};
		optionsBg.addChild(searchByartist);

		var searchByTitle = new GuiButton(loadButtonImages("data/ui/search/name"));
		searchByTitle.buttonType = Radio;
		searchByTitle.position = new Vector(92, 32);
		searchByTitle.extent = new Vector(68, 45);
		searchByTitle.pressed = true;
		searchByTitle.pressedAction = (e) -> {
			searchTitle.text.text = "Title:";
			currentSortBy = "title";
			sortBy("title");
		};
		optionsBg.addChild(searchByTitle);

		var searchRandom = new GuiButton(loadButtonImages("data/ui/search/random"));
		searchRandom.vertSizing = Top;
		searchRandom.position = new Vector(44, 32);
		searchRandom.extent = new Vector(44, 44);
		searchRandom.pressedAction = (e) -> {
			var mis = missionList[Math.floor(Math.random() * missionList.length)];
			cast(this.parent, Canvas).marbleGame.playMission(mis.mis);
		}
		optionsBg.addChild(searchRandom);
	}
}
