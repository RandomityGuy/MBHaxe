package collision.gjk;

import h3d.Vector;
import h3d.Matrix;

class ConvexHull implements GJKShape {
	public var vertices:Array<Vector>;

	public var transform:Matrix;

	var _centercache:Vector;

	public function getCenter():Vector {
		if (_centercache != null)
			return _centercache;
		else {
			var sum = new Vector();
			for (v in vertices) {
				sum = sum.add(v.transformed(this.transform));
			}
			sum = sum.multiply(1 / vertices.length);
			_centercache = sum;
			return _centercache;
		}
	}

	public function new(vertices:Array<Vector>) {
		this.transform = Matrix.I();
		this.vertices = vertices;
	}

	public function setTransform(matrix:Matrix):Void {
		if (this.transform != matrix) {
			this.transform = matrix;
			this._centercache = null;
		}
	}

	public function support(direction:Vector):Vector {
		var furthestDistance:Float = Math.NEGATIVE_INFINITY;
		var furthestVertex:Vector = new Vector();

		for (v in vertices) {
			var v2 = v.transformed(transform);
			var distance:Float = v2.dot(direction);
			if (distance > furthestDistance) {
				furthestDistance = distance;
				furthestVertex.x = v2.x;
				furthestVertex.y = v2.y;
				furthestVertex.z = v2.z;
			}
		}

		return furthestVertex;
	}
}
