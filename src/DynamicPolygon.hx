package src;

import hxd.FloatBuffer;
import h3d.prim.UV;
import h3d.prim.MeshPrimitive;
import h3d.col.Point;

/*
	DynamicPolygon rough implementation, doesn't support tangents and colors unlike Polygon, most of the code was taken from Polygon.hx and DynamicPrimitive.hx.
	Usage: 
	Set your points, normals and stuff like usual Polygon
	To update points/normals/uvs, just change the points/normals/uvs array and set dirtyFlags[i] to true for all index of changed points/normals/uvs where i is index of point and call flush();
 */
class DynamicPolygon extends MeshPrimitive {
	public var points:Array<Float>;
	public var normals:Array<Float>;
	public var uvs:Array<Float>;

	// A list of bools having the same length as points/normals/uv and each bool corresponds to point/normal/uv having the same index as the bool
	// Basically this is just used to tell apart vertices that changed so it will be flushed, it will be created after alloc has been called
	public var dirtyFlags:Array<Bool>;

	var buf:FloatBuffer;

	var bounds:h3d.col.Bounds;

	public function new() {}

	public function addPoints(points:Array<h3d.col.Point>) {
		this.points = [];
		for (p in points) {
			this.points.push(p.x);
			this.points.push(p.y);
			this.points.push(p.z);
		}
	}

	public function addUVs(uvs:Array<h3d.prim.UV>) {
		this.uvs = [];
		for (uv in uvs) {
			this.uvs.push(uv.u);
			this.uvs.push(uv.v);
		}
	}

	public function addNormals(normals:Array<h3d.col.Point>) {
		this.normals = [];
		for (n in normals) {
			this.normals.push(n.x);
			this.normals.push(n.y);
			this.normals.push(n.z);
		}
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

	public function flush() {
		var alloc = hxd.impl.Allocator.get();
		var vsize = Std.int(points.length / 3);
		if (vsize == 0) {
			if (buffer != null) {
				alloc.disposeBuffer(buffer);
				buffer = null;
			}
			if (indexes != null) {
				alloc.disposeIndexBuffer(indexes);
				indexes = null;
			}
			return;
		}

		if (buffer != null && (buffer.isDisposed() || buffer.vertices < vsize)) {
			alloc.disposeBuffer(buffer);
			buffer = null;
		}

		if (buffer == null)
			buffer = alloc.allocBuffer(hxd.Math.imax(0, vsize), 8, Dynamic);

		var off = 0;
		for (k in 0...Std.int(points.length / 3)) {
			if (dirtyFlags[k]) {
				buf[off++] = points[k * 3];
				buf[off++] = points[k * 3 + 1];
				buf[off++] = points[k * 3 + 2];
				if (normals != null) {
					buf[off++] = normals[k * 3];
					buf[off++] = normals[k * 3 + 1];
					buf[off++] = normals[k * 3 + 2];
				}
				if (uvs != null) {
					buf[off++] = uvs[k * 2];
					buf[off++] = uvs[k * 2 + 1];
				}
				dirtyFlags[k] = false;
			} else {
				off += 3;
				if (normals != null)
					off += 3;
				if (uvs != null)
					off += 2;
			}
		}

		buffer.uploadVector(buf, 0, vsize);
	}

	override function alloc(engine:h3d.Engine) {
		dispose();

		var allocator = hxd.impl.Allocator.get();

		dirtyFlags = [];

		var size = 3;
		var names = ["position"];
		var positions = [0];
		if (normals != null) {
			names.push("normal");
			positions.push(size);
			size += 3;
		}
		if (uvs != null) {
			names.push("uv");
			positions.push(size);
			size += 2;
		}

		buf = new hxd.FloatBuffer();
		for (k in 0...Std.int(points.length / 3)) {
			buf.push(points[k * 3]);
			buf.push(points[k * 3 + 1]);
			buf.push(points[k * 3 + 2]);
			if (normals != null) {
				buf.push(normals[k * 3]);
				buf.push(normals[k * 3 + 1]);
				buf.push(normals[k * 3 + 2]);
			}
			if (uvs != null) {
				buf.push(uvs[k * 2]);
				buf.push(uvs[k * 2 + 1]);
			}
			dirtyFlags.push(false);
		}

		var flags:Array<h3d.Buffer.BufferFlag> = [];
		flags.push(Triangles);
		if (normals == null)
			flags.push(RawFormat);
		flags.push(Dynamic);

		buffer = allocator.allocBuffer(hxd.Math.imax(0, vertexCount()), 8, Dynamic); // h3d.Buffer.ofFloats(buf, size, flags);
		buffer.uploadVector(buf, 0, Std.int(points.length / 3));

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

	override function triCount() {
		var n = super.triCount();
		if (n != 0)
			return n;
		return Std.int(points.length / 3);
	}

	override function vertexCount() {
		return Std.int(points.length / 3);
	}

	override function render(engine:h3d.Engine) {
		if (buffer == null || buffer.isDisposed())
			alloc(engine);
		var bufs = getBuffers(engine);
		if (indexes != null)
			engine.renderMultiBuffers(bufs, indexes);
		else if (buffer.flags.has(Quads))
			engine.renderMultiBuffers(bufs, engine.mem.quadIndexes, 0, triCount());
		else
			engine.renderMultiBuffers(bufs, engine.mem.triIndexes, 0, triCount());
	}
}
