package collision;

import h3d.Vector;
import octree.Octree;

class CollisionWorld {
	public var octree:Octree;

	public function new() {
		this.octree = new Octree();
	}

	public function sphereIntersection(position:Vector, velocity:Vector, radius:Float) {
		var searchdist = velocity.length() + radius;
		var intersections = this.octree.radiusSearch(position, searchdist);

		var contacts = [];

		for (obj in intersections) {
			var entity:CollisionEntity = cast obj;

			contacts = contacts.concat(entity.sphereIntersection(position, velocity, radius));
		}
		return contacts;
	}

	public function addEntity(entity:CollisionEntity) {
		this.octree.insert(entity);
	}
}
