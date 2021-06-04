package shapes;

import h3d.Vector;
import src.ForceObject;

class Tornado extends ForceObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/tornado.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.forceDatas = [
			{
				forceType: ForceSpherical,
				forceNode: 0,
				forceStrength: -60,
				forceRadius: 8,
				forceArc: 0,
				forceVector: new Vector()
			},
			{
				forceType: ForceSpherical,
				forceNode: 0,
				forceStrength: 60,
				forceRadius: 3,
				forceArc: 0,
				forceVector: new Vector()
			},
			{
				forceType: ForceField,
				forceNode: 0,
				forceStrength: 250,
				forceRadius: 3,
				forceArc: 0,
				forceVector: new Vector(0, 0, 1)
			},
		];
	}
}
