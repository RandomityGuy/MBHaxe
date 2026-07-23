package src;

import mis.MissionElement;
import src.DtsObject;
import src.MarbleWorld;
import triggers.Trigger;
import triggers.OutOfBoundsTrigger;
import triggers.InBoundsTrigger;
import triggers.HelpTrigger;
import triggers.TeleportTrigger;
import triggers.DestinationTrigger;
import triggers.CheckpointTrigger;
import triggers.GemChangeTrigger;
import triggers.TimeTravelTrigger;
import triggers.FinishTrigger;
import triggers.SetVelocityTrigger;
import triggers.CancelVelocityTrigger;
import triggers.CameraTrigger;
import triggers.CameraDistanceTrigger;
import triggers.ChangeMarbleSizeTrigger;
import triggers.AccelerationTrigger;
import triggers.GravityTrigger;
import triggers.AlterGravityTrigger;
import triggers.GravityWellTrigger;
import triggers.GravityPointTrigger;
import triggers.NoMovementKeysTrigger;
import triggers.PathTrigger;
import triggers.UsePowerupTrigger;
import triggers.AlignmentTrigger;
import triggers.CountdownStartTrigger;
import triggers.CountdownStopTrigger;
import triggers.DisableShapeForceTrigger;
import triggers.PhysModTrigger;
import shapes.StartPad;
import shapes.EndPad;
import shapes.SignFinish;
import shapes.SignPlain;
import shapes.SignCaution;
import shapes.Sign;
import shapes.Gem;
import shapes.SuperJump;
import shapes.SuperBounce;
import shapes.RoundBumper;
import shapes.TriangleBumper;
import shapes.Helicopter;
import shapes.EasterEgg;
import shapes.Checkpoint;
import shapes.DuctFan;
import shapes.SmallDuctFan;
import shapes.Magnet;
import shapes.AntiGravity;
import shapes.LandMine;
import shapes.Nuke;
import shapes.ShockAbsorber;
import shapes.SuperSpeed;
import shapes.TimeTravel;
import shapes.RandomPowerup;
import shapes.Blast;
import shapes.MegaMarble;
import shapes.Tornado;
import shapes.Trapdoor;
import shapes.PushButton;
import shapes.Oilslick;
import shapes.Glass;
import shapes.PQProp;
import shapes.HelpBubble;
import shapes.AnvilItem;
import shapes.Propeller;
import shapes.ToggleButton;
import shapes.NestEgg;
import shapes.TeleportItem;
import shapes.IceShard;
import shapes.FadePlatform;

/**
 * Matches a lowercased mission-file `datablock` name to a registered entry.
 * `Any` lets a single entry accept several match rules (used for the sign/arrow overlap).
 */
enum DatablockMatch {
	Exact(names:Array<String>);
	Prefix(prefix:String);
	Any(rules:Array<DatablockMatch>);
}

@:structInit
class ShapeDatablockEntry {
	public var match:DatablockMatch;
	public var create:(element:IPlaceableElement) -> DtsObject;
	public var after:(shape:DtsObject, element:IPlaceableElement, world:MarbleWorld) -> Void = null;
}

@:structInit
class TriggerDatablockEntry {
	public var match:DatablockMatch;
	public var create:(element:MissionElementTrigger, level:MarbleWorld) -> Trigger;
}

class DatablockRegistry {
	static function matchesRule(rule:DatablockMatch, name:String):Bool {
		return switch (rule) {
			case Exact(names): names.contains(name);
			case Prefix(prefix): StringTools.startsWith(name, prefix);
			case Any(rules): Lambda.exists(rules, r -> matchesRule(r, name));
		}
	}

	public static function resolveShape(name:String):ShapeDatablockEntry {
		if (PQDecorations.paths.exists(name)) {
			var path = PQDecorations.paths.get(name);
			return {
				match: Exact([name]),
				create: element -> new PQProp(cast element, path)
			};
		}
		for (entry in shapeEntries) {
			if (matchesRule(entry.match, name))
				return entry;
		}
		return null;
	}

