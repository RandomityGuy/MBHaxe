package triggers;

import src.TimeState;
import h3d.scene.Mesh;
import h3d.mat.Material;
import h3d.prim.Cube;
import h3d.col.Bounds;
import h3d.Matrix;
import h3d.Vector;
import mis.MisParser;
import collision.BoxCollisionEntity;
import mis.MissionElement.MissionElementTrigger;
import src.GameObject;
import src.MarbleWorld;

class Trigger extends GameObject {
	var id:Float;
	var level:MarbleWorld;
	var element:MissionElementTrigger;

	var vertices:Array<Vector>;

	public var collider:BoxCollisionEntity;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super();
		this.element = element;
		this.id = element._id;
		this.level = level;
		var coordinates = MisParser.parseNumberList(element.polyhedron);

		var origin = new Vector(-coordinates[0], coordinates[1], coordinates[2]);
		var d1 = new Vector(-coordinates[3], coordinates[4], coordinates[5]);
		var d2 = new Vector(-coordinates[6], coordinates[7], coordinates[8]);
		var d3 = new Vector(-coordinates[9], coordinates[10], coordinates[11]);

		// Create the 8 points of the parallelepiped
		var p1 = origin.clone();
		var p2 = origin.add(d1);
		var p3 = origin.add(d2);
		var p4 = origin.add(d3);
		var p5 = origin.add(d1).add(d2);
		var p6 = origin.add(d1).add(d3);
		var p7 = origin.add(d2).add(d3);
		var p8 = origin.add(d1).add(d2).add(d3);

		var mat = new Matrix();
		var quat = MisParser.parseRotation(element.rotation);
		quat.x = -quat.x;
		// quat.w = -quat.w;
		quat.toMatrix(mat);
		var scale = MisParser.parseVector3(element.scale);
		mat.scale(scale.x, scale.y, scale.z);
		var pos = MisParser.parseVector3(element.position);
		pos.x = -pos.x;
		// mat.setPosition(pos);

		vertices = [p1, p2, p3, p4, p5, p6, p7, p8].map((vert) -> vert.transformed(mat));

		var boundingbox = new Bounds();
		for (vector in vertices) {
			boundingbox.addPoint(vector.add(pos).toPoint());
		}

		collider = new BoxCollisionEntity(boundingbox, this);

		// var cub = new Cube(boundingbox.xSize, boundingbox.ySize, boundingbox.zSize);
		// cub.addUVs();
		// cub.addNormals();
		// var mat = Material.create();
		// mat.mainPass.wireframe = true;
		// var mesh = new Mesh(cub, mat, level.scene);
		// // var m1 = new Mesh(cub, mat, level.scene);
		// // m1.setPosition(boundingbox.xMin, boundingbox.yMin, boundingbox.zMin);
		// // var m2 = new Mesh(cub, mat, level.scene);
		// // m2.setPosition(boundingbox.xMax, boundingbox.yMax, boundingbox.zMax);
		// mesh.setPosition(boundingbox.xMin, boundingbox.yMin, boundingbox.zMin);
	}

	public function update(timeState:TimeState) {}

	public function init(onFinish:Void->Void) {
		onFinish();
	}
}
