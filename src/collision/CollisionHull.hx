package collision;

import src.TimeState;
import src.GameObject;
import h3d.col.Bounds;
import collision.gjk.GJK;
import collision.gjk.ConvexHull;
import h3d.Vector;

class CollisionHull extends CollisionEntity {
	var hull:ConvexHull;

	public var friction = 1.0;
	public var restitution = 1.0;
	public var force = 0.0;

	public function new(go:GameObject) {
		super(go);
	}

	public override function sphereIntersection(collisionEntity:SphereCollisionEntity, timeState:TimeState):Array<CollisionInfo> {
		var bbox = this.boundingBox;
		var box = new Bounds();
		var pos = collisionEntity.transform.getPosition();
		box.xMin = pos.x - collisionEntity.radius;
		box.yMin = pos.y - collisionEntity.radius;
		box.zMin = pos.z - collisionEntity.radius;
		box.xMax = pos.x + collisionEntity.radius;
		box.yMax = pos.y + collisionEntity.radius;
		box.zMax = pos.z + collisionEntity.radius;

		if (bbox.collide(box)) {
			var sph = new collision.gjk.Sphere();
			sph.position = pos;
			sph.radius = collisionEntity.radius;
			var newTform = this.transform.clone();
			var newpos = this.transform.getPosition().add(this.velocity.multiply(timeState.dt));
			newTform.setPosition(newpos);
			hull.setTransform(newTform);

			var pt = GJK.gjk(sph, this.hull).epa;
			if (pt != null) {
				var cinfo = new CollisionInfo();
				cinfo.normal = pt.normalized();
				cinfo.point = sph.position.sub(pt);
				cinfo.velocity = velocity;
				cinfo.contactDistance = sph.radius + pt.length();
				cinfo.restitution = restitution;
				cinfo.otherObject = this.go;
				cinfo.friction = friction;
				cinfo.force = force;
				this.go.onMarbleContact(timeState, cinfo);
				return [cinfo];
			}
		}
		return [];
	}

	public override function addSurface(surface:CollisionSurface) {
		super.addSurface(surface);
		if (hull == null)
			hull = new ConvexHull([]);
		hull.vertices = hull.vertices.concat(surface.points);
		if (surface.points.length != 0) {
			this.force = surface.force;
			this.friction = surface.friction;
			this.restitution = surface.restitution;
		}
	}
}
