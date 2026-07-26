package shapes;

import src.DtsObject;
import mis.MissionElement.MissionElementStaticShape;

/** Ported from `server/scripts/cannon.cs`'s `Target`/`TargetShape` datablock - a purely decorative
	shooting-range prop (not part of the cannon mechanic itself, just placed near cannons in some
	missions, e.g. `HavingABlast.mcs`) with a handful of preset skins (`base`/`cool`/`red`/`blue`/
	`green`) selected per-instance via the placed object's own `skin` field, matching
	`Target::onAdd`'s `%obj.setSkinName(%obj.skin)`. */
class Target extends DtsObject {
	public function new(?element:MissionElementStaticShape) {
		super();
		this.dtsPath = "data/shapes_pq/gameplay/cannon/target.dts";
		this.identifier = "Target";
		this.isCollideable = true;

		var skinField = element != null ? element.fields.get("skin") : null;
		if (skinField != null && skinField[0] != "")
			this.skinOverride = skinField[0].toLowerCase();
	}
}
