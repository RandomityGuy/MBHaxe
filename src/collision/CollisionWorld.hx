package collision;

import h3d.col.Sphere;
import h3d.Vector;
import octree.Octree;

class CollisionWorld {
	public var octree:Octree;
	public var entities:Array<CollisionEntity> = [];
	public var dynamicEntities:Array<CollisionEntity> = [];

	public function new() {
		this.octree = new Octree();
	}

	public function sphereIntersection(spherecollision:SphereCollisionEntity) {
		var position = spherecollision.transform.getPosition();
		var radius = spherecollision.radius;
		var velocity = spherecollision.velocity;
		var searchdist = velocity.length() + radius;
		var intersections = this.octree.radiusSearch(position, searchdist);

		var contacts = [];

		for (obj in intersections) {
			var entity:CollisionEntity = cast obj;

			contacts = contacts.concat(entity.sphereIntersection(spherecollision));
		}

		for (obj in dynamicEntities) {
			if (obj != spherecollision) {
				contacts = contacts.concat(obj.sphereIntersection(spherecollision));
			}
		}
		return contacts;
	}

	public function addEntity(entity:CollisionEntity) {
		this.octree.insert(entity);
		this.entities.push(entity);
	}

	public function addMovingEntity(entity:CollisionEntity) {
		this.dynamicEntities.push(entity);
	}
}
