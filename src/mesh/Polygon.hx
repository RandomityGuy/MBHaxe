package mesh;

import h3d.prim.*;
import h3d.col.Point;

class Polygon extends MeshPrimitive {
	public var points:Array<Float>;
	public var normals:Array<Float>;
	public var tangents:Array<Float>;
	public var bitangents:Array<Float>;
	public var texMatNormals:Array<Float>;
	public var uvs:Array<Float>;
	public var indexStarts:Array<Int>;
	public var indexCounts:Array<Int>;

	var currentMaterial:Int = 0;
	var curTris = 0;

	var bounds:h3d.col.Bounds;

	public function new() {
		this.indexStarts = [0];
		this.indexCounts = [];
		this.points = [];
		this.uvs = [];
		this.normals = [];
		this.tangents = [];
		this.bitangents = [];
		this.texMatNormals = [];
	}

	override function getBounds() {
		if (bounds == null) {
			var b = new h3d.col.Bounds();
			var i = 0;
			while (i < points.length) {
				b.addPoint(new h3d.col.Point(points[i], points[i + 1], points[i + 2]));
				i += 3;
			}
			bounds = b;
		}
		return bounds;
	}

	public function appendPoints(pts:Array<Point>) {
		for (p in pts) {
			this.points.push(p.x);
			this.points.push(p.y);
			this.points.push(p.z);
		}
		curTris += Math.floor(pts.length / 3);
	}

	public function appendNormals(pts:Array<Point>) {
		for (p in pts) {
			this.normals.push(p.x);
			this.normals.push(p.y);
			this.normals.push(p.z);
		}
	}

	public function appendTangents(pts:Array<Point>) {
		for (p in pts) {
			this.tangents.push(p.x);
			this.tangents.push(p.y);
			this.tangents.push(p.z);
		}
	}

	public function appendBitangents(pts:Array<Point>) {
		for (p in pts) {
			this.bitangents.push(p.x);
			this.bitangents.push(p.y);
			this.bitangents.push(p.z);
		}
	}

	public function appendTexMatNormals(pts:Array<Point>) {
		for (p in pts) {
			this.texMatNormals.push(p.x);
			this.texMatNormals.push(p.y);
			this.texMatNormals.push(p.z);
		}
	}

	public function appendUVs(uvs:Array<UV>) {
		for (uv in uvs) {
			this.uvs.push(uv.u);
			this.uvs.push(uv.v);
		}
	}

	public function nextMaterial() {
		indexStarts.push(Math.floor(this.points.length / 9));
		indexCounts.push(curTris);
		curTris = 0;
	}

	public function endPrimitive() {
		indexCounts.push(curTris);
		curTris = 0;
	}

	override function alloc(engine:h3d.Engine) {
		dispose();

		var size = 3;
		var names = ["position"];
		var positions = [0];
		if (normals != null) {
			names.push("normal");
			positions.push(size);
			size += 3;
		}
		if (tangents != null) {
			names.push("t");
			positions.push(size);
			size += 3;
		}
		if (bitangents != null) {
			names.push("b");
			positions.push(size);
			size += 3;
		}
		if (texMatNormals != null) {
			names.push("n");
			positions.push(size);
			size += 3;
		}
		if (uvs != null) {
			names.push("uv");
			positions.push(size);
			size += 2;
		}

		var buf = new hxd.FloatBuffer();
		for (k in 0...Std.int(points.length / 3)) {
			buf.push(points[k * 3]);
			buf.push(points[k * 3 + 1]);
			buf.push(points[k * 3 + 2]);
			if (normals != null) {
				buf.push(normals[k * 3]);
				buf.push(normals[k * 3 + 1]);
				buf.push(normals[k * 3 + 2]);
			}
			if (tangents != null) {
				buf.push(tangents[k * 3]);
				buf.push(tangents[k * 3 + 1]);
				buf.push(tangents[k * 3 + 2]);
			}
			if (bitangents != null) {
				buf.push(bitangents[k * 3]);
				buf.push(bitangents[k * 3 + 1]);
				buf.push(bitangents[k * 3 + 2]);
			}
			if (texMatNormals != null) {
				buf.push(texMatNormals[k * 3]);
				buf.push(texMatNormals[k * 3 + 1]);
				buf.push(texMatNormals[k * 3 + 2]);
			}
			if (uvs != null) {
				var t = uvs[k];
				buf.push(uvs[k * 2]);
				buf.push(uvs[k * 2 + 1]);
			}
		}
		var flags:Array<h3d.Buffer.BufferFlag> = [];
		flags.push(Triangles);
		if (normals == null || tangents != null)
			flags.push(RawFormat);
		buffer = h3d.Buffer.ofFloats(buf, size, flags);

		for (i in 0...names.length)
			addBuffer(names[i], buffer, positions[i]);
	}

