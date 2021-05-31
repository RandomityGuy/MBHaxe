package src;

import h3d.Vector;
import h3d.scene.CustomObject;

enum ForceType {
	NoForce;
	ForceSpherical;
	ForceField;
	ForceCone;
}

class ForceData {
	public var forceType:ForceType;
	public var forceNode:Int;
	public var forceVector:Vector;
	public var forceRadius:Float;
	public var forceStrength:Float;
	public var forceArc:Float;

	public function new() {}
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
				nodeVec = new Vector(node._12, node._22, node._32);
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
