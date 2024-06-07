package src;

private class ParticleIterator {
	var p:ParticleElement;

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

class ParticleElement {
	public var parts:ParticlesMesh;

	public var x:Float;
	public var y:Float;
	public var z:Float;

	public var w:Float; // used for sorting

	public var r:Float;
	public var g:Float;
	public var b:Float;
	public var a:Float;
	public var alpha(get, set):Float;

	public var frame:Int;

	public var size:Float;
	public var ratio:Float;
	public var rotation:Float;

	public var prev:ParticleElement;
	public var next:ParticleElement;

	// --- Particle emitter ---
	public var time:Float;
	public var lifeTimeFactor:Float;

	public var dx:Float;
	public var dy:Float;
	public var dz:Float;

	public var fx:Float;
	public var fy:Float;
	public var fz:Float;

	public var randIndex = 0;
	public var randValues:Array<Float>;

	// -------------------------

	public function new() {
		r = 1;
		g = 1;
		b = 1;
		a = 1;
		frame = 0;
	}

	inline function get_alpha()
		return a;

	inline function set_alpha(v)
		return a = v;

	public function setColor(color:Int, alpha = 1.) {
		a = alpha;
		r = ((color >> 16) & 0xFF) / 255.;
		g = ((color >> 8) & 0xFF) / 255.;
		b = (color & 0xFF) / 255.;
	}

	public function remove() {
		if (parts != null) {
			@:privateAccess parts.kill(this);
			parts = null;
		}
	}

	public function rand():Float {
		if (randValues == null)
			randValues = [];
		if (randValues.length <= randIndex)
			randValues.push(Math.random());
		return randValues[randIndex++];
	}
}

class ParticlesMesh extends h3d.scene.Mesh {
	var pshader:h3d.shader.ParticleShader;

	public var frames:Array<h2d.Tile>;
	public var count(default, null):Int = 0;
	public var hasColor(default, set):Bool;
	public var sortMode:SortMode;
	public var globalSize:Float = 1;

	var head:ParticleElement;
	var tail:ParticleElement;
	var pool:ParticleElement;

	var tmp:h3d.Vector;
	var tmpBuf:hxd.FloatBuffer;
	var buffer:h3d.Buffer;
	var bufferSize:Int = 0;

	public function new(?texture, ?parent) {
		super(null, null, parent);
		material.props = material.getDefaultProps("particles3D");
		sortMode = Back;
		pshader = new h3d.shader.ParticleShader();
		pshader.isAbsolute = true;
		material.mainPass.addShader(pshader);
		material.mainPass.dynamicParameters = true;
		material.texture = texture;
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

	/**
		Offset all existing particles by the given values.
	**/
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

	public function alloc() {
		var p = emitParticle();
		if (posChanged)
			syncPos();
		p.parts = this;
		p.x = absPos.tx;
		p.y = absPos.ty;
		p.z = absPos.tz;
		p.rotation = 0;
		p.ratio = 1;
		p.size = 1;
		p.r = p.g = p.b = p.a = 1;
		return p;
	}

	public function add(p) {
		emitParticle(p);
		return p;
	}

	function emitParticle(?p) {
		if (p == null) {
			if (pool == null)
				p = new ParticleElement();
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

	function kill(p:ParticleElement) {
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

	function sort(list:ParticleElement) {
		return haxe.ds.ListSort.sort(list, function(p1, p2) return p1.w < p2.w ? 1 : -1);
	}

	function sortInv(list:ParticleElement) {
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
		if (frames == null || frames.length == 0) {
			var t = material.texture == null ? h2d.Tile.fromColor(0xFF00FF) : h2d.Tile.fromTexture(material.texture);
			frames = [t];
		}
		material.texture = frames[0].getTexture();

		while (p != null) {
			var f = frames[p.frame];
			if (f == null)
				f = frames[0];
			var ratio = p.size * p.ratio * (f.height / f.width);

			if (pos >= tmp.length) {
				tmp.grow(tmp.length + 40 + (hasColor ? 16 : 0));
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
			tmp[pos++] = f.u;
			tmp[pos++] = f.v2;
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
			tmp[pos++] = f.u;
			tmp[pos++] = f.v;
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
			tmp[pos++] = f.u2;
			tmp[pos++] = f.v2;
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
			tmp[pos++] = f.u2;
			tmp[pos++] = f.v;
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
			if (buffer == null) {
				buffer = h3d.Buffer.ofSubFloats(tmp, stride, Std.int(pos / stride), [Quads, Dynamic, RawFormat]);
				bufferSize = Std.int(pos / stride);
			} else {
				var len = Std.int(pos / stride);
				if (bufferSize < len) {
					buffer.dispose();
					buffer = h3d.Buffer.ofSubFloats(tmp, stride, Std.int(pos / stride), [Quads, Dynamic, RawFormat]);
					bufferSize = Std.int(pos / stride);
				} else {
					buffer.uploadVector(tmp, 0, len);
				}
			}
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
