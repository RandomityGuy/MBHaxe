package collision;

import src.Marble;
import h3d.col.Ray;
import h3d.Vector;
import h3d.col.Sphere;
import h3d.col.Bounds;

class SphereCollisionEntity extends CollisionEntity {
	public var radius:Float;
	public var velocity:Vector;
	public var marble:Marble;

	public function new(marble:Marble) {
		super();
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
		return boundingBox.rayIntersection(Ray.fromValues(rayOrigin.x, rayOrigin.y, rayOrigin.z, rayDirection.x, rayDirection.y, rayDirection.z), true) != -1;
	}

	public override function sphereIntersection(collisionEntity:SphereCollisionEntity) {
		var contacts = [];
		var thispos = transform.getPosition();
		var position = collisionEntity.transform.getPosition();
		var velocity = collisionEntity.velocity;
		var radius = collisionEntity.radius;

		if (position.distanceSq(thispos) < (radius + this.radius) * (radius + this.radius)) {
			var contact = new CollisionInfo();
			contact.collider = this;
			contact.friction = 1;
			contact.restitution = 1;
			contact.velocity = this.velocity;
			contact.point = position.add(thispos).multiply(0.5);
			contact.normal = contact.point.sub(thispos).normalized();
			contact.penetration = radius - (position.sub(contact.point).dot(contact.normal));
			contacts.push(contact);

			var othercontact = new CollisionInfo();
			othercontact.collider = collisionEntity;
			othercontact.friction = 1;
			othercontact.restitution = 1;
			othercontact.velocity = this.velocity;
			othercontact.point = thispos.add(position).multiply(0.5);
			othercontact.normal = contact.point.sub(position).normalized();
			othercontact.penetration = this.radius - (thispos.sub(othercontact.point).dot(othercontact.normal));
			this.marble.queueCollision(othercontact);
		}
		return contacts;
	}
}
