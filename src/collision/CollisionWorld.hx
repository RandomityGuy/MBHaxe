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
	public var grid:GridBroadphase;
	public var entities:Array<CollisionEntity> = [];
	public var dynamicEntities:Array<CollisionEntity> = [];
	public var dynamicGrid:GridBroadphase;

	public var marbleEntities:Array<SphereCollisionEntity> = [];

	var dynamicEntitySet:Map<CollisionEntity, Bool> = [];

	public function new() {
		this.grid = new GridBroadphase();
		this.dynamicGrid = new GridBroadphase();
		this.staticWorld = new CollisionEntity(null);
	}

	public function build() {
		this.grid.build();
		this.dynamicGrid.setBounds(this.grid.bounds);
		this.dynamicGrid.build();
	}

	var contactList:Array<CollisionInfo> = [];
	var intersectionList:Array<CollisionEntity> = [];

	public function sphereIntersection(spherecollision:SphereCollisionEntity, timeState:TimeState, contacts:Array<CollisionInfo>) {
		var position = spherecollision.transform.getPosition();
		var radius = spherecollision.radius;

		var box = new Bounds();
		box.addSpherePos(0, 0, 0, radius);
		var rotQuat = spherecollision.marble.getRotationQuat();
		box.transform(rotQuat.toMatrix());
		box.offset(position.x, position.y, position.z);
		// box.addSpherePos(position.x + velocity.x * timeState.dt, position.y + velocity.y * timeState.dt, position.z + velocity.z * timeState.dt, radius);
		this.intersectionList.resize(0);
		this.grid.boundingSearch(box, this.intersectionList);
		dynamicGrid.boundingSearch(box, this.intersectionList);

		for (obj in this.intersectionList) {
			if (obj != spherecollision) {
				var entity = obj;

				if (obj.boundingBox.collide(box) && entity.go.isCollideable) {
					entity.sphereIntersection(spherecollision, timeState, contacts);
				}
			}
		}
	}

	public function boundingSearch(bounds:Bounds, contacts:Array<CollisionEntity>, useCache:Bool = true) {
		this.grid.boundingSearch(bounds, contacts);
		dynamicGrid.boundingSearch(bounds, contacts);
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
		this.intersectionList.resize(0);

		this.grid.boundingSearch(bounds, this.intersectionList);
		dynamicGrid.boundingSearch(bounds, this.intersectionList);

		var results = [];
		for (obj in this.intersectionList) {
			var oo = obj;
			oo.rayCast(rayStart, rayDirection, results, rayLength);
		}

		return results;
	}

	public function addEntity(entity:CollisionEntity) {
		this.grid.insert(entity);
		this.entities.push(entity);

		// this.rtree.insert([entity.boundingBox.xMin, entity.boundingBox.yMin, entity.boundingBox.zMin],
		// 	[entity.boundingBox.xSize, entity.boundingBox.ySize, entity.boundingBox.zSize], entity);
	}

	public function removeEntity(entity:CollisionEntity) {
		this.entities.remove(entity);
		this.grid.remove(entity);
	}

	public function addMarbleEntity(entity:SphereCollisionEntity) {
		this.marbleEntities.push(entity);
	}

	public function removeMarbleEntity(entity:SphereCollisionEntity) {
		this.marbleEntities.remove(entity);
	}

	public function addMovingEntity(entity:CollisionEntity) {
		this.dynamicEntities.push(entity);
		this.dynamicGrid.insert(entity);
		this.dynamicEntitySet.set(entity, true);
	}

	public function removeMovingEntity(entity:CollisionEntity) {
		this.dynamicEntities.remove(entity);
		this.dynamicGrid.remove(entity);
		this.dynamicEntitySet.remove(entity);
	}

	public function updateTransform(entity:CollisionEntity) {
		if (!dynamicEntitySet.exists(entity)) {
			this.grid.update(entity);
		} else {
			this.dynamicGrid.update(entity);
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
		grid = null;
		entities = null;
		dynamicEntities = null;
		dynamicGrid = null;
		dynamicEntitySet = null;
		staticWorld.dispose();
		staticWorld = null;
	}
}
