package src;

import src.MarbleGame;
import h3d.Vector;

@:publicFields
class Debug {
	static var timeScale:Float = 1.0;
	static var wireFrame:Bool = false;
	static var drawBounds:Bool = false;

	static var _triangles:Array<h3d.col.Point> = [];

	static var debugTriangles:h3d.scene.Mesh;

	public static function update() {
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
	}

	public static function drawTriangle(p1:Vector, p2:Vector, p3:Vector) {
		_triangles.push(p3.toPoint());
		_triangles.push(p2.toPoint());
		_triangles.push(p1.toPoint());
	}
}
