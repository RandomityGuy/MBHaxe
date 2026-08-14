package src;

import src.ParticleSystem.Particle;

private class ParticleIterator {
	var p:Particle;

	public inline function new(p) {
		this.p = p;
	}

	public inline function hasNext() {
		return p != null;
	}

	public inline function next() {
		var v = p;
		p = p.next;
		return v;
	}
}

enum SortMode {
	Front;
	Back;
	Sort;
	InvSort;
}

class ParticlesMesh extends h3d.scene.Mesh {
	var pshader:h3d.shader.ParticleShader;

	public var count(default, null):Int = 0;
	public var hasColor(default, set):Bool;
	public var sortMode:SortMode;
	public var globalSize:Float = 1;

	public var frustumCull:Bool = true;

	public var cullDistance:Float = -1;

	var head:Particle;
	var tail:Particle;
	var pool:Particle;

	var tmp:h3d.Vector;
	var tmpBuf:hxd.FloatBuffer;
	var buffer:h3d.Buffer;
	var bufferSize:Int = 0;

	var tile:h2d.Tile;

	var cullPoint = new h3d.col.Point();

	public function new(?texture, ?parent) {
		super(null, null, parent);
		material.props = material.getDefaultProps("particles3D");
		sortMode = Back;
		pshader = new h3d.shader.ParticleShader();
		pshader.isAbsolute = true;
		material.mainPass.addShader(pshader);
		material.mainPass.dynamicParameters = true;
		material.texture = texture;
		tile = h2d.Tile.fromTexture(material.texture);
		tmp = new h3d.Vector();
	}

	function set_hasColor(b) {
		var c = material.mainPass.getShader(h3d.shader.VertexColorAlpha);
		if (b) {
			if (c == null)
				material.mainPass.addShader(new h3d.shader.VertexColorAlpha());
		} else {
			if (c != null)
				material.mainPass.removeShader(c);
		}
		return hasColor = b;
	}

	public function offsetParticles(dx:Float, dy:Float, dz = 0.) {
		var p = head;
		while (p != null) {
			p.x += dx;
			p.y += dy;
			p.z += dz;
			p = p.next;
		}
	}

	public function clear() {
		while (head != null)
			kill(head);
	}

	public function alloc():Particle {
		var p = emitParticle();
		if (posChanged)
			syncPos();
		p.parts = this;
		p.x = absPos.tx;
		p.y = absPos.ty;
		p.z = absPos.tz;
		p.rotation = 0;
		p.ratio = 0;
		p.size = 0;
		p.r = p.g = p.b = p.a = 0;
		return p;
	}

	public function add(p:Particle) {
		emitParticle(p);
		return p;
	}

	function emitParticle(?p:Particle) {
		if (p == null) {
			if (pool == null)
				p = new Particle();
			else {
				p = pool;
				pool = p.next;
			}
		}
		count++;
		switch (sortMode) {
			case Front, Sort, InvSort:
				if (head == null) {
					p.next = null;
					head = tail = p;
				} else {
					head.prev = p;
					p.next = head;
					head = p;
				}
			case Back:
				if (head == null) {
					p.next = null;
					head = tail = p;
				} else {
					tail.next = p;
					p.prev = tail;
					p.next = null;
					tail = p;
				}
		}
		return p;
	}

	function kill(p:Particle) {
		p.clear();
		if (p.prev == null)
			head = p.next
		else
			p.prev.next = p.next;
		if (p.next == null)
			tail = p.prev
		else
			p.next.prev = p.prev;
		p.prev = null;
		p.next = pool;
		pool = p;
		count--;
	}

	function sort(list:Particle) {
		return haxe.ds.ListSort.sort(list, function(p1, p2) return p1.w < p2.w ? 1 : -1);
	}

	function sortInv(list:Particle) {
		return haxe.ds.ListSort.sort(list, function(p1, p2) return p1.w < p2.w ? -1 : 1);
	}

	public inline function getParticles() {
		return new ParticleIterator(head);
	}

