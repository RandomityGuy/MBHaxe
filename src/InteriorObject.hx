package src;

import collision.CollisionWorld;
import src.MarbleWorld;
import src.DifBuilder;
import h3d.Matrix;
import h3d.Vector;
import collision.CollisionEntity;
import src.GameObject;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.mat.Material;
import h3d.mat.Stencil;
import h3d.shader.FixedColor;
import src.Util;
import dif.Interior;
import dif.Surface;
import dif.math.Point3F;
import src.Settings;

class InteriorObject extends GameObject {
	static var stencilVolumeMeshes:Array<Mesh> = [];

	public var collider:CollisionEntity;
	public var interiorFile:String;
	public var useInstancing = true;
	public var level:MarbleWorld;
	public var collisionWorld:CollisionWorld;

	public var dif:Interior;

	var shadowMesh:Mesh;
	var shadowExtrude:Point3F;

	public function new() {
		super();
		this.isCollideable = true;
	}

	public function init(level:MarbleWorld, onFinish:Void->Void) {
		this.identifier = this.interiorFile;
		this.level = level;

		if (!Util.isIOSInstancingSupported()) {
			this.useInstancing = false;
		}

		if (this.level != null)
			this.collisionWorld = this.level.collisionWorld;

		DifBuilder.loadDif(this.interiorFile, cast this, () -> {
			updateStencilShadowVolume();
			onFinish();
		});
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		collider.setTransform(transform);
		this.level.collisionWorld.updateTransform(this.collider);

		updateStencilShadowVolume();
	}

	public override function onLevelStart() {
		updateStencilShadowVolume();
	}

	override public function dispose() {
		super.dispose();
		destroyShadowVolume();
	}

	inline function getFlippedPlane(planeIndex:Int):Point3F {
		var flipped = (planeIndex & 0x8000) != 0;
		var index = planeIndex & 0x7FFF;
		var plane = dif.planes[index];
		var normal = dif.normals[plane.normalIndex];

		var x = flipped ? normal.x : -normal.x;
		var y = flipped ? -normal.y : normal.y;
		var z = flipped ? -normal.z : normal.z;
		return new Point3F(x, y, z);
	}

	function fullWindingFromSurface(surf:Surface, outIndices:Array<Int>) {
		var count = surf.windingCount;
		outIndices[0] = dif.windings[surf.windingStart];

		var idx = 1;
		var i = 1;
		while (i < count) {
			outIndices[idx++] = dif.windings[surf.windingStart + i];
			i += 2;
		}

		i = (count - 1) & ~1;
		while (i > 0) {
			outIndices[idx++] = dif.windings[surf.windingStart + i];
			i -= 2;
		}
	}

	function addNearCapTriangles(surf:Surface, outTris:Array<Point3F>) {
		var start = surf.windingStart;
		for (k in (start + 2)...(start + surf.windingCount)) {
			var i1:Int;
			var i2:Int;
			var i3:Int;
			if ((k - (start + 2)) % 2 == 0) {
				i1 = dif.windings[k];
				i2 = dif.windings[k - 1];
				i3 = dif.windings[k - 2];
			} else {
				i1 = dif.windings[k - 2];
				i2 = dif.windings[k - 1];
				i3 = dif.windings[k];
			}

			pushMirrored(outTris, i3);
			pushMirrored(outTris, i2);
			pushMirrored(outTris, i1);
		}
	}

	inline function pushMirrored(outTris:Array<Point3F>, index:Int) {
		var p = dif.points[index];
		outTris.push(new Point3F(-p.x, p.y, p.z));
	}

	public function buildStencilShadowVolume(objExtrude:Point3F, outTris:Array<Point3F>) {
		outTris.resize(0);

		if (objExtrude.lengthSq() <= 0.0 || dif.points.length == 0)
			return;

		var builder = new StencilShadowVolumeBuilder(objExtrude, outTris, Std.int(dif.windings.length / 2));

		var polyIndices:Array<Int> = [];
		var polyPoints:Array<Point3F> = [];

		for (i in 0...dif.surfaces.length) {
			var surf = dif.surfaces[i];
			if (surf.windingCount < 3)
				continue;

			var plane = getFlippedPlane(surf.planeIndex);

			var facing = plane.dot(objExtrude);
			if (facing >= 0.0 || facing > -objExtrude.length() * 1.0e-4)
				continue;

			var count = surf.windingCount;
			polyIndices.resize(count);
			polyPoints.resize(count);
			fullWindingFromSurface(surf, polyIndices);

			var newell = new Point3F(0, 0, 0);
			for (j in 0...count) {
				var a = dif.points[polyIndices[j]];
				var b = dif.points[polyIndices[(j + 1) % count]];
				var ax = -a.x, ay = a.y, az = a.z;
				var bx = -b.x, by = b.y, bz = b.z;
				newell.x += (ay - by) * (az + bz);
				newell.y += (az - bz) * (ax + bx);
				newell.z += (ax - bx) * (ay + by);
			}

			if (newell.dot(plane) < 0.0) {
				for (j in 0...Std.int(count / 2)) {
					var tmp = polyIndices[j];
					polyIndices[j] = polyIndices[count - 1 - j];
					polyIndices[count - 1 - j] = tmp;
				}
			}

			for (j in 0...count) {
				var p = dif.points[polyIndices[j]];
				polyPoints[j] = new Point3F(-p.x, p.y, p.z);
			}

			addNearCapTriangles(surf, outTris);
			builder.addPolygon(polyPoints, polyIndices, count, false);
		}

		builder.finish();
	}

