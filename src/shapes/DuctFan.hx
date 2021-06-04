package shapes;

import h3d.Vector;
import src.ForceObject;

class DuctFan extends ForceObject {
	public function new() {
		super();
		this.dtsPath = "data/shapes/hazards/ductfan.dts";
		this.isCollideable = true;
		this.isTSStatic = false;
		this.forceDatas = [
			{
				forceType: ForceCone,
				forceNode: 0,
				forceStrength: 40,
				forceRadius: 10,
				forceArc: 0.7,
				forceVector: new Vector()
			}
		];
	}
}
