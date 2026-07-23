package src;

import h3d.Vector;
import h3d.Matrix;
import h3d.Quat;
import mis.MisParser;
import mis.MissionElement.IPlaceableElement;
import src.PathNodeElement.PathNodeLiveTransform;
import src.MarbleWorld;
import src.GameObject;

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

	// The object's own authored scale, captured once here rather than ever re-derived from a
	// transform matrix - `relativeTransform` (whether computed from `ownTransform` or given via
	// `parentmodtrans`) always ends up carrying *some* scale value in its 3x3 part (1 in the
	// `parentmodtrans` case, since that's built from just a position+rotation offset with no scale
	// info at all), and multiplying that into `resultTransform` before `setTransform` decomposes it
	// back out silently replaces the object's own scale with garbage (parent's scale, or flat
	// identity) - reapplying this captured value every call after `setTransform` guarantees the
	// object's own scale is never affected by anything on the parent's side, by construction.
	var ownScale:Vector;

	public function new(obj:GameObject, element:IPlaceableElement, level:MarbleWorld) {
		this.obj = obj;
		this.level = level;
		this.ownScale = new Vector(obj.scaleX, obj.scaleY, obj.scaleZ);

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
	static var scratchParentCleanMat = new Matrix();
	static var scratchParentInverseMat = new Matrix();
	static var scratchRelativeMat = new Matrix();
	static var scratchRotMat = new Matrix();
	static var scratchCombinedMat = new Matrix();

	public function advance() {
		if (this.parentObject == null) {
			// The named parent might not have existed in `level.namedGameObjects` yet at
			// construction time - DTS objects load asynchronously, so a `parent` field can easily
			// resolve *after* this follower was built if the parent's own load just happens to
			// finish later. Keep retrying the lookup lazily every call until it succeeds rather than
			// giving up forever.
			this.parentObject = this.level.namedGameObjects.get(this.parentName);
			if (this.parentObject == null)
				return;
		}
		// The parent might itself be a parented object that hasn't been advanced yet this substep -
		// `MarbleWorld.registerParentedObject`'s insertion-order guarantee only covers the case
		// where both parent and child were already resolved at registration time, which a lazily-
		// resolved parent (just above) can't satisfy. Recursing here guarantees parent-before-child
		// correctness unconditionally, regardless of array order or when resolution happened -
		// idempotent/safe to call more than once per substep since it's a pure function of the
		// parent's current state.
		this.parentObject.advanceParent();
		// Read the parent's position/rotation directly off the object rather than its transform
		// matrix - a parent's *scale* must never leak into where/how the child sits, and pulling
		// position+rotation straight from `x`/`y`/`z`/`getRotationQuat()` (scale lives entirely
		// separately in `scaleX`/`scaleY`/`scaleZ`) rules that out by construction, no decompose
		// needed.
		var parentPos = this.parentObject.getAbsPos().getPosition();
		var parentRot = this.parentObject.getRotationQuat();
		var resultTransform = applyOffsetMatrix(parentPos, parentRot, this.obj.getTransform(), this.parentOffset, this.parentSimple, this.noRot,
			this.relativeTransform);
		this.obj.setTransform(resultTransform);
		// `setTransform` just decomposed whatever scale ended up baked into `resultTransform`'s 3x3
		// part back onto `scaleX`/`scaleY`/`scaleZ` - overwrite it with the object's own captured
		// scale so nothing from the parenting math (parent's scale, or a flat 1 from a
		// `parentmodtrans`-provided relative transform) can ever override it.
		this.obj.scaleX = this.ownScale.x;
		this.obj.scaleY = this.ownScale.y;
		this.obj.scaleZ = this.ownScale.z;
	}

	static function applyOffsetMatrix(parentPos:Vector, parentRot:Quat, ownTransform:Matrix, offset:Vector, simple:Bool, noRot:Bool,
			relativeTransform:Matrix):Matrix {
		// Parent's rotation+position only, scale-free - this is what the child is actually rigidly
		// attached to.
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
