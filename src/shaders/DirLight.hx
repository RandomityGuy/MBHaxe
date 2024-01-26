package shaders;

import src.MarbleGame;
import h3d.scene.fwd.Light;

class DirLight extends Light {
	var dshader:DirLightShader;

	public var direction:h3d.Vector;

	public function new(?dir:h3d.Vector, ?parent) {
		dshader = new DirLightShader();
		super(dshader, parent);
		priority = 100;
		direction = dir;
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
		if (MarbleGame.instance.world == null || MarbleGame.instance.world.marble == null)
			return new h3d.Vector(0, 0, -1);
		return MarbleGame.instance.world.marble.currentUp.multiply(-1);
	}

	override function emit(ctx) {
		dshader.direction.load(absPos.front());
		dshader.direction.normalize();
		super.emit(ctx);
	}
}
