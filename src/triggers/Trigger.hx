package triggers;

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

	public var collider:BoxCollisionEntity;

	public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super();
		this.element = element;
		this.id = element._id;
		this.level = level;
		var coordinates = MisParser.parseNumberList(element.polyhedron);

		var origin = new Vector(coordinates[0], coordinates[1], coordinates[2]);
		var d1 = new Vector(coordinates[3], coordinates[4], coordinates[5]);
		var d2 = new Vector(coordinates[6], coordinates[7], coordinates[8]);
		var d3 = new Vector(coordinates[9], coordinates[10], coordinates[11]);

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
		quat.toMatrix(mat);
		mat.setPosition(MisParser.parseVector3(element.position));
		var scale = MisParser.parseVector3(element.scale);
		mat.scale(scale.x, scale.y, scale.z);

		var vertices = [p1, p2, p3, p4, p5, p6, p7, p8].map((vert) -> vert.transformed(mat));

		var boundingbox = new Bounds();
		for (vector in vertices) {
			boundingbox.addPoint(vector.toPoint());
		}

		collider = new BoxCollisionEntity(boundingbox, this);
	}
}
