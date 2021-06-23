package shaders;

import h3d.scene.Light;

class DirLight extends Light {
	var dshader:DirLightShader;

	public function new(?dir:h3d.Vector, ?parent) {
		dshader = new DirLightShader();
		super(dshader, parent);
		priority = 100;
		if (dir != null)
			setDirection(dir);
	}

	override function get_color() {
		return dshader.color;
	}

	override function set_color(v) {
		return dshader.color = v;
	}

	override function get_enableSpecular() {
		return dshader.enableSpecular;
	}

	override function set_enableSpecular(b) {
		return dshader.enableSpecular = b;
	}

	override function getShadowDirection():h3d.Vector {
		return absPos.front();
	}

	override function emit(ctx) {
		dshader.direction.load(absPos.front());
		dshader.direction.normalize();
		super.emit(ctx);
	}
}
