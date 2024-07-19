package src;

import src.DtsObject;
import h3d.Vector;

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

	public function getForce(pos:Vector, outForce:Vector) {
		if (pos.distanceSq(this.getAbsPos().getPosition()) > 50 * 50)
			return;
		var strength = 0.0;
		var dot = 0.0;
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

			var posVec = pos.sub(node.getPosition());
			dot = posVec.length();

			if (forceData.forceRadius < dot) {
				continue;
			}

			var forceType = forceData.forceType;
			strength = (1 - dot / forceData.forceRadius) * forceData.forceStrength;

			if (forceType == ForceSpherical) {
				dot = strength / dot;
				outForce.load(outForce.add(posVec.multiply(dot)));
			}

			if (forceType == ForceField) {
				outForce.load(outForce.add(nodeVec.multiply(strength)));
			}

			if (forceType == ForceCone) {
				posVec.load(posVec.multiply(1 / dot));
				var newDot = nodeVec.dot(posVec);
				var arc = forceData.forceArc;
				if (arc < newDot) {
					outForce.load(outForce.add(posVec.multiply(strength).multiply(newDot - arc).multiply(1 / (1 - arc))));
				}
			}
		}
	}
}
