package collision;

import h3d.Matrix;
import src.TimeState;
import src.Marble;
import h3d.col.Ray;
import h3d.Vector;
import h3d.col.Sphere;
import h3d.col.Bounds;
import src.MarbleGame;
import src.Debug;

class SphereCollisionEntity extends CollisionEntity {
	public var radius:Float;
	public var marble:Marble;

	var _dbgEntity2:h3d.scene.Mesh;

	public function new(marble:Marble) {
		super(cast marble);
		this.marble = marble;
		this.velocity = marble.velocity;
		this.radius = marble._radius;
		this.generateBoundingBox();
	}

	public override function generateBoundingBox() {
		var boundingBox = new Bounds();
		var pos = transform.getPosition();
		boundingBox.addSpherePos(pos.x, pos.y, pos.z, radius);
		boundingBox.transform3x3(transform);
		this.boundingBox = boundingBox;

		if (Debug.drawBounds) {
			if (_dbgEntity == null) {
				var cube = new h3d.prim.Cube(this.boundingBox.xSize, this.boundingBox.ySize, this.boundingBox.zSize, true);
				cube.addNormals();
				cube.addUVs();
				_dbgEntity = new h3d.scene.Mesh(cube);
				_dbgEntity.material.mainPass.wireframe = true;
				_dbgEntity.setTransform(transform);
				MarbleGame.instance.scene.addChild(_dbgEntity);

				var cube2 = new h3d.prim.Cube(this.boundingBox.xSize, this.boundingBox.ySize, this.boundingBox.zSize, true);
				cube2.addNormals();
				cube2.addUVs();
				_dbgEntity2 = new h3d.scene.Mesh(cube2);
				_dbgEntity2.material.mainPass.wireframe = true;
				_dbgEntity2.setTransform(transform);
				MarbleGame.instance.scene.addChild(_dbgEntity2);
			} else {
				_dbgEntity.setTransform(transform);
				var cube2 = new h3d.prim.Cube(this.boundingBox.xSize, this.boundingBox.ySize, this.boundingBox.zSize, true);
				cube2.addNormals();
				cube2.addUVs();
				_dbgEntity2.primitive = cube2;
				_dbgEntity2.setPosition(pos.x, pos.y, pos.z);
			}
		}
	}

	public override function setTransform(transform:Matrix) {
		super.setTransform(transform);
		if (Debug.drawBounds) {
			if (_dbgEntity != null) {
				_dbgEntity.setTransform(transform);
			}
		}
	}

	public override function rayCast(rayOrigin:Vector, rayDirection:Vector) {
		// TEMP cause bruh
		return [];
	}

	public override function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState) {
		var contacts = [];
		var thispos = transform.getPosition();
		var position = collisionEntity.transform.getPosition();
		var velocity = collisionEntity.velocity;
		var radius = collisionEntity.radius;

		var otherDist = thispos.sub(position);
		var otherRadius = this.radius + radius;

		if (otherRadius * otherRadius * 1.01 > otherDist.lengthSq()) {
			var normDist = otherDist.normalized();
			var contact = new CollisionInfo();
			contact.collider = this;
			contact.friction = 1;
			contact.restitution = 1;
			contact.velocity = this.velocity.clone();
			contact.otherObject = this.go;
			contact.point = position.add(normDist);
			contact.normal = normDist.multiply(-1);
			contact.force = 0;
			contact.contactDistance = contact.point.distance(position);
			contact.penetration = radius - (position.sub(contact.point).dot(contact.normal));
			contacts.push(contact);

			var othercontact = new CollisionInfo();
			othercontact.collider = collisionEntity;
			othercontact.friction = 1;
			othercontact.restitution = 1;
			othercontact.velocity = collisionEntity.velocity.clone();
			othercontact.point = thispos.sub(normDist);
			othercontact.normal = normDist.clone();
			othercontact.contactDistance = contact.point.distance(position);
			othercontact.force = 0;
			othercontact.penetration = this.radius - (thispos.sub(othercontact.point).dot(othercontact.normal));
			this.marble.queueCollision(othercontact);
		}
		return contacts;
	}
}