	@:access(h2d.Tile)
	@:noDebug
	override function draw(ctx:h3d.scene.RenderContext) {
		if (head == null)
			return;
		switch (sortMode) {
			case Sort, InvSort:
				var p = head;
				var m = ctx.camera.m;
				while (p != null) {
					p.w = (p.x * m._13 + p.y * m._23 + p.z * m._33 + m._43) / (p.x * m._14 + p.y * m._24 + p.z * m._34 + m._44);
					p = p.next;
				}
				head = sortMode == Sort ? sort(head) : sortInv(head);
				tail = head.prev;
				head.prev = null;
			default:
		}
		if (tmpBuf == null)
			tmpBuf = new hxd.FloatBuffer();
		var pos = 0;
		var p = head;
		var tmp = tmpBuf;
		var surface = 0.;

		var camPos = ctx.camera.pos;
		var frustum = ctx.camera.frustum;
		var cullDistSq = cullDistance * cullDistance;

		while (p != null) {
			if (cullDistance > 0) {
				var dx = p.x - camPos.x;
				var dy = p.y - camPos.y;
				var dz = p.z - camPos.z;
				if (dx * dx + dy * dy + dz * dz > cullDistSq) {
					p = p.next;
					continue;
				}
			}
			if (frustumCull) {
				cullPoint.set(p.x, p.y, p.z);
				if (!frustum.hasPoint(cullPoint)) {
					p = p.next;
					continue;
				}
			}

			var ratio = p.size * p.ratio * (tile.height / tile.width);

			if (pos >= tmp.length) {
				var stride = 40 + (hasColor ? 16 : 0);
				var newLen = tmp.length == 0 ? stride * 64 : tmp.length * 2;
				while (newLen <= pos)
					newLen *= 2;
				tmp.grow(newLen);
			}

			tmp[pos++] = p.x;
			tmp[pos++] = p.y;
			tmp[pos++] = p.z;
			tmp[pos++] = p.size;
			tmp[pos++] = ratio;
			tmp[pos++] = p.rotation;
			// delta
			tmp[pos++] = -0.5;
			tmp[pos++] = -0.5;
			// UV
			tmp[pos++] = tile.u;
			tmp[pos++] = tile.v2;
			// RBGA
			if (hasColor) {
				tmp[pos++] = p.r;
				tmp[pos++] = p.g;
				tmp[pos++] = p.b;
				tmp[pos++] = p.a;
			}

			tmp[pos++] = p.x;
			tmp[pos++] = p.y;
			tmp[pos++] = p.z;
			tmp[pos++] = p.size;
			tmp[pos++] = ratio;
			tmp[pos++] = p.rotation;
			tmp[pos++] = -0.5;
			tmp[pos++] = 0.5;
			tmp[pos++] = tile.u;
			tmp[pos++] = tile.v;
			if (hasColor) {
				tmp[pos++] = p.r;
				tmp[pos++] = p.g;
				tmp[pos++] = p.b;
				tmp[pos++] = p.a;
			}

			tmp[pos++] = p.x;
			tmp[pos++] = p.y;
			tmp[pos++] = p.z;
			tmp[pos++] = p.size;
			tmp[pos++] = ratio;
			tmp[pos++] = p.rotation;
			tmp[pos++] = 0.5;
			tmp[pos++] = -0.5;
			tmp[pos++] = tile.u2;
			tmp[pos++] = tile.v2;
			if (hasColor) {
				tmp[pos++] = p.r;
				tmp[pos++] = p.g;
				tmp[pos++] = p.b;
				tmp[pos++] = p.a;
			}

			tmp[pos++] = p.x;
			tmp[pos++] = p.y;
			tmp[pos++] = p.z;
			tmp[pos++] = p.size;
			tmp[pos++] = ratio;
			tmp[pos++] = p.rotation;
			tmp[pos++] = 0.5;
			tmp[pos++] = 0.5;
			tmp[pos++] = tile.u2;
			tmp[pos++] = tile.v;
			if (hasColor) {
				tmp[pos++] = p.r;
				tmp[pos++] = p.g;
				tmp[pos++] = p.b;
				tmp[pos++] = p.a;
			}

			p = p.next;
		}

		if (pos != 0) {
			var stride = 10;
			if (hasColor)
				stride += 4;
			var len = Std.int(pos / stride);
			if (buffer == null || bufferSize < len) {
				var newCapacity = bufferSize == 0 ? 64 : bufferSize * 2;
				while (newCapacity < len)
					newCapacity *= 2;
				tmp.grow(newCapacity * stride);
				if (buffer != null)
					buffer.dispose();
				buffer = h3d.Buffer.ofSubFloats(tmp, stride, newCapacity, [Quads, Dynamic, RawFormat]);
				bufferSize = newCapacity;
			}
			buffer.uploadVector(tmp, 0, len);
			if (pshader.is3D)
				pshader.size.set(globalSize, globalSize);
			else
				pshader.size.set(globalSize * ctx.engine.height / ctx.engine.width * 4, globalSize * 4);
			ctx.uploadParams();
			var verts = Std.int(pos / stride);
			var vertsPerTri = 2;
			ctx.engine.renderQuadBuffer(buffer, 0, verts >> 1); // buffer, 0, Std.int(pos / stride));
		}
	}

	override function onRemove() {
		super.onRemove();
		if (buffer != null) {
			buffer.dispose();
			buffer = null;
		}
	}
}
