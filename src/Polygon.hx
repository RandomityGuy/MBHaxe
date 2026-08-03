package src;

import h3d.Vector;
import h3d.col.Point;
import h3d.prim.MeshPrimitive;

class Polygon extends MeshPrimitive {
	public var points:Array<Float>;
	public var normals:Array<Float>;
	public var tangents:Array<Float>;
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
	}

	public function addPoints(points:Array<h3d.col.Point>) {
		for (p in points) {
			this.points.push(p.x);
			this.points.push(p.y);
			this.points.push(p.z);
		}
		curTris += Math.floor(points.length / 3);
	}

	public function addUVs(uvs:Array<h3d.prim.UV>) {
		for (uv in uvs) {
			this.uvs.push(uv.u);
			this.uvs.push(uv.v);
		}
	}

	public function addNormals(normals:Array<h3d.col.Point>) {
		for (n in normals) {
			this.normals.push(n.x);
			this.normals.push(n.y);
			this.normals.push(n.z);
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
			names.push("tangent");
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
				var n = normals[k * 3];
				buf.push(normals[k * 3]);
				buf.push(normals[k * 3 + 1]);
				buf.push(normals[k * 3 + 2]);
			}
			if (tangents != null) {
				var t = tangents[k];
				buf.push(tangents[k * 3]);
				buf.push(tangents[k * 3 + 1]);
				buf.push(tangents[k * 3 + 2]);
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

		if (indexes == null && Std.int(points.length / 3) > 65535) {
			var indices = new haxe.io.BytesOutput();
			for (i in 0...Std.int(points.length / 3))
				indices.writeInt32(i);
			indexes = new h3d.Indexes(indices.length >> 2, true);
			indexes.uploadBytes(indices.getBytes(), 0, indices.length >> 2);
		}
	}

	// Ported from real PQ's `tangentsFromVertices`/`calculateTangents` (`interiorRender.cc`): each
	// vertex's tangent is orthogonalized against its own normal, and its handedness is derived from
	// the sign of the UV-delta determinant (`r`) so that mirrored/flipped UV triangles get a tangent
	// with the correct sign instead of always taking the same handedness.
	function tangentForVertex(p0:Vector, p1:Vector, p2:Vector, uv0:Vector, uv1:Vector, uv2:Vector, n:Vector) {
		var deltaPos1 = p1.sub(p0);
		var deltaPos2 = p2.sub(p0);
		var deltaUV1x = uv1.x - uv0.x;
		var deltaUV1y = uv1.y - uv0.y;
		var deltaUV2x = uv2.x - uv0.x;
		var deltaUV2y = uv2.y - uv0.y;

		var det = deltaUV1x * deltaUV2y - deltaUV1y * deltaUV2x;
		if (det == 0)
			return new Vector(0, 0, 0);

		var r = 1.0 / det;
		var uDir = deltaPos1.multiply(deltaUV2y).sub(deltaPos2.multiply(deltaUV1y));
		uDir.scale(r);
		var vDir = deltaPos2.multiply(deltaUV1x).sub(deltaPos1.multiply(deltaUV2x));
		vDir.scale(r);

		var tangent = uDir.sub(n.multiply(n.dot3(uDir)));
		tangent.normalize();
		if (n.cross(tangent).dot3(vDir) < 0)
			tangent.scale(-1);

		return tangent;
	}

	public function addTangents() {
		tangents = [];
		for (i in 0...points.length)
			tangents[i] = 0.0;
		var pos = 0;
		for (i in 0...triCount()) {
			var i0, i1, i2;
			i0 = pos++;
			i1 = pos++;
			i2 = pos++;
			var p0 = new Vector(points[i0 * 3], points[i0 * 3 + 1], points[i0 * 3 + 2]);
			var p1 = new Vector(points[i1 * 3], points[i1 * 3 + 1], points[i1 * 3 + 2]);
			var p2 = new Vector(points[i2 * 3], points[i2 * 3 + 1], points[i2 * 3 + 2]);
			var uv0 = new Vector(uvs[i0 * 2], uvs[i0 * 2 + 1]);
			var uv1 = new Vector(uvs[i1 * 2], uvs[i1 * 2 + 1]);
			var uv2 = new Vector(uvs[i2 * 2], uvs[i2 * 2 + 1]);
			var n0 = new Vector(normals[i0 * 3], normals[i0 * 3 + 1], normals[i0 * 3 + 2]);
			var n1 = new Vector(normals[i1 * 3], normals[i1 * 3 + 1], normals[i1 * 3 + 2]);
			var n2 = new Vector(normals[i2 * 3], normals[i2 * 3 + 1], normals[i2 * 3 + 2]);

			var t0 = tangentForVertex(p0, p1, p2, uv0, uv1, uv2, n0);
			var t1 = tangentForVertex(p1, p0, p2, uv1, uv0, uv2, n1);
			var t2 = tangentForVertex(p2, p0, p1, uv2, uv0, uv1, n2);

			tangents[i0 * 3] = t0.x;
			tangents[i0 * 3 + 1] = t0.y;
			tangents[i0 * 3 + 2] = t0.z;
			tangents[i1 * 3] = t1.x;
			tangents[i1 * 3 + 1] = t1.y;
			tangents[i1 * 3 + 2] = t1.z;
			tangents[i2 * 3] = t2.x;
			tangents[i2 * 3 + 1] = t2.y;
			tangents[i2 * 3 + 2] = t2.z;
		}
	}

	override function triCount() {
		var n = super.triCount();
		if (n != 0)
			return n;
		return Std.int(points.length / 3);
	}

	override function vertexCount() {
		return Std.int(points.length / 3);
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
		if (indexes != null)
			engine.renderMultiBuffers(bufs, indexes, indexStarts[currentMaterial], indexCounts[currentMaterial]);
		else
			engine.renderMultiBuffers(bufs, engine.mem.triIndexes, indexStarts[currentMaterial], indexCounts[currentMaterial]);
	}
}
