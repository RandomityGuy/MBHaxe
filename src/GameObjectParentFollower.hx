package src;

import h3d.Vector;
import h3d.Matrix;
import h3d.Quat;
import mis.MisParser;
import mis.MissionElement.IPlaceableElement;
import src.PathNodeElement.PathNodeLiveTransform;

/** Rigidly attaches a `GameObject` to another named object's live transform, ported from PQ's
	`objectToParent`/`SceneObject::updateParenting` (`platinum/server/scripts/moving.cs`). Re-snaps
	every call rather than integrating over time - a parented object is a pure function of its
	parent's *current* transform, nothing to accumulate. */
class GameObjectParentFollower {
	var level:MarbleWorld;
	public var obj:GameObject;
	public var parentObject:GameObject;

	var parentName:String;
	var parentOffset:Vector;
	var parentSimple:Bool;
	var noRot:Bool;
	var relativeTransform:Matrix;

	public function new(obj:GameObject, element:IPlaceableElement, level:MarbleWorld) {
		this.obj = obj;
		this.level = level;

		function field(key:String):String {
			var f = element.fields.get(key);
			return f != null ? f[0] : null;
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
			quat.initRotateAxis(rotOff[0], rotOff[1], rotOff[2], -rotOff[3] * Math.PI / 180);
			quat.x = -quat.x;
			quat.w = -quat.w;
			quat.toMatrix(this.relativeTransform);
			this.relativeTransform.setPosition(vecValue);
		}
	}

	// Pure scratch, reused across calls to avoid per-substep allocations - each call fully
	// consumes/copies these before returning, none of it is stored beyond `advance()`/`applyOffset`.
	static var scratchResultMat = new Matrix();
	static var scratchNoRotMat = new Matrix();
	static var scratchRelativeMat = new Matrix();
	static var scratchRotMat = new Matrix();
	static var scratchCombinedMat = new Matrix();

	public function advance() {
		if (this.parentObject == null)
			return;
		var resultTransform = applyOffsetMatrix(this.parentObject.getTransform(), this.obj.getTransform(), this.parentOffset, this.parentSimple, this.noRot,
			this.relativeTransform);
		this.obj.setTransform(resultTransform);
	}

	static function applyOffsetMatrix(parentTransform:Matrix, ownTransform:Matrix, offset:Vector, simple:Bool, noRot:Bool,
			relativeTransform:Matrix):Matrix {
		var resultTransform = scratchResultMat;
		resultTransform.load(parentTransform);
		if (noRot) {
			scratchNoRotMat.identity();
			scratchNoRotMat.setPosition(resultTransform.getPosition());
			resultTransform = scratchNoRotMat;
		}
		if (!simple) {
			if (relativeTransform == null) {
				scratchRelativeMat.multiply(ownTransform, parentTransform.getInverse());
				relativeTransform = scratchRelativeMat;
			}
			resultTransform.multiply(relativeTransform, resultTransform);
		}
		var finalPos = resultTransform.getPosition().add(offset);
		resultTransform.setPosition(finalPos);
		return resultTransform;
	}

	/** Simplified position/rotation-only variant used by `MarbleWorld.resolvePathNodeTransform` for
		PathNodes that are themselves parented - PathNode's `parent` field is just a plain rigid
		follow with a local position/rotation offset, not general object parenting with
		offset/simple/relative-transform config. */
	public static function applyOffset(parentTransform:Matrix, localPos:Vector, localRot:Quat):PathNodeLiveTransform {
		localRot.toMatrix(scratchRotMat);
		scratchCombinedMat.multiply3x4(scratchRotMat, parentTransform);
		var pos = localPos.transformed(parentTransform);
		var rot = new Quat();
		rot.initRotateMatrix(scratchCombinedMat);
		return {position: new Vector(pos.x, pos.y, pos.z), rotation: rot};
	}
}
