package modes.special;

import src.InteriorObject;
import collision.CollisionInfo;

class SacredGroundMode extends NullMode {
	public override function processMaterialContact(marble:src.Marble, contact:CollisionInfo) {
		if (contact.otherObject is InteriorObject) {
			var igo = cast(contact.otherObject, InteriorObject);
			if (igo.interiorFile.indexOf("spike") != -1) {
				this.level.goOutOfBounds(marble);
			}
		}
	}
}