	public function updateStencilShadowVolume() {
		if (!Settings.optionsSettings.shadows)
			return;

		var worldDir = level.dirLightDir;
		if (worldDir.lengthSq() < 1.0e-8)
			return;

		var inv = new Matrix();
		inv.inverse3x4(getAbsPos());

		var local = worldDir.normalized();
		local.w = 0;
		local.transform3x3(inv);
		local.scale(500);

		var extrude = new Point3F(local.x, local.y, local.z);
		if (shadowMesh != null && shadowExtrude != null) {
			var refLenSq = Math.max(shadowExtrude.lengthSq(), 1.0);
			if (extrude.sub(shadowExtrude).lengthSq() <= refLenSq * 1.0e-8)
				return;
		}

		var tris:Array<Point3F> = [];
		buildStencilShadowVolume(extrude, tris);
		if (tris.length < 3) {
			destroyShadowVolume();
			return;
		}

		var points:Array<h3d.col.Point> = [];
		for (p in tris)
			points.push(new h3d.col.Point(p.x, p.y, p.z));

		var prim = new h3d.prim.Polygon(points);

		if (shadowMesh == null) {
			shadowMesh = new Mesh(prim, createVolumeMaterial(), level.scene);
			shadowMesh.follow = this;
			stencilVolumeMeshes.push(shadowMesh);
		} else {
			shadowMesh.primitive = prim;
		}

		shadowExtrude = extrude;
	}

	function destroyShadowVolume() {
		if (shadowMesh != null) {
			shadowMesh.remove();
			stencilVolumeMeshes.remove(shadowMesh);
			shadowMesh = null;
		}
		shadowExtrude = null;
	}

	static function createVolumeMaterial():Material {
		var mat = Material.create();
		mat.castShadows = false;
		mat.receiveShadows = false;
		mat.shadows = false;

		var pass = mat.mainPass;
		pass.setPassName("interiorShadowVolume");
		pass.enableLights = false;
		pass.culling = None;
		pass.depth(false, Less);
		pass.setColorMask(false, false, false, false);
		pass.blend(One, Zero);
		pass.addShader(new FixedColor(0, 0));

		var stencil = new Stencil();
		stencil.setFunc(Always, 0, 0xFF, 0xFF);
		stencil.setFront(Keep, DecrementWrap, Keep);
		stencil.setBack(Keep, IncrementWrap, Keep);
		pass.stencil = stencil;

		return mat;
	}
}

private typedef ShadowEdge = {
	var a:Point3F;
	var b:Point3F;
	var count:Int;
}

private class StencilShadowVolumeBuilder {
	var extrude:Point3F;
	var out:Array<Point3F>;
	var edges:Map<String, ShadowEdge> = [];

	public function new(extrude:Point3F, out:Array<Point3F>, expectedEdges:Int = 0) {
		this.extrude = extrude;
		this.out = out;
	}

	inline function tri(a:Point3F, b:Point3F, c:Point3F) {
		out.push(a);
		out.push(b);
		out.push(c);
	}

	function addEdge(ia:Int, ib:Int, a:Point3F, b:Point3F) {
		var reverseKey = '${ib}:${ia}';
		var rev = edges.get(reverseKey);
		if (rev != null) {
			rev.count--;
			if (rev.count == 0)
				edges.remove(reverseKey);
			return;
		}

		var key = '${ia}:${ib}';
		var rec = edges.get(key);
		if (rec == null) {
			rec = {
				a: a,
				b: b,
				count: 0
			};
			edges.set(key, rec);
		}
		rec.count++;
	}

	public function addPolygon(points:Array<Point3F>, ids:Array<Int>, count:Int, nearCap:Bool = true) {
		if (count < 3)
			return;

		for (j in 1...(count - 1)) {
			if (nearCap)
				tri(points[0], points[j], points[j + 1]);
			tri(points[0].add(extrude), points[j + 1].add(extrude), points[j].add(extrude));
		}

		for (j in 0...count) {
			var n = (j + 1) % count;
			addEdge(ids[j], ids[n], points[j], points[n]);
		}
	}

	public function finish() {
		for (key => rec in edges) {
			var a2 = rec.a.add(extrude);
			var b2 = rec.b.add(extrude);
			for (c in 0...rec.count) {
				tri(rec.a, a2, b2);
				tri(rec.a, b2, rec.b);
			}
		}

		edges.clear();
	}
}