	public static function resolveTrigger(name:String):TriggerDatablockEntry {
		for (entry in triggerEntries) {
			if (matchesRule(entry.match, name))
				return entry;
		}
		return null;
	}

	// Order matters: entries are matched top-to-bottom, first match wins. This mirrors the
	// original if/else chain, notably the sign* prefixes which must stay ordered narrowest-first.
	public static var shapeEntries:Array<ShapeDatablockEntry> = [
		{
			match: Exact([
				"startpad",
				"startpad_mbg",
				"startpad_mbp",
				"startpad_mbu",
				"startpad_pq",
				"startpad_pq_construction"
			]),
			create: element -> new StartPad(cast element)
		},
		{
			match: Exact([
				"endpad",
				"endpad_mbg",
				"endpad_mbp",
				"endpad_mbu",
				"endpad_pq",
				"endpad_pq_construction"
			]),
			create: element -> new EndPad(cast element),
			after: (shape, element, world) -> {
				if (element is MissionElementStaticShape && cast(element, MissionElementStaticShape) == world.endPadElement)
					world.endPad = cast shape;
			}
		},
		{
			match: Exact(["signfinish"]),
			create: element -> new SignFinish()
		},
		{
			match: Prefix("signplain"),
			create: element -> new SignPlain(cast element)
		},
		{
			match: Any([Prefix("gemitem"), Prefix("fancygemitem")]),
			create: element -> new Gem(cast element),
			after: (shape, element, world) -> {
				world.totalGems++;
				world.gems.push(cast shape);
			}
		},
		{
			match: Exact([
				"superjumpitem",
				"superjumpitem_mbu",
				"superjumpitem_pq",
				"customsuperjumpitem_pq"
			]),
			create: element -> new SuperJump(cast element)
		},
		{
			match: Prefix("signcaution"),
			create: element -> new SignCaution(cast element)
		},
		{
			match: Exact(["superbounceitem", "superbounceitem_pq"]),
			create: element -> new SuperBounce(cast element)
		},
		{
			match: Exact(["roundbumper", "bumper", "roundbumper_pq"]),
			create: element -> new RoundBumper(cast element)
		},
		{
			match: Exact(["trianglebumper", "trianglebumper_pq"]),
			create: element -> new TriangleBumper(cast element)
		},
		{
			match: Exact(["helicopteritem", "helicopteritem_mbu", "helicopteritem_pq"]),
			create: element -> new Helicopter(cast element)
		},
		{
			match: Exact(["easteregg", "easteregg_mbu"]),
			create: element -> new EasterEgg(cast element)
		},
		{
			match: Exact(["checkpoint", "checkpoint_mbu", "checkpoint_pq"]),
			create: element -> new Checkpoint(cast element)
		},
		{
			match: Exact(["ductfan", "ductfan_mbu", "ductfan_mbm", "ductfan_pq", "nomeshductfan_pq"]),
			create: element -> new DuctFan(cast element)
		},
		{
			match: Exact(["smallductfan", "smallductfan_mbm", "smallductfan_pq"]),
			create: element -> new SmallDuctFan(cast element)
		},
		{
			match: Exact(["magnet"]),
			create: element -> new Magnet()
		},
		{
			match: Exact(["antigravityitem", "antigravityitem_mbu", "antigravityitem_pq"]),
			create: element -> new AntiGravity(cast element)
		},
		{
			match: Exact(["norespawnantigravityitem", "norespawnantigravityitem_pq"]),
			create: element -> new AntiGravity(cast element, true)
		},
		{
			match: Exact(["landmine", "landmine_mbm", "landmine_pq"]),
			create: element -> new LandMine(cast element)
		},
		{
			match: Exact(["nuke", "nuke_pq"]),
			create: element -> new Nuke(cast element)
		},
		{
			match: Exact(["shockabsorberitem", "shockabsorberitem_pq"]),
			create: element -> new ShockAbsorber(cast element)
		},
		{
			match: Exact(["superspeeditem", "superspeeditem_mbu", "superspeeditem_pq"]),
			create: element -> new SuperSpeed(cast element)
		},
		{
			match: Exact([
				   "timetravelitem",    "timepenaltyitem", "timetravelitem_mbu",
				"timetravelitem_pq", "timepenaltyitem_pq",     "sundialitem_pq"
			]),
			create: element -> new TimeTravel(cast element)
		},
		{
			match: Exact([
				   "respawningtimetravelitem",  "respawningtimepenaltyitem",
				"respawningtimetravelitem_pq", "respawningtimepenaltyitem_pq"
			]),
			create: element -> new TimeTravel(cast element, false)
		},
		{
			match: Exact(["randompowerupitem"]),
			create: element -> new RandomPowerup(cast element)
		},
		{
			match: Exact(["blastitem", "blastitem_mbu"]),
			create: element -> new Blast(cast element)
		},
		{
			match: Exact(["megamarbleitem", "megamarbleitem_mbu"]),
			create: element -> new MegaMarble(cast element)
		},
		{
			match: Exact(["tornado", "tornado_mbm", "tornado_pq"]),
			create: element -> new Tornado(cast element)
		},
		{
			match: Exact(["trapdoor", "trapdoor_mbu", "trapdoor_pq"]),
			create: element -> new Trapdoor(cast element)
		},
		{
			match: Exact(["pushbutton", "pushbutton_pq", "pushbuttonflat_pq"]),
			create: element -> new PushButton(cast element)
		},
		{
			match: Exact(["oilslick"]),
			create: element -> new Oilslick()
		},
		{
			match: Exact(["togglebutton", "togglebuttonflat_pq"]),
			create: element -> new ToggleButton(cast element)
		},
		{
			match: Exact(["nestegg_pq"]),
			create: element -> new NestEgg(cast element)
		},
		{
			match: Exact(["teleportitem"]),
			create: element -> new TeleportItem(cast element)
		},
		{
			match: Exact(["iceshard1", "iceshard2"]),
			create: element -> new IceShard(cast element)
		},
		{
			match: Exact([
				"fadeplatform",
				"fadeplatform2_1x1",
				"fadeplatform2_1x2",
				"fadeplatform2_1x3",
				"fadeplatform2_1x5",
				"fadeplatform2_2x2",
				"fadeplatform2_3x3",
				"fadeplatform2_5x5",
				"fadeplatformconcrete",
				"fadeplatformgrass",
				"fadeplatformice"
			]),
			create: element -> new FadePlatform(cast element)
		},
		{
			match: Exact(["helpbubble"]),
			create: element -> new HelpBubble(cast element)
		},
		{
			match: Exact(["anvilitem"]),
			create: element -> new AnvilItem(cast element)
		},
		{
			match: Exact([
				"propeller",
				"proplarge1",
				"proplarge2",
				"proplarge3",
				"proplarge4",
				"proplarge5",
				"propsmall1",
				"propsmall2",
				"propsmall3",
				"propsmall4",
				"propsmall5",
				"proplargereverse1",
				"proplargereverse2",
				"proplargereverse3",
				"proplargereverse4",
				"proplargereverse5",
				"propsmallreverse1",
				"propsmallreverse2",
				"propsmallreverse3",
				"propsmallreverse4",
				"propsmallreverse5"
			]),
			create: element -> new Propeller(cast element)
		},
		{
			match: Any([Exact(["arrow"]), Prefix("sign")]),
			create: element -> new Sign(cast element)
		},
		{
			match: Exact([
				"glass_3shape",
				"glass_6shape",
				"glass_9shape",
				"glass_12shape",
				"glass_15shape",
				"glass_18shape"
			]),
			create: element -> new Glass(cast element)
		},
		{
			match: Exact(["clear", "cloudy", "dusk", "wintry"]),
			create: element -> new shapes.Sky(element.datablock.toLowerCase())
		}
	];