	public function addNormals() {
		// make per-point normal
		normals = new Array();
		for (i in 0...points.length)
			normals[i] = 0;
		var pos = 0;
		for (i in 0...triCount()) {
			var i0, i1, i2;
			i0 = pos++;
			i1 = pos++;
			i2 = pos++;
			var p0 = new h3d.Vector(points[3 * i0], points[3 * i0 + 1], points[3 * i0 + 2]);
			var p1 = new h3d.Vector(points[3 * i1], points[3 * i1 + 1], points[3 * i1 + 2]);
			var p2 = new h3d.Vector(points[3 * i2], points[3 * i2 + 1], points[3 * i2 + 2]);
			// this is the per-face normal
			var n = p1.sub(p0).cross(p2.sub(p0));
			// add it to each point
			normals[3 * i0] += n.x;
			normals[3 * i0 + 1] += n.y;
			normals[3 * i0 + 2] += n.z;

			normals[3 * i1] += n.x;
			normals[3 * i1 + 1] += n.y;
			normals[3 * i1 + 2] += n.z;

			normals[3 * i2] += n.x;
			normals[3 * i2 + 1] += n.y;
			normals[3 * i2 + 2] += n.z;
		}
		// normalize all normals
		for (k in 0...Std.int(points.length / 3)) {
			var n = new h3d.Vector(normals[k * 3], normals[k * 3 + 1], normals[k * 3 + 2]);
			n.normalize();

			normals[k * 3] = n.x;
			normals[k * 3 + 1] = n.y;
			normals[k * 3 + 2] = n.z;
		}
	}

	public function addTangents() {
		if (normals == null)
			addNormals();
		if (uvs == null)
			addUVs();
		tangents = [];
		for (i in 0...points.length)
			tangents[i] = 0;
		var pos = 0;
		for (i in 0...triCount()) {
			var i0, i1, i2;
			i0 = pos++;
			i1 = pos++;
			i2 = pos++;

			var p0 = new h3d.Vector(points[3 * i0], points[3 * i0 + 1], points[3 * i0 + 2]);
			var p1 = new h3d.Vector(points[3 * i1], points[3 * i1 + 1], points[3 * i1 + 2]);
			var p2 = new h3d.Vector(points[3 * i2], points[3 * i2 + 1], points[3 * i2 + 2]);
			var uv0 = new UV(uvs[2 * i0], uvs[2 * i0 + 1]);
			var uv1 = new UV(uvs[2 * i1], uvs[2 * i1 + 1]);
			var uv2 = new UV(uvs[2 * i2], uvs[2 * i2 + 1]);
			var n = new h3d.Vector(normals[3 * i0], normals[3 * i0 + 1], normals[3 * i0 + 2]);

			var k0 = p1.sub(p0);
			var k1 = p2.sub(p0);
			k0.scale(uv2.v - uv0.v);
			k1.scale(uv1.v - uv0.v);
			var t = k0.sub(k1);
			var b = n.cross(t);
			b.normalize();
			t = b.cross(n);
			t.normalize();

			// add it to each point
			tangents[3 * i0] += t.x;
			tangents[3 * i0 + 1] += t.y;
			tangents[3 * i0 + 2] += t.z;

			tangents[3 * i1] += t.x;
			tangents[3 * i1 + 1] += t.y;
			tangents[3 * i1 + 2] += t.z;

			tangents[3 * i2] += t.x;
			tangents[3 * i2 + 1] += t.y;
			tangents[3 * i2 + 2] += t.z;
		}
		for (k in 0...Std.int(points.length / 3)) {
			var n = new h3d.Vector(tangents[k * 3], tangents[k * 3 + 1], tangents[k * 3 + 2]);
			n.normalize();

			tangents[k * 3] = n.x;
			tangents[k * 3 + 1] = n.y;
			tangents[k * 3 + 2] = n.z;
		}
	}

	public function addUVs() {
		uvs = [];
		for (k in 0...Std.int(points.length / 3)) {
			uvs[k * 2] = points[k * 3];
			uvs[k * 2 + 1] = points[k * 3 + 1];
		}
	}

	override function triCount() {
		var n = super.triCount();
		if (n != 0)
			return n;
		return Std.int(points.length / 9);
	}

	override function vertexCount() {
		return points.length;
	}

	override function selectMaterial(material:Int) {
		currentMaterial = material;
	}

	override function getMaterialIndexes(material:Int):{count:Int, start:Int} {
		return {start: indexStarts[material] * 3, count: indexCounts[material] * 3};
	}

	override function render(engine:h3d.Engine) {
		if (buffer == null || buffer.isDisposed())
			alloc(engine);
		var bufs = getBuffers(engine);
		engine.renderMultiBuffers(bufs, engine.mem.triIndexes, indexStarts[currentMaterial], indexCounts[currentMaterial]);
	}
}
