package src;

import h3d.Vector;
import h3d.Matrix;
import h3d.Quat;
import mis.MisParser;
import mis.MissionElement.IPlaceableElement;
import src.PathNodeElement.PathNodeLiveTransform;
import src.MarbleWorld;
import src.GameObject;

class GameObjectParentFollower {
	var level:MarbleWorld;

	public var obj:GameObject;
	public var parentObject:GameObject;

	var parentName:String;
	var parentOffset:Vector;
	var parentSimple:Bool;
	var noRot:Bool;
	var relativeTransform:Matrix;

	var ownScale:Vector;

	public function new(obj:GameObject, element:IPlaceableElement, level:MarbleWorld) {
		this.obj = obj;
		this.level = level;
		this.ownScale = new Vector(obj.scaleX, obj.scaleY, obj.scaleZ);

		function field(key:String):String {
			var f = element.fields.get(key);
			return f != null ? f[0].toLowerCase() : null;
		}

		this.parentName = field("parent");
		this.parentObject = level.namedGameObjects.get(this.parentName);

		var parentOffsetStr = field("parentoffset");
		this.parentOffset = parentOffsetStr != null && parentOffsetStr != "" ? MisParser.parseVector3(parentOffsetStr) : new Vector();
		this.parentOffset.x = -this.parentOffset.x;
		this.parentOffset.w = 0;

		var parentSimpleStr = field("parentsimple");
		this.parentSimple = parentSimpleStr != null && MisParser.parseBoolean(parentSimpleStr);
		var noRotStr = field("parentnorot");
		this.noRot = noRotStr != null && MisParser.parseBoolean(noRotStr);

		var parentModTransStr = field("parentmodtrans");
		if (parentModTransStr != null && parentModTransStr != "") {
			var vecValue = MisParser.parseVector3(parentModTransStr);
			vecValue.x = -vecValue.x;

			var rotOff = MisParser.parseNumberList(parentModTransStr).slice(3);
			while (rotOff.length < 4)
				rotOff.push(0);

			this.relativeTransform = new Matrix();
			var quat = new Quat();
			quat.initRotateAxis(rotOff[0], rotOff[1], rotOff[2], -rotOff[3]);
			quat.x = -quat.x;
			quat.w = -quat.w;
			quat.toMatrix(this.relativeTransform);
			this.relativeTransform.setPosition(vecValue);
		}
	}

	static var scratchResultMat = new Matrix();
	static var scratchParentCleanMat = new Matrix();
	static var scratchParentInverseMat = new Matrix();
	static var scratchRelativeMat = new Matrix();
	static var scratchRotMat = new Matrix();
	static var scratchCombinedMat = new Matrix();

	public function advance() {
		if (this.parentObject == null) {
			this.parentObject = this.level.namedGameObjects.get(this.parentName);
			if (this.parentObject == null)
				return;
		}
		this.parentObject.advanceParent();
		var parentPos = this.parentObject.getAbsPos().getPosition();
		var parentRot = this.parentObject.getRotationQuat();
		var resultTransform = applyOffsetMatrix(parentPos, parentRot, this.obj.getTransform(), this.parentOffset, this.parentSimple, this.noRot,
			this.relativeTransform);
		this.obj.setTransform(resultTransform);
		this.obj.scaleX = this.ownScale.x;
		this.obj.scaleY = this.ownScale.y;
		this.obj.scaleZ = this.ownScale.z;
	}

	static function applyOffsetMatrix(parentPos:Vector, parentRot:Quat, ownTransform:Matrix, offset:Vector, simple:Bool, noRot:Bool,
			relativeTransform:Matrix):Matrix {
		parentRot.toMatrix(scratchParentCleanMat);
		scratchParentCleanMat.setPosition(parentPos);

		var resultTransform = scratchResultMat;
		if (noRot) {
			resultTransform.identity();
			resultTransform.setPosition(parentPos);
		} else {
			resultTransform.load(scratchParentCleanMat);
		}
		if (!simple) {
			if (relativeTransform == null) {
				scratchRelativeMat.multiply(ownTransform, scratchParentCleanMat.getInverse(scratchParentInverseMat));
				relativeTransform = scratchRelativeMat;
			}
			resultTransform.multiply(relativeTransform, resultTransform);
		}
		var finalPos = resultTransform.getPosition().add(offset);
		resultTransform.setPosition(finalPos);
		return resultTransform;
	}

	public static function applyOffset(parentTransform:Matrix, localPos:Vector, localRot:Quat):PathNodeLiveTransform {
		localRot.toMatrix(scratchRotMat);
		scratchCombinedMat.multiply3x4(scratchRotMat, parentTransform);
		var pos = localPos.transformed(parentTransform);
		var rot = new Quat();
		rot.initRotateMatrix(scratchCombinedMat);
		return {position: new Vector(pos.x, pos.y, pos.z), rotation: rot};
	}
}
