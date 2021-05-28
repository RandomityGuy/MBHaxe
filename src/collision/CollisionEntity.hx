package collision;

import dif.math.Point3F;
import dif.math.PlaneF;
import h3d.col.Plane;
import octree.Octree;
import h3d.col.Ray;
import h3d.Vector;
import octree.IOctreeObject;
import h3d.Matrix;
import h3d.col.Bounds;

class CollisionEntity implements IOctreeObject {
	public var boundingBox:Bounds;

	var octree:Octree;

	public var surfaces:Array<CollisionSurface>;

	public var priority:Int;
	public var position:Int;

	var transform:Matrix;

	public function new() {
		this.octree = new Octree();
		this.surfaces = [];
		this.transform = Matrix.I();
	}

	public function addSurface(surface:CollisionSurface) {
		this.octree.insert(surface);
		this.surfaces.push(surface);
	}

	public function generateBoundingBox() {
		var boundingBox = new Bounds();
		for (surface in this.surfaces) {
			var tform = surface.boundingBox.clone();
			tform.transform(transform);
			boundingBox.add(tform);
		}
		this.boundingBox = boundingBox;
	}

	public function isIntersectedByRay(rayOrigin:Vector, rayDirection:Vector, intersectionPoint:Vector):Bool {
		// TEMP cause bruh
		return boundingBox.rayIntersection(Ray.fromValues(rayOrigin.x, rayOrigin.y, rayOrigin.z, rayDirection.x, rayDirection.y, rayDirection.z), true) != -1;
	}

	public function getElementType() {
		return 2;
	}

	public function setPriority(priority:Int) {
		this.priority = priority;
	}

