package collision;

import src.TimeState;
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

	public function sphereIntersection(spherecollision:SphereCollisionEntity, timeState:TimeState) {
		var position = spherecollision.transform.getPosition();
		var radius = spherecollision.radius;
		var velocity = spherecollision.velocity;
		var searchdist = (velocity.length() * timeState.dt) + radius;
		// var intersections = this.octree.radiusSearch(position, searchdist);

		var box = new Bounds();
		box.xMin = position.x - radius;
		box.yMin = position.y - radius;
		box.zMin = position.z - radius;
		box.xMax = position.x + radius;
		box.yMax = position.y + radius;
		box.zMax = position.z + radius;
		var intersections = this.octree.boundingSearch(box);

		// var intersections = this.rtree.search([box.xMin, box.yMax, box.zMin], [box.xSize, box.ySize, box.zSize]);

		var contacts = [];
		var foundEntities = [];

		for (obj in intersections) {
			var entity:CollisionEntity = cast obj;

			foundEntities.push(entity);
			if (entity.go.isCollideable) {
				contacts = contacts.concat(entity.sphereIntersection(spherecollision, timeState));
			}
		}

		for (obj in dynamicEntities) {
			if (obj != spherecollision) {
				// if (obj.boundingBox.collide(box) && obj.go.isCollideable)
				contacts = contacts.concat(obj.sphereIntersection(spherecollision, timeState));
			}
		}
		return {foundEntities: foundEntities, contacts: contacts};
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

	public function boundingSearch(bounds:Bounds) {
		var contacts = this.octree.boundingSearch(bounds).map(x -> cast(x, CollisionEntity));
		for (obj in dynamicEntities) {
			if (obj.boundingBox.collide(bounds))
				contacts.push(obj);
		}
		return contacts;
	}

	public function rayCast(rayStart:Vector, rayDirection:Vector) {
		return [];
		return this.octree.raycast(rayStart, rayDirection);
	}

	public function addEntity(entity:CollisionEntity) {
		this.octree.insert(entity);
		this.entities.push(entity);

		// this.rtree.insert([entity.boundingBox.xMin, entity.boundingBox.yMin, entity.boundingBox.zMin],
		// 	[entity.boundingBox.xSize, entity.boundingBox.ySize, entity.boundingBox.zSize], entity);
	}

	public function addMovingEntity(entity:CollisionEntity) {
		this.dynamicEntities.push(entity);
	}

	public function updateTransform(entity:CollisionEntity) {
		this.octree.remove(entity);
		this.octree.insert(entity);
	}
}
