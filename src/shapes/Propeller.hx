package shapes;

import h3d.Vector;
import src.ForceObject;
import mis.MissionElement.MissionElementStaticShape;

typedef PropellerStats = {
	var dtsPath:String;
	var forceStrength:Float;
	var forceRadius:Float;
}

class Propeller extends ForceObject {
	static var stats:Map<String, PropellerStats> = [
		"propeller" => {dtsPath: "data/shapes_pq/gameplay/hazards/propeller.dts", forceStrength: 0, forceRadius: 10},
		"proplarge1" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_large_1.dts", forceStrength: 15, forceRadius: 25},
		"proplarge2" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_large_2.dts", forceStrength: 25, forceRadius: 35},
		"proplarge3" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_large_3.dts", forceStrength: 35, forceRadius: 45},
		"proplarge4" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_large_4.dts", forceStrength: 40, forceRadius: 50},
		"proplarge5" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_large_5.dts", forceStrength: 45, forceRadius: 55},
		"propsmall1" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_small_1.dts", forceStrength: 4, forceRadius: 4},
		"propsmall2" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_small_2.dts", forceStrength: 6, forceRadius: 4.5},
		"propsmall3" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_small_3.dts", forceStrength: 8, forceRadius: 4.75},
		"propsmall4" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_small_4.dts", forceStrength: 10, forceRadius: 5},
		"propsmall5" => {dtsPath: "data/shapes_pq/gameplay/hazards/forward/propeller_small_5.dts", forceStrength: 15, forceRadius: 7},
		"proplargereverse1" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_large_r_1.dts", forceStrength: -15, forceRadius: 25},
		"proplargereverse2" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_large_r_2.dts", forceStrength: -25, forceRadius: 35},
		"proplargereverse3" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_large_r_3.dts", forceStrength: -35, forceRadius: 45},
		"proplargereverse4" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_large_r_4.dts", forceStrength: -40, forceRadius: 50},
		"proplargereverse5" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_large_r_5.dts", forceStrength: -45, forceRadius: 55},
		"propsmallreverse1" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_small_r_1.dts", forceStrength: -4, forceRadius: 4},
		"propsmallreverse2" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_small_r_2.dts", forceStrength: -6, forceRadius: 4.5},
		"propsmallreverse3" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_small_r_3.dts", forceStrength: -8, forceRadius: 4.75},
		"propsmallreverse4" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_small_r_4.dts", forceStrength: -10, forceRadius: 5},
		"propsmallreverse5" => {dtsPath: "data/shapes_pq/gameplay/hazards/reverse/propeller_small_r_5.dts", forceStrength: -15, forceRadius: 7},
	];

	public function new(element:MissionElementStaticShape) {
		super();
		var s = stats.exists(element.datablock.toLowerCase()) ? stats.get(element.datablock.toLowerCase()) : stats.get("propeller");
		this.dtsPath = s.dtsPath;
		this.isCollideable = true;
		this.isTSStatic = false;
		this.identifier = "Propeller";
		this.forceDatas = [
			{
				forceType: ForceCone,
				forceNode: 0,
				forceStrength: s.forceStrength,
				forceRadius: s.forceRadius,
				forceArc: 0.7,
				forceVector: new Vector()
			}
		];
	}
}