	public function sphereIntersection(position:Vector, velocity:Vector, radius:Float) {
		var invMatrix = transform.clone();
		invMatrix.invert();
		var localpos = position.clone();
		localpos.transform(invMatrix);

		var bigRad = 2 * velocity.length() + radius * 1.1;

		var surfaces = octree.radiusSearch(position, radius * 1.1);

		var contacts = [];

		function toDifPoint(pt:Vector) {
			return new Point3F(pt.x, pt.y, pt.z);
		}

		function fromDifPoint(pt:Point3F) {
			return new Vector(pt.x, pt.y, pt.z);
		}

		for (obj in surfaces) {
			var surface:CollisionSurface = cast obj;

			var i = 0;
			while (i < surface.indices.length) {
				var v0 = surface.points[surface.indices[i]];
				var v = surface.points[surface.indices[i + 1]];
				var v2 = surface.points[surface.indices[i + 2]];

				// var packet = new CollisionPacket(position, velocity, new Vector(radius, radius, radius));
				// packet.e_base_point = packet.e_position.clone();
				// packet.e_norm_velocity = packet.e_velocity.clone().normalized();
				// packet.nearest_distance = 1e20;

				// var plane = PlaneF.PointNormal(toDifPoint(v), toDifPoint(surface.normals[surface.indices[i]]));

				// var retpacket = Collision.CheckTriangle(packet, v0.multiply(1 / radius), v.multiply(1 / radius), v2.multiply(1 / radius));

				// if (retpacket.found_collision) {
				// 	var cinfo = new CollisionInfo();
				// 	cinfo.restitution = 1;
				// 	cinfo.friction = 1;
				// 	cinfo.normal = surface.normals[surface.indices[i]];
				// 	cinfo.point = retpacket.intersect_point;
				// 	cinfo.velocity = new Vector();
				// 	cinfo.collider = null;
				// 	cinfo.penetration = radius - (position.sub(cinfo.point).dot(cinfo.normal));
				// 	contacts.push(cinfo);
				// }
				// var plane = PlaneF.ThreePoints(toDifPoint(v0), toDifPoint(v), toDifPoint(v2));

				// var distance = plane.distance(toDifPoint(position));

				// if (Math.abs(distance) <= radius + 0.001) {
				// 	var lastVertex = surface.points[surface.indices[surface.indices.length - 1]];

				// 	var contactVert = plane.project(toDifPoint(position));
				// 	var separation = Math.sqrt(radius * radius - distance * distance);

				// 	for (j in 0...surface.indices.length) {
				// 		var vertex = surface.points[surface.indices[i]];
				// 		if (vertex != lastVertex) {
				// 			var vertPlane = PlaneF.ThreePoints(toDifPoint(vertex).add(plane.getNormal()), toDifPoint(vertex), toDifPoint(lastVertex));
				// 			var vertDistance = vertPlane.distance(contactVert);
				// 			if (vertDistance < 0.0) {
				// 				if (vertDistance < -(separation + 0.0001))
				// 					return contacts;
				// 				// return contacts;

				// 				if (PlaneF.ThreePoints(vertPlane.getNormal().add(toDifPoint(vertex)), toDifPoint(vertex),
				// 					toDifPoint(vertex).add(plane.getNormal()))
				// 					.distance(contactVert) >= 0.0) {
				// 					if (PlaneF.ThreePoints(toDifPoint(lastVertex).sub(vertPlane.getNormal()), toDifPoint(lastVertex),
				// 						toDifPoint(lastVertex).add(plane.getNormal()))
				// 						.distance(contactVert) >= 0.0) {
				// 						contactVert = vertPlane.project(contactVert);
				// 						break;
				// 					}
				// 					contactVert = toDifPoint(lastVertex);
				// 				} else {
				// 					contactVert = toDifPoint(vertex);
				// 				}
				// 			}
				// 			lastVertex = vertex;
				// 		}

				// 		var cinfo = new CollisionInfo();
				// 		cinfo.restitution = 1;
				// 		cinfo.friction = 1;
				// 		cinfo.normal = surface.normals[i];
				// 		cinfo.point = fromDifPoint(contactVert);
				// 		cinfo.velocity = new Vector();
				// 		cinfo.collider = null;
				// 		cinfo.penetration = radius - (position.sub(cinfo.point).dot(cinfo.normal));
				// 		contacts.push(cinfo);
				// 	}
				// }

				// 	// var norm = Plane.fromPoints(v0.toPoint(), v.toPoint(), v2.toPoint());

				// 	var cinfo = new CollisionInfo();
				// 	cinfo.restitution = 1;
				// 	cinfo.friction = 1;
				// 	cinfo.normal = surface.normals[i];
				// 	cinfo.point = fromDifPoint(contactVert);
				// 	cinfo.velocity = new Vector();
				// 	cinfo.collider = null;
				// 	cinfo.penetration = radius - (position.sub(cinfo.point).dot(cinfo.normal));
				// 	contacts.push(cinfo);
				// }

				var res = Collision.IntersectTriangleSphere(v0, v, v2, surface.normals[surface.indices[i]], position, radius);
				var closest = res.point;
				// Collision.ClosestPtPointTriangle(position, radius, v0, v, v2, surface.normals[surface.indices[i]]);
				if (res.result) {
					if (position.sub(closest).lengthSq() < radius * radius) {
						var normal = res.normal;

						if (position.sub(closest).dot(surface.normals[surface.indices[i]]) > 0) {
							normal.normalize();

							var cinfo = new CollisionInfo();
							cinfo.normal = res.normal; // surface.normals[surface.indices[i]];
							cinfo.point = closest;
							// cinfo.collider = this;
							cinfo.velocity = new Vector();
							cinfo.penetration = radius - (position.sub(closest).dot(normal));
							cinfo.restitution = 1;
							cinfo.friction = 1;
							contacts.push(cinfo);
						}
					}
				}

				// var res = Collision.IntersectTriangleSphere(v0, v, v2, surface.normals[surface.indices[i]], position, radius);
				// var closest = res.point;
				// var closest = Collision.ClosestPtPointTriangle(position, radius, v0, v, v2, surface.normals[surface.indices[i]]);
				// if (closest != null) {
				// 	if (position.sub(closest).lengthSq() < radius * radius) {
				// 		var normal = position.sub(closest);

				// 		if (position.sub(closest).dot(surface.normals[surface.indices[i]]) > 0) {
				// 			normal.normalize();

				// 			var cinfo = new CollisionInfo();
				// 			cinfo.normal = normal;
				// 			cinfo.point = closest;
				// 			// cinfo.collider = this;
				// 			cinfo.velocity = new Vector();
				// 			cinfo.penetration = radius - (position.sub(closest).dot(normal));
				// 			cinfo.restitution = 1;
				// 			cinfo.friction = 1;
				// 			contacts.push(cinfo);
				// 		}
				// 	}
				// }

				i += 3;
			}
		}

		return contacts;
	}
}
