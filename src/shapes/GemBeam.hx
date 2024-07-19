package shapes;

import h3d.mat.Material;
import src.DtsObject;
import src.ResourceLoader;

class GemBeam extends DtsObject {
	public function new(color:String) {
		super();
		this.dtsPath = "data/shapes/gemlights/gemlight.dts";
		this.isCollideable = false;
		this.isTSStatic = false;
		this.identifier = "GemBeam" + color;
		this.useInstancing = true;
		this.matNameOverride.set('base.lightbeam', color + '.lightbeam');
	}
}
