package collision;

import src.MarbleGame;
import src.TimeState;
import h3d.col.Bounds;
import h3d.col.Sphere;
import h3d.Vector;
import octree.Octree;

class CollisionWorld {
	public var octree:Octree;
	public var entities:Array<CollisionEntity> = [];
	public var dynamicEntities:Array<CollisionEntity> = [];
	public var dynamicOctree:Octree;

	var marbleEntities:Array<SphereCollisionEntity> = [];

	var dynamicEntitySet:Map<CollisionEntity, Bool> = [];

	public function new() {
		this.octree = new Octree();
		this.dynamicOctree = new Octree();
	}

	public function sphereIntersection(spherecollision:SphereCollisionEntity, timeState:TimeState) {
		var position = spherecollision.transform.getPosition();
		var radius = spherecollision.radius;
		// var velocity = spherecollision.velocity;
		// var intersections = this.octree.radiusSearch(position, searchdist);

		var box = new Bounds();
		box.addSpherePos(0, 0, 0, radius);
		var rotQuat = spherecollision.marble.getRotationQuat();
		box.transform(rotQuat.toMatrix());
		box.offset(position.x, position.y, position.z);
		// box.addSpherePos(position.x + velocity.x * timeState.dt, position.y + velocity.y * timeState.dt, position.z + velocity.z * timeState.dt, radius);
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

		var dynSearch = dynamicOctree.boundingSearch(box).map(x -> cast(x, CollisionEntity));
		for (obj in dynSearch) {
			if (obj != spherecollision) {
				if (obj.boundingBox.collide(box) && obj.go.isCollideable)
					contacts = contacts.concat(obj.sphereIntersection(spherecollision, timeState));
			}
		}

		for (marb in marbleEntities) {
			if (marb != spherecollision) {
				if (spherecollision.go.isCollideable)
					contacts = contacts.concat(marb.sphereIntersection(spherecollision, timeState));
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

		contacts = contacts.concat(dynamicOctree.boundingSearch(box, false).map(x -> cast(x, CollisionEntity)));

		return contacts;
	}

	public function boundingSearch(bounds:Bounds, useCache:Bool = true) {
		var contacts = this.octree.boundingSearch(bounds, useCache).map(x -> cast(x, CollisionEntity));
		contacts = contacts.concat(dynamicOctree.boundingSearch(bounds, useCache).map(x -> cast(x, CollisionEntity)));
		return contacts;
	}

	public function rayCast(rayStart:Vector, rayDirection:Vector, rayLength:Float) {
		// 	return [];
		rayStart.w = 1;
		rayDirection.w = 1;
		var bounds = new Bounds();
		bounds.addPos(rayStart.x, rayStart.y, rayStart.z);
		bounds.addPos(rayStart.x
			+ rayDirection.x * rayLength, rayStart.y
			+ rayDirection.y * rayLength, rayStart.z
			+ rayDirection.z * rayLength);
		var objs = this.octree.boundingSearch(bounds).concat(dynamicOctree.boundingSearch(bounds)).map(x -> cast(x, CollisionEntity));
		var results = [];
		for (obj in objs) {
			results = results.concat(obj.rayCast(rayStart, rayDirection));
		}
		return results;
	}

	public function addEntity(entity:CollisionEntity) {
		this.octree.insert(entity);
		this.entities.push(entity);

		// this.rtree.insert([entity.boundingBox.xMin, entity.boundingBox.yMin, entity.boundingBox.zMin],
		// 	[entity.boundingBox.xSize, entity.boundingBox.ySize, entity.boundingBox.zSize], entity);
	}

	public function addMarbleEntity(entity:SphereCollisionEntity) {
		this.marbleEntities.push(entity);
	}

	public function removeMarbleEntity(entity:SphereCollisionEntity) {
		this.marbleEntities.remove(entity);
	}

	public function addMovingEntity(entity:CollisionEntity) {
		this.dynamicEntities.push(entity);
		this.dynamicOctree.insert(entity);
		this.dynamicEntitySet.set(entity, true);
	}

	public function removeMovingEntity(entity:CollisionEntity) {
		this.dynamicEntities.remove(entity);
	}

	public function updateTransform(entity:CollisionEntity) {
		if (!dynamicEntitySet.exists(entity)) {
			this.octree.update(entity);
		} else {
			this.dynamicOctree.update(entity);
		}
	}

	public function dispose() {
		for (e in entities) {
			e.dispose();
		}
		for (e in dynamicEntities) {
			e.dispose();
		}
		octree = null;
		entities = null;
		dynamicEntities = null;
		dynamicOctree = null;
		dynamicEntitySet = null;
	}
}
