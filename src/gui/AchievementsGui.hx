package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Mission;

class AchievementsGui extends GuiImage {
	public function new() {
		var img = ResourceLoader.getImage("data/ui/achiev/window.png");
		super(img.resource.toTile());
		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(73, -21);
		this.extent = new Vector(493, 512);

		var achiev = new GuiImage(ResourceLoader.getResource("data/ui/achiev/achiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		achiev.position = new Vector(152, 26);
		achiev.extent = new Vector(176, 50);
		this.addChild(achiev);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var domcasual64 = domcasual32b.toSdfFont(cast 58 * Settings.uiScale, MultiChannel);
		var domcasual24 = domcasual32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

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

		var achievText = new GuiMLText(domcasual32, mlFontLoader);
		achievText.position = new Vector(156, 60);
		achievText.extent = new Vector(262, 410);
		achievText.text.textColor = 0;
		achievText.text.text = '<font face="DomCasual24">Amateur Marbler</font><br/><font face="Arial14">Beat all Beginner levels.</font><br/>
<font face="DomCasual24">Experienced Marbler</font><br/><font face="Arial14">Beat all Intermediate levels.</font><br/>
<font face="DomCasual24">Pro Marbler</font><br/><font face="Arial14">Beat all Advanced levels.</font><br/>
<font face="DomCasual24">Skilled Marbler</font><br/><font face="Arial14">Beat all Expert Levels</font><br/>
<font face="DomCasual24">Marble Master</font><br/><font face="Arial14">Beat all of the Platinum Times.</font><br/>
<font face="DomCasual24">Legendary Marbler</font><br/><font face="Arial14">Beat all of the Ultimate Times.</font><br/>
<font face="DomCasual24">Egg Seeker</font><br/><font face="Arial14">Find any Easter Egg.</font><br/>
<font face="DomCasual24">Easter Bunny</font><br/><font face="Arial14">Find all of the Easter Eggs.</font>';

		this.addChild(achievText);

		var bmp1 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp1.position = new Vector(39, 62);
		bmp1.extent = new Vector(113, 44);
		this.addChild(bmp1);

		var bmp2 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp2.position = new Vector(35, 115);
		bmp2.extent = new Vector(117, 44);
		this.addChild(bmp2);

		var bmp3 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp3.position = new Vector(30, 168);
		bmp3.extent = new Vector(122, 44);
		this.addChild(bmp3);

		var bmp4 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp4.position = new Vector(30, 221);
		bmp4.extent = new Vector(122, 44);
		this.addChild(bmp4);

		var bmp5 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp5.position = new Vector(36, 274);
		bmp5.extent = new Vector(116, 44);
		this.addChild(bmp5);

		var bmp6 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp6.position = new Vector(37, 327);
		bmp6.extent = new Vector(115, 44);
		this.addChild(bmp6);

		var bmp7 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp7.position = new Vector(38, 380);
		bmp7.extent = new Vector(114, 44);
		this.addChild(bmp7);

		var bmp8 = new GuiImage(ResourceLoader.getResource("data/ui/achiev/nonachiev.png", ResourceLoader.getImage, this.imageResources).toTile());
		bmp8.position = new Vector(39, 433);
		bmp8.extent = new Vector(113, 44);
		this.addChild(bmp8);

		var closeButton = new GuiButton(loadButtonImages("data/ui/achiev/close"));
		closeButton.position = new Vector(355, 426);
		closeButton.extent = new Vector(95, 45);
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

		for (difficulty => missions in MissionList.missionList["platinum"]) {
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
				var beatPar = bestTime.time < mis.qualifyTime;
				var beatPlatinum = bestTime.time < mis.goldTime;
				var beatUltimate = bestTime.time < mis.ultimateTime;
				var beaten = beatPar || beatPlatinum || beatUltimate;
				return {
					mission: mis,
					beatPar: beatPar,
					beatPlatinum: beatPlatinum,
					beatUltimate: beatUltimate,
					beaten: beaten
				};
			}));
		}

		var beginnerFinishAchiev = completions["beginner"].filter(x -> !x.beatPar).length == 0;
		var intermediateFinishAchiev = completions["intermediate"].filter(x -> !x.beatPar).length == 0;
		var advancedFinishAchiev = completions["advanced"].filter(x -> !x.beatPar).length == 0;
		var expertFinishAchiev = completions["expert"].filter(x -> !x.beatPar).length == 0;
		var beatPlatinumAchiev = totalPlatinums == 120;
		var beatUltimateAchiev = totalUltimates == 120;

		if (beginnerFinishAchiev)
			bmp1.bmp.tile = ResourceLoader.getResource("data/ui/achiev/n1.png", ResourceLoader.getImage, this.imageResources).toTile();
		if (intermediateFinishAchiev)
			bmp2.bmp.tile = ResourceLoader.getResource("data/ui/achiev/n2.png", ResourceLoader.getImage, this.imageResources).toTile();
		if (advancedFinishAchiev)
			bmp3.bmp.tile = ResourceLoader.getResource("data/ui/achiev/n3.png", ResourceLoader.getImage, this.imageResources).toTile();
		if (expertFinishAchiev)
			bmp4.bmp.tile = ResourceLoader.getResource("data/ui/achiev/n4.png", ResourceLoader.getImage, this.imageResources).toTile();
		if (beatPlatinumAchiev)
			bmp5.bmp.tile = ResourceLoader.getResource("data/ui/achiev/n6.png", ResourceLoader.getImage, this.imageResources).toTile();
		if (beatUltimateAchiev)
			bmp6.bmp.tile = ResourceLoader.getResource("data/ui/achiev/n5.png", ResourceLoader.getImage, this.imageResources).toTile();
	}
}