	public static var triggerEntries:Array<TriggerDatablockEntry> = [
		{
			match: Exact(["outofboundstrigger"]),
			create: (element, level) -> new OutOfBoundsTrigger(element, level)
		},
		{
			match: Exact(["inboundstrigger"]),
			create: (element, level) -> new InBoundsTrigger(element, level)
		},
		{
			match: Exact(["helptrigger"]),
			create: (element, level) -> new HelpTrigger(element, level)
		},
		{
			match: Exact(["teleporttrigger"]),
			create: (element, level) -> new TeleportTrigger(element, level)
		},
		{
			match: Exact(["destinationtrigger"]),
			create: (element, level) -> new DestinationTrigger(element, level)
		},
		{
			match: Exact(["checkpointtrigger"]),
			create: (element, level) -> new CheckpointTrigger(element, level)
		},
		{
			match: Exact(["gemchangetrigger"]),
			create: (element, level) -> new GemChangeTrigger(element, level)
		},
		{
			match: Exact(["timetraveltrigger"]),
			create: (element, level) -> new TimeTravelTrigger(element, level)
		},
		{
			match: Exact(["finishtrigger"]),
			create: (element, level) -> new FinishTrigger(element, level)
		},
		{
			match: Exact(["setvelocitytrigger"]),
			create: (element, level) -> new SetVelocityTrigger(element, level)
		},
		{
			match: Exact(["cancelvelocitytrigger"]),
			create: (element, level) -> new CancelVelocityTrigger(element, level)
		},
		{
			match: Exact(["cameratrigger"]),
			create: (element, level) -> new CameraTrigger(element, level)
		},
		{
			match: Exact(["cameradistancetrigger"]),
			create: (element, level) -> new CameraDistanceTrigger(element, level)
		},
		{
			match: Exact(["changemarblesizetrigger"]),
			create: (element, level) -> new ChangeMarbleSizeTrigger(element, level)
		},
		{
			match: Exact(["accelerationtrigger"]),
			create: (element, level) -> new AccelerationTrigger(element, level)
		},
		{
			match: Exact(["gravitytrigger"]),
			create: (element, level) -> new GravityTrigger(element, level)
		},
		{
			match: Exact(["marblephysmodtrigger"]),
			create: (element, level) -> new PhysModTrigger(element, level)
		},
		{
			match: Exact(["altergravitytrigger"]),
			create: (element, level) -> new AlterGravityTrigger(element, level)
		},
		{
			match: Exact(["gravitywelltrigger"]),
			create: (element, level) -> new GravityWellTrigger(element, level)
		},
		{
			match: Exact(["gravitypointtrigger"]),
			create: (element, level) -> new GravityPointTrigger(element, level)
		},
		{
			match: Exact(["nomovementkeystrigger"]),
			create: (element, level) -> new NoMovementKeysTrigger(element, level)
		},
		{
			match: Exact(["pathtrigger"]),
			create: (element, level) -> new PathTrigger(element, level)
		},
		{
			match: Exact(["usepoweruptrigger"]),
			create: (element, level) -> new UsePowerupTrigger(element, level)
		},
		{
			match: Exact(["alignmenttrigger"]),
			create: (element, level) -> new AlignmentTrigger(element, level)
		},
		{
			match: Exact(["countdownstarttrigger"]),
			create: (element, level) -> new CountdownStartTrigger(element, level)
		},
		{
			match: Exact(["countdownstoptrigger"]),
			create: (element, level) -> new CountdownStopTrigger(element, level)
		},
		{
			match: Exact(["disableshapeforcetrigger"]),
			create: (element, level) -> new DisableShapeForceTrigger(element, level)
		}
	];
}
