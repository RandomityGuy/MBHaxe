package collision;

import h3d.col.Bounds;
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

	public function sphereIntersection(spherecollision:SphereCollisionEntity, dt:Float) {
		var position = spherecollision.transform.getPosition();
		var radius = spherecollision.radius;
		var velocity = spherecollision.velocity;
		var searchdist = (velocity.length() * dt) + radius;
		var intersections = this.octree.radiusSearch(position, searchdist);

		var contacts = [];

		for (obj in intersections) {
			var entity:CollisionEntity = cast obj;

			contacts = contacts.concat(entity.sphereIntersection(spherecollision, dt));
		}

		for (obj in dynamicEntities) {
			if (obj != spherecollision) {
				contacts = contacts.concat(obj.sphereIntersection(spherecollision, dt));
			}
		}
		return contacts;
	}

	public function radiusSearch(center:Vector, radius:Float) {
		var intersections = this.octree.radiusSearch(center, radius);

		var box = new Bounds();
		box.xMin = center.x - radius;
		box.yMin = center.y - radius;
		box.zMin = center.z - radius;
		box.xMax = center.x + radius;
		box.yMax = center.y + radius;
		box.zMax = center.z + radius;

		var contacts:Array<CollisionEntity> = [];

		for (obj in intersections) {
			var entity:CollisionEntity = cast obj;

			contacts.push(entity);
		}

		for (obj in dynamicEntities) {
			if (obj.boundingBox.collide(box))
				contacts.push(obj);
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
