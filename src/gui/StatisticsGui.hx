package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Settings.PlayStatistics;
import src.Mission;
import src.Util;

class StatisticsGui extends GuiImage {
	public function new(game:String) {
		var img = ResourceLoader.getImage("data/ui/achiev/window.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(73, -21);
		this.extent = new Vector(493, 512);

		var stat = new GuiImage(ResourceLoader.getResource("data/ui/play/statistics_text.png", ResourceLoader.getImage, this.imageResources).toTile());
		stat.position = new Vector(176, 25);
		stat.extent = new Vector(160, 39);
		this.addChild(stat);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var domcasual64 = domcasual32b.toSdfFont(cast 58 * Settings.uiScale, MultiChannel);
		var domcasual24 = domcasual32b.toSdfFont(cast 21 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual24":
					return domcasual24;
				case "Arial14":
					return arial14;
				default:
					return null;
			}
		}

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var statLabel = new GuiMLText(domcasual24, mlFontLoader);
		statLabel.position = new Vector(39, 51);
		statLabel.extent = new Vector(341, 375);
		statLabel.text.textColor = 0;
		statLabel.text.lineSpacing = 4;
		this.addChild(statLabel);

		var statText = new GuiMLText(domcasual24, mlFontLoader);
		statText.position = new Vector(59, 54);
		statText.extent = new Vector(389, 375);
		statText.horizSizing = Left;
		statText.text.textColor = 0;
		statText.text.lineSpacing = 4;

		if (game == "platinum") {
			statLabel.text.text = "Beginner:<br/>" + "Intermediate:<br/>" + "Advanced:<br/>" + "Expert:<br/>" + "Total:<br/>" + "<br/>"
				+ "Platinum times:<br/>" + "Ultimate times:<br/>" + "Easter Eggs:<br/>" + "Out of Bounds:<br/>" + "Respawns:<br/>" + "Hardest Level:<br/>"
				+ "<br/>" + "Grand Total (hours:minutes:seconds):<br/>" + "Total Wasted Time (hours:minutes:seconds):<br/>";
		}
		if (game == "gold") {
			statLabel.text.text = "Beginner:<br/>" + "Intermediate:<br/>" + "Advanced:<br/>" + "Total:<br/>" + "<br/>" + "Gold times:<br/>"
				+ "Out of Bounds:<br/>" + "Respawns:<br/>" + "Hardest Level:<br/>" + "<br/>" + "Grand Total (hours:minutes:seconds):<br/>"
				+ "Total Wasted Time (hours:minutes:seconds):";
		}
		if (game == "ultra") {
			statLabel.text.text = "Beginner:<br/>" + "Intermediate:<br/>" + "Advanced:<br/>" + "Total:<br/>" + "<br/>" + "Gold times:<br/>"
				+ "Ultimate times:<br/>" + "Easter Eggs:<br/>" + "Out of Bounds:<br/>" + "Respawns:<br/>" + "Hardest Level:<br/>" + "<br/>"
				+ "Grand Total (hours:minutes:seconds):<br/>" + "Total Wasted Time (hours:minutes:seconds):<br/>";
		}

		this.addChild(statText);

		var closeButton = new GuiButton(loadButtonImages("data/ui/achiev/close"));
		closeButton.position = new Vector(199, 431);
		closeButton.extent = new Vector(95, 45);
		closeButton.horizSizing = Center;
		closeButton.pressedAction = (e) -> {
			MarbleGame.canvas.popDialog(this);
		}
		this.addChild(closeButton);

		// Now do the actual achievement check logic
		var completions:Map<String, Array<{
			mission:Mission,
			beatPar:Bool,
			beatPlatinum:Bool,
			beatUltimate:Bool,
			beaten:Bool
		}>> = [];

		var totalPlatinums = 0;
		var totalUltimates = 0;
		var totalEggs = 0;
		var totalBestTime = 0.0;
		var hardestLevel:Mission = MissionList.missionList[game]["beginner"][0];
		var hardestStats:PlayStatistics = {
			oobs: 0,
			respawns: 0,
			totalTime: 0
		};
		var hardestLevelScore = 0.0;

		for (difficulty => missions in MissionList.missionList[game]) {
			completions.set(difficulty, missions.map(mis -> {
				var misScores = Settings.getScores(mis.path);
				if (misScores.length == 0) {
					return {
						mission: mis,
						beatPar: false,
						beatPlatinum: false,
						beatUltimate: false,
						beaten: false
					}
				}
				var bestTime = misScores[0];
				totalBestTime += bestTime.time;
				var beatPar = bestTime.time < mis.qualifyTime;
				var beatPlatinum = bestTime.time < mis.goldTime;
				var beatUltimate = bestTime.time < mis.ultimateTime;
				var beaten = beatPar || beatPlatinum || beatUltimate;

				if (beatPlatinum)
					totalPlatinums++;
				if (beatUltimate)
					totalUltimates++;
				if (Settings.easterEggs.exists(mis.path))
					totalEggs++;

				if (Settings.levelStatistics.exists(mis.path)) {
					var stats = Settings.levelStatistics.get(mis.path);
					var metric = stats.oobs + stats.respawns + (stats.totalTime / 60);
					if (metric > hardestLevelScore) {
						hardestLevel = mis;
						hardestLevelScore = metric;
						hardestStats = stats;
					}
				}

				return {
					mission: mis,
					beatPar: beatPar,
					beatPlatinum: beatPlatinum,
					beatUltimate: beatUltimate,
					beaten: beaten
				};
			}));
		}

		if (game == "platinum") {
			var beginnerCompletion = completions["beginner"].filter(x -> x.beatPar).length / completions["beginner"].length;
			var intermediateCompletion = completions["intermediate"].filter(x -> x.beatPar).length / completions["intermediate"].length;
			var advancedCompletion = completions["advanced"].filter(x -> x.beatPar).length / completions["advanced"].length;
			var expertCompletion = completions["expert"].filter(x -> x.beatPar).length / completions["expert"].length;
			var totalCompletion:Float = completions["beginner"].filter(x -> x.beatPar).length
				+ completions["intermediate"].filter(x -> x.beatPar)
					.length + completions["advanced"].filter(x -> x.beatPar).length + completions["expert"].filter(x -> x.beatPar).length;
			totalCompletion /= completions["beginner"].length
				+ completions["intermediate"].length + completions["advanced"].length + completions["expert"].length;

			statText.text.text = '<p align="right">${Math.floor(beginnerCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(intermediateCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(advancedCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(expertCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(totalCompletion * 100)}%</p>'
				+ '<br/>'
				+ '<p align="right">${totalPlatinums}/120		${Math.floor(totalPlatinums / 120.0 * 100)}%</p>'
				+ '<p align="right">${totalUltimates}/120		${Math.floor(totalUltimates / 120.0 * 100)}%</p>'
				+ '<p align="right">${totalEggs}/96		${Math.floor(totalEggs / 96 * 100)}%</p>'
				+ '<p align="right">${Settings.playStatistics.oobs}</p>'
				+ '<p align="right">${Settings.playStatistics.respawns}</p>'
				+ '<p align="right">${hardestLevel != null ? hardestLevel.title : ""}</p>'
				+
				'<p align="right">${hardestLevel != null ? 'With ${hardestStats.oobs} OOBs, ${hardestStats.respawns} Respawns, and ${Util.formatTimeHours(hardestStats.totalTime)} Played': ""}</p>'
				+ '<p align="right">${Util.formatTimeHours(totalBestTime)}</p>'
				+ '<p align="right">${Util.formatTimeHours(Settings.playStatistics.totalTime)}</p>';
		}
		if (game == "gold") {
			var beginnerCompletion = completions["beginner"].filter(x -> x.beatPar).length / completions["beginner"].length;
			var intermediateCompletion = completions["intermediate"].filter(x -> x.beatPar).length / completions["intermediate"].length;
			var advancedCompletion = completions["advanced"].filter(x -> x.beatPar).length / completions["advanced"].length;
			var totalCompletion:Float = completions["beginner"].filter(x -> x.beatPar).length
				+ completions["intermediate"].filter(x -> x.beatPar).length + completions["advanced"].filter(x -> x.beatPar).length;
			totalCompletion /= completions["beginner"].length + completions["intermediate"].length + completions["advanced"].length;

			statText.text.text = '<p align="right">${Math.floor(beginnerCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(intermediateCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(advancedCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(totalCompletion * 100)}%</p>'
				+ '<br/>'
				+ '<p align="right">${totalPlatinums}/100		${Math.floor(totalPlatinums / 100.0 * 100)}%</p>'
				+ '<p align="right">${Settings.playStatistics.oobs}</p>'
				+ '<p align="right">${Settings.playStatistics.respawns}</p>'
				+ '<p align="right">${hardestLevel != null ? hardestLevel.title : ""}</p>'
				+
				'<p align="right">${hardestLevel != null ? 'With ${hardestStats.oobs} OOBs, ${hardestStats.respawns} Respawns, and ${Util.formatTimeHours(hardestStats.totalTime)} Played': ""}</p>'
				+ '<p align="right">${Util.formatTimeHours(totalBestTime)}</p>'
				+ '<p align="right">${Util.formatTimeHours(Settings.playStatistics.totalTime)}</p>';
		}
		if (game == "ultra") {
			var beginnerCompletion = completions["beginner"].filter(x -> x.beatPar).length / completions["beginner"].length;
			var intermediateCompletion = completions["intermediate"].filter(x -> x.beatPar).length / completions["intermediate"].length;
			var advancedCompletion = completions["advanced"].filter(x -> x.beatPar).length / completions["advanced"].length;
			var totalCompletion:Float = completions["beginner"].filter(x -> x.beatPar).length
				+ completions["intermediate"].filter(x -> x.beatPar).length + completions["advanced"].filter(x -> x.beatPar).length;
			totalCompletion /= completions["beginner"].length + completions["intermediate"].length + completions["advanced"].length;

			statText.text.text = '<p align="right">${Math.floor(beginnerCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(intermediateCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(advancedCompletion * 100)}%</p>'
				+ '<p align="right">${Math.floor(totalCompletion * 100)}%</p>'
				+ '<br/>'
				+ '<p align="right">${totalPlatinums}/61		${Math.floor(totalPlatinums / 61.0 * 100)}%</p>'
				+ '<p align="right">${totalUltimates}/61		${Math.floor(totalUltimates / 61.0 * 100)}%</p>'
				+ '<p align="right">${totalEggs}/20		${Math.floor(totalEggs / 20 * 100)}%</p>'
				+ '<p align="right">${Settings.playStatistics.oobs}</p>'
				+ '<p align="right">${Settings.playStatistics.respawns}</p>'
				+ '<p align="right">${hardestLevel != null ? hardestLevel.title : ""}</p>'
				+
				'<p align="right">${hardestLevel != null ? 'With ${hardestStats.oobs} OOBs, ${hardestStats.respawns} Respawns, and ${Util.formatTimeHours(hardestStats.totalTime)} Played': ""}</p>'
				+ '<p align="right">${Util.formatTimeHours(totalBestTime)}</p>'
				+ '<p align="right">${Util.formatTimeHours(Settings.playStatistics.totalTime)}</p>';
		}
	}
}
