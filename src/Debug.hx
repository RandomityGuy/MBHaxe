package src;

import src.MarbleGame;
import h3d.Vector;

@:publicFields
class Debug {
	static var timeScale:Float = 1.0;
	static var wireFrame:Bool = false;
	static var drawBounds:Bool = false;

	static var _triangles:Array<h3d.col.Point> = [];
	static var _spheres:Array<{
		position:Vector,
		radius:Float,
		lifetime:Float
	}> = [];

	static var debugTriangles:h3d.scene.Mesh;
	static var debugSphere:src.MeshBatch;

	public static function init() {}

	public static function update(dt:Float) {
		if (_triangles.length != 0 && drawBounds) {
			var prim = new h3d.prim.Polygon(_triangles.copy());
			if (debugTriangles != null) {
				debugTriangles.remove();
			}
			debugTriangles = new h3d.scene.Mesh(prim, h3d.mat.Material.create());
			prim.addUVs();
			prim.addNormals();
			MarbleGame.instance.scene.addChild(debugTriangles);
			_triangles = [];
		} else {
			if (debugTriangles != null) {
				debugTriangles.remove();
				debugTriangles = null;
			}
		}
		if (_spheres.length != 0 && drawBounds) {
			if (debugSphere == null) {
				var sphprim = new h3d.prim.Sphere();
				sphprim.addUVs();
				sphprim.addNormals();
				debugSphere = new src.MeshBatch(sphprim, h3d.mat.Material.create());
				debugSphere.material.castShadows = false;
				debugSphere.material.receiveShadows = false;
				MarbleGame.instance.scene.addChild(debugSphere);
			}
			debugSphere.begin(_spheres.length);
			var toremove = [];
			for (sph in _spheres) {
				debugSphere.setPosition(sph.position.x, sph.position.y, sph.position.z);
				debugSphere.setScale(sph.radius);
				debugSphere.emitInstance();
				sph.lifetime -= dt;
				if (sph.lifetime < 0)
					toremove.push(sph);
			}
			for (sph in toremove)
				_spheres.remove(sph);
		} else {
			if (debugSphere != null) {
				debugSphere.remove();
				debugSphere = null;
			}
		}
	}

	public static inline function drawTriangle(p1:Vector, p2:Vector, p3:Vector) {
		if (drawBounds) {
			_triangles.push(p3.toPoint());
			_triangles.push(p2.toPoint());
			_triangles.push(p1.toPoint());
		}
	}

	public static inline function drawSphere(centre:Vector, radius:Float, lifetime = 0.032) {
		if (drawBounds)
			_spheres.push({position: centre.clone(), radius: radius, lifetime: lifetime});
	}
}
