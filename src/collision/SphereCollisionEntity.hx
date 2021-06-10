package collision;

import src.Marble;
import h3d.col.Ray;
import h3d.Vector;
import h3d.col.Sphere;
import h3d.col.Bounds;

class SphereCollisionEntity extends CollisionEntity {
	public var radius:Float;
	public var marble:Marble;

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
		this.boundingBox = boundingBox;
	}

	public override function isIntersectedByRay(rayOrigin:Vector, rayDirection:Vector, intersectionPoint:Vector):Bool {
		// TEMP cause bruh
		return false;
		return boundingBox.rayIntersection(Ray.fromValues(rayOrigin.x, rayOrigin.y, rayOrigin.z, rayDirection.x, rayDirection.y, rayDirection.z), true) != -1;
	}

	public override function sphereIntersection(collisionEntity:SphereCollisionEntity, dt:Float) {
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
			contact.velocity = this.velocity;
			contact.otherObject = this.go;
			contact.point = position.add(normDist);
			contact.normal = normDist.multiply(-1);
			contact.force = 0;
			contact.contactDistance = contact.point.distance(position);
			contact.penetration = radius - (position.sub(contact.point).dot(contact.normal));
			contacts.push(contact);

			// var othercontact = new CollisionInfo();
			// othercontact.collider = collisionEntity;
			// othercontact.friction = 1;
			// othercontact.restitution = 1;
			// othercontact.velocity = this.velocity;
			// othercontact.point = thispos.add(position).multiply(0.5);
			// othercontact.normal = contact.point.sub(position).normalized();
			// othercontact.contactDistance = contact.point.distance(position);
			// othercontact.force = 0;
			// othercontact.penetration = this.radius - (thispos.sub(othercontact.point).dot(othercontact.normal));
			// this.marble.queueCollision(othercontact);
		}
		return contacts;
	}
}
