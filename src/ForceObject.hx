package src;

import src.DtsObject;
import h3d.Vector;
import h3d.scene.CustomObject;

enum ForceType {
	NoForce;
	ForceSpherical;
	ForceField;
	ForceCone;
}

typedef ForceData = {
	var forceType:ForceType;
	var forceNode:Int;
	var forceVector:Vector;
	var forceRadius:Float;
	var forceStrength:Float;
	var forceArc:Float;
}

class ForceObject extends DtsObject {
	var forceDatas:Array<ForceData>;

	public function getForce(pos:Vector) {
		var strength = 0.0;
		var dot = 0.0;
		var posVec = new Vector();
		var retForce = new Vector();
		for (forceData in forceDatas) {
			if (forceData.forceType == NoForce) {
				continue;
			}

			var node = this.getMountTransform(forceData.forceNode);
			var nodeVec:Vector;
			if (forceData.forceVector.length() == 0) {
				nodeVec = node.right();
			} else {
				nodeVec = forceData.forceVector;
			}

			posVec = pos.sub(node.getPosition());
			dot = posVec.length();

			if (forceData.forceRadius < dot) {
				continue;
			}

			var forceType = forceData.forceType;
			strength = (1 - dot / forceData.forceRadius) * forceData.forceStrength;

			if (forceType == ForceSpherical) {
				dot = strength / dot;
				retForce = retForce.add(posVec.multiply(dot));
			}

			if (forceType == ForceField) {
				retForce = retForce.add(nodeVec.multiply(strength));
			}

			if (forceType == ForceCone) {
				posVec = posVec.multiply(1 / dot);
				var newDot = nodeVec.dot(posVec);
				var arc = forceData.forceArc;
				if (arc < newDot) {
					retForce = retForce.add(posVec.multiply(strength).multiply(newDot - arc).multiply(1 / (1 - arc)));
				}
			}
		}

		return retForce;
	}
}
