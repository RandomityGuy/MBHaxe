package collision;

import h3d.Matrix;
import src.MarbleGame;
import src.TimeState;
import h3d.col.Bounds;
import h3d.col.Sphere;
import h3d.Vector;
import octree.Octree;

@:structInit
@:publicFields
class SphereIntersectionResult {
	var foundEntities:Array<CollisionEntity>;
	var contacts:Array<CollisionInfo>;
}

class CollisionWorld {
	public var staticWorld:CollisionEntity;
	public var octree:Octree;
	public var entities:Array<CollisionEntity> = [];
	public var dynamicEntities:Array<CollisionEntity> = [];
	public var dynamicOctree:Octree;

	public var marbleEntities:Array<SphereCollisionEntity> = [];

	var dynamicEntitySet:Map<CollisionEntity, Bool> = [];

	public function new() {
		this.octree = new Octree();
		this.dynamicOctree = new Octree(true);
		this.staticWorld = new CollisionEntity(null);
	}

	public function sphereIntersection(spherecollision:SphereCollisionEntity, timeState:TimeState):SphereIntersectionResult {
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

		// if (marbleEntities.length > 1) {
		// 	marbleSap.recompute();
		// 	var sapCollisions = marbleSap.getIntersections(spherecollision);
		// 	for (obj in sapCollisions) {
		// 		if (obj.go.isCollideable) {
		// 			contacts = contacts.concat(obj.sphereIntersection(spherecollision, timeState));
		// 		}
		// 	}
		// }

		// contacts = contacts.concat(this.staticWorld.sphereIntersection(spherecollision, timeState));

		var dynSearch = dynamicOctree.boundingSearch(box);
		for (obj in dynSearch) {
			if (obj != spherecollision) {
				var col = cast(obj, CollisionEntity);
				if (col.boundingBox.collide(box) && col.go.isCollideable)
					contacts = contacts.concat(col.sphereIntersection(spherecollision, timeState));
			}
		}

		// for (marb in marbleEntities) {
		// 	if (marb != spherecollision) {
		// 		if (spherecollision.go.isCollideable) {
		// 			var isecs = marb.sphereIntersection(spherecollision, timeState);
		// 			if (isecs.length > 0)
		// 				foundEntities.push(marb);
		// 			contacts = contacts.concat(isecs);
		// 		}
		// 	}
		// }
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
		var objs = this.octree.boundingSearch(bounds);
		var dynObjs = dynamicOctree.boundingSearch(bounds);
		var results = [];
		for (obj in objs) {
			var oo = cast(obj, CollisionEntity);
			oo.rayCast(rayStart, rayDirection, results, rayLength);
		}

		for (obj in dynObjs) {
			var oo = cast(obj, CollisionEntity);
			oo.rayCast(rayStart, rayDirection, results, rayLength);
		}
		// results = results.concat(this.staticWorld.rayCast(rayStart, rayDirection));
		return results;
	}

	public function addEntity(entity:CollisionEntity) {
		if (this.octree.insert(entity))
			this.entities.push(entity);

		// this.rtree.insert([entity.boundingBox.xMin, entity.boundingBox.yMin, entity.boundingBox.zMin],
		// 	[entity.boundingBox.xSize, entity.boundingBox.ySize, entity.boundingBox.zSize], entity);
	}

	public function removeEntity(entity:CollisionEntity) {
		this.entities.remove(entity);
		this.octree.remove(entity);
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
		this.dynamicOctree.remove(entity);
		this.dynamicEntitySet.remove(entity);
	}

	public function updateTransform(entity:CollisionEntity) {
		if (!dynamicEntitySet.exists(entity)) {
			this.octree.update(entity);
		} else {
			this.dynamicOctree.update(entity);
		}
	}

	public function addStaticInterior(entity:CollisionEntity, transform:Matrix) {
		var invTform = transform.getInverse();
		for (surf in entity.surfaces) {
			staticWorld.addSurface(surf.getTransformed(transform, invTform));
		}
	}

	public function finalizeStaticGeometry() {
		this.staticWorld.finalize();
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
		staticWorld.dispose();
		staticWorld = null;
	}
}
