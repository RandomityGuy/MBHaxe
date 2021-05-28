package collision;

import dif.math.Point3F;
import dif.math.PlaneF;
import h3d.col.Plane;
import h3d.Vector;

typedef ISCResult = {
	var result:Bool;
	var tSeg:Float;
	var tCap:Float;
}

typedef CPSSResult = {
	var result:Float;
	var s:Float;
	var t:Float;
	var c1:Vector;
	var c2:Vector;
}

typedef ITSResult = {
	var result:Bool;
	var normal:Vector;
	var point:Vector;
}

class Collision {
	public static function IntersectLineSphere(start:Vector, end:Vector, center:Vector, radius:Float) {
		var d = end.sub(start).normalized();
		var v = center.sub(start);
		var t = v.dot(d);
		var p = start.add(d.multiply(t));
		var dist = center.distance(p);

		if (dist > radius) {
			return null;
		} else
			return p;
	}

	public static function IntersectTriangleSphere(v0:Vector, v1:Vector, v2:Vector, normal:Vector, center:Vector, radius:Float) {
		var radiusSq = radius * radius;

		var res:ITSResult = {
			result: false,
			point: null,
			normal: null
		};

		var p = PlaneF.PointNormal(new Point3F(v0.x, v0.y, v0.z), new Point3F(normal.x, normal.y, normal.z));
		var pdist = p.distance(new Point3F(center.x, center.y, center.z));

		if (pdist < 0) {
			return res; // Dont collide internal edges
		}

		function toDifPoint(pt:Vector) {
			return new Point3F(pt.x, pt.y, pt.z);
		}

		function fromDifPoint(pt:Point3F) {
			return new Vector(pt.x, pt.y, pt.z);
		}

		if (pdist < radius) {
			var t = -toDifPoint(center).dot(p.getNormal()) / p.getNormal().lengthSq();
			var pt = fromDifPoint(p.project(toDifPoint(center))); // center.add(fromDifPoint(p.getNormal().scalar(t)));
			if (PointInTriangle(pt, v0, v1, v2)) {
				res.result = true;
				res.point = pt;
				res.normal = center.sub(pt).normalized();
				return res;
			}
			// return res;
		}

		// Check points
		if (center.sub(v0).lengthSq() < radiusSq) {
			res.result = true;
			res.point = v0;
			res.normal = center.sub(v0).normalized();
			// center.sub(v0).normalized();
			return res;
		}
		if (center.sub(v1).lengthSq() < radiusSq) {
			res.result = true;
			res.point = v1;
			res.normal = center.sub(v1).normalized();

			return res;
		}
		if (center.sub(v2).lengthSq() < radiusSq) {
			res.result = true;
			res.point = v2;
			res.normal = center.sub(v2).normalized();

			return res;
		}

		// Check edges
		var r1 = IntersectLineSphere(v0, v1, center, radius);
		if (r1 != null) {
			res.result = true;
			res.point = r1;
			res.normal = center.sub(r1).normalized();
			return res;
		}
		var r2 = IntersectLineSphere(v1, v2, center, radius);
		if (r2 != null) {
			res.result = true;
			res.point = r2;
			res.normal = center.sub(r2).normalized();
			return res;
		}
		var r3 = IntersectLineSphere(v2, v0, center, radius);
		if (r3 != null) {
			res.result = true;
			res.point = r3;
			res.normal = center.sub(r3).normalized();
			return res;
		}

		// Check plane
		// var p = PlaneF.ThreePoints(toDifPoint(v0), toDifPoint(v1), toDifPoint(v2));
		return res;
	}

	public static function IntersectSegmentCapsule(segStart:Vector, segEnd:Vector, capStart:Vector, capEnd:Vector, radius:Float) {
		var cpssres = Collision.ClosestPtSegmentSegment(segStart, segEnd, capStart, capEnd);
		var res:ISCResult = {
			result: cpssres.result < radius * radius,
			tSeg: cpssres.s,
			tCap: cpssres.t
		}
		return res;
	}

	public static function ClosestPtSegmentSegment(p1:Vector, q1:Vector, p2:Vector, q2:Vector) {
		var Epsilon = 0.0001;
		var d3 = q1.sub(p1);
		var d2 = q2.sub(p2);
		var r = p1.sub(p2);
		var a = d3.dot(d3);
		var e = d2.dot(d2);
		var f = d2.dot(r);

		var res:CPSSResult = {
			s: 0,
			t: 0,
			c1: null,
			c2: null,
			result: -1
		}

		if (a <= Epsilon && e <= Epsilon) {
			res = {
				s: 0,
				t: 0,
				c1: p1,
				c2: p2,
				result: p1.sub(p2).dot(p1.sub(p2))
			}
			return res;
		}
		if (a <= Epsilon) {
			res.s = 0;
			res.t = f / e;
			if (res.t > 1)
				res.t = 1;
			if (res.t < 0)
				res.t = 0;
		} else {
			var c3 = d3.dot(r);
			if (e <= Epsilon) {
				res.t = 0;
				if (-c3 / a > 1)
					res.s = 1;
				else if (-c3 / a < 0)
					res.s = 0;
				else
					res.s = (-c3 / a);
			} else {
				var b = d3.dot(d2);
				var denom = a * e - b * b;
				if (denom != 0) {
					res.s = (b * f - c3 * e) / denom;
					if (res.s > 1)
						res.s = 1;
					if (res.s < 0)
						res.s = 0;
				} else {
					res.s = 0;
				}
				res.t = (b * res.s + f) / e;
				if (res.t < 0) {
					res.t = 0;
					res.s = -c3 / a;
					if (res.s > 1)
						res.s = 1;
					if (res.s < 0)
						res.s = 0;
				} else if (res.t > 1) {
					res.t = 1;
					res.s = (b - c3) / a;
					if (res.s > 1)
						res.s = 1;
					if (res.s < 0)
						res.s = 0;
				}
			}
		}
		res.c1 = p1.add(d3.multiply(res.s));
		res.c2 = p2.add(d2.multiply(res.t));
		res.result = res.c1.sub(res.c2).lengthSq();
		return res;
	}

	private static function PointInTriangle(point:Vector, v0:Vector, v1:Vector, v2:Vector):Bool {
		var u = v1.sub(v0);
		var v = v2.sub(v0);
		var w = point.sub(v0);

		var vw = v.cross(w);
		var vu = v.cross(u);

		if (vw.dot(vu) < 0.0) {
			return false;
		}

		var uw = u.cross(w);
		var uv = u.cross(v);

		if (uw.dot(uv) < 0.0) {
			return false;
		}

		var d:Float = uv.length();
		var r:Float = vw.length() / d;
		var t:Float = uw.length() / d;

		return (r + t) <= 1;
	}

	private static function PointInTriangle2(point:Vector, a:Vector, b:Vector, c:Vector):Bool {
		var a1 = a.sub(point);
		var b1 = b.sub(point);
		var c1 = c.sub(point);

		var u = b1.cross(c1);
		var v = c1.cross(a1);

		if (u.dot(v) < 0)
			return false;

		var w = a1.cross(b1);
		return !(u.dot(w) < 0);
	}

	private static function GetLowestRoot(a:Float, b:Float, c:Float, max:Float):Null<Float> {
		// check if solution exists
		var determinant:Float = b * b - 4.0 * a * c;

		// if negative there is no solution
		if (determinant < 0.0) {
			return null;
		}

		// calculate two roots
		var sqrtD:Float = Math.sqrt(determinant);
		var r1:Float = (-b - sqrtD) / (2 * a);
		var r2:Float = (-b + sqrtD) / (2 * a);

		// set x1 <= x2
		if (r1 > r2) {
			var temp:Float = r2;
			r2 = r1;
			r1 = temp;
		}

		// get lowest root
		if (r1 > 0 && r1 < max) {
			return r1;
		}

		if (r2 > 0 && r2 < max) {
			return r2;
		}

		// no solutions
		return null;
	}

	public static function ClosestPtPointTriangle(pt:Vector, radius:Float, p0:Vector, p1:Vector, p2:Vector, normal:Vector) {
		var closest:Vector = null;
		var ptDot = pt.dot(normal);
		var triDot = p0.dot(normal);
		if (Math.abs(ptDot - triDot) > radius * 1.1) {
			return null;
		}
		closest = pt.add(normal.multiply(triDot - ptDot));
		if (Collision.PointInTriangle2(closest, p0, p1, p2)) {
			return closest;
		}
		var t = 10.0;
		var r1 = Collision.IntersectSegmentCapsule(pt, pt, p0, p1, radius);
		if (r1.result && r1.tSeg < t) {
			closest = p0.add((p1.sub(p0).multiply(r1.tCap)));
			t = r1.tSeg;
		}
		var r2 = Collision.IntersectSegmentCapsule(pt, pt, p1, p2, radius);
		if (r2.result && r2.tSeg < t) {
			closest = p1.add((p2.sub(p1).multiply(r2.tCap)));
			t = r2.tSeg;
		}
		var r3 = Collision.IntersectSegmentCapsule(pt, pt, p2, p0, radius);
		if (r3.result && r3.tSeg < t) {
			closest = p2.add((p2.sub(p2).multiply(r3.tCap)));
			t = r3.tSeg;
		}
		var res = t < 1;
		if (res) {
			return closest;
		}
		return null;
	}

	public static function CheckTriangle(packet:CollisionPacket, p1:Vector, p2:Vector, p3:Vector) {
		function toDifPoint(pt:Vector) {
			return new Point3F(pt.x, pt.y, pt.z);
		}

		function fromDifPoint(pt:Point3F) {
			return new Vector(pt.x, pt.y, pt.z);
		}

		var plane = PlaneF.ThreePoints(toDifPoint(p1), toDifPoint(p2), toDifPoint(p3));

		// only check front facing triangles
		var dist = plane.distance(toDifPoint(packet.e_norm_velocity));
		if (dist < 0) {
			return packet;
		}

		// get interval of plane intersection
		var t0:Float = 0.0;
		var t1:Float = 0.0;
		var embedded_in_plane:Bool = false;

		// signed distance from sphere to point on plane
		var signed_dist_to_plane:Float = plane.distance(toDifPoint(packet.e_base_point));

		// cache this as we will reuse
		var normal_dot_vel = plane.getNormal().dot(toDifPoint(packet.e_velocity));

		// if sphere is moving parrallel to plane
		if (normal_dot_vel == 0.0) {
			if (Math.abs(signed_dist_to_plane) >= 1.0) {
				// no collision possible
				return packet;
			} else {
				// sphere is in plane in whole range [0..1]
				embedded_in_plane = true;
				t0 = 0.0;
				t1 = 1.0;
			}
		} else {
			// N dot D is not 0, calc intersect interval
			t0 = (-1.0 - signed_dist_to_plane) / normal_dot_vel;
			t1 = (1.0 - signed_dist_to_plane) / normal_dot_vel;

			// swap so t0 < t1
			if (t0 > t1) {
				var temp = t1;
				t1 = t0;
				t0 = temp;
			}

			// check that at least one result is within range
			if (t0 > 1.0 || t1 < 0.0) {
				// both values outside range [0,1] so no collision
				return packet;
			}

			// clamp to [0,1]
			if (t0 < 0.0) {
				t0 = 0.0;
			}
			if (t1 < 0.0) {
				t1 = 0.0;
			}
			if (t0 > 1.0) {
				t0 = 1.0;
			}
			if (t1 > 1.0) {
				t1 = 1.0;
			}
		}

		// time to check for a collision
		var collision_point:Vector = new Vector(0.0, 0.0, 0.0);
		var found_collision:Bool = false;
		var t:Float = 1.0;

		// first check collision with the inside of the triangle
		if (!embedded_in_plane) {
			var plane_intersect:Vector = packet.e_base_point.sub(fromDifPoint(plane.getNormal()));
			var temp:Vector = packet.e_velocity.multiply(t0);
			plane_intersect = plane_intersect.add(temp);

			if (Collision.PointInTriangle(plane_intersect, p1, p2, p3)) {
				found_collision = true;
				t = t0;
				collision_point = plane_intersect;
			}
		}

		// no collision yet, check against points and edges
		if (!found_collision) {
			var velocity = packet.e_velocity.clone();
			var base = packet.e_base_point.clone();

			var velocity_sq_length = velocity.lengthSq();
			var a:Float = velocity_sq_length;
			var b:Float = 0.0;
			var c:Float = 0.0;

			// equation is a*t^2 + b*t + c = 0
			// check against points

			// p1
			var temp = base.sub(p1);
			b = 2.0 * velocity.dot(temp);
			temp = p1.sub(base);
			c = temp.lengthSq() - 1.0;
			var new_t = Collision.GetLowestRoot(a, b, c, t);
			if (new_t != null) {
				t = new_t;
				found_collision = true;
				collision_point = p1;
			}

			// p2
			if (!found_collision) {
				temp = base.sub(p2);
				b = 2.0 * velocity.dot(temp);
				temp = p2.sub(base);
				c = temp.lengthSq() - 1.0;
				new_t = Collision.GetLowestRoot(a, b, c, t);
				if (new_t != null) {
					t = new_t;
					found_collision = true;
					collision_point = p2;
				}
			}

			// p3
			if (!found_collision) {
				temp = base.sub(p3);
				b = 2.0 * velocity.dot(temp);
				temp = p3.sub(base);
				c = temp.lengthSq() - 1.0;
				new_t = Collision.GetLowestRoot(a, b, c, t);
				if (new_t != null) {
					t = new_t;
					found_collision = true;
					collision_point = p3;
				}
			}

			// check against edges
			// p1 -> p2
			var edge = p2.sub(p1);
			var base_to_vertex = p1.sub(base);
			var edge_sq_length = edge.lengthSq();
			var edge_dot_velocity = edge.dot(velocity);
			var edge_dot_base_to_vertex = edge.dot(base_to_vertex);

			// calculate params for equation
			a = edge_sq_length * -velocity_sq_length + edge_dot_velocity * edge_dot_velocity;
			b = edge_sq_length * (2.0 * velocity.dot(base_to_vertex)) - 2.0 * edge_dot_velocity * edge_dot_base_to_vertex;
			c = edge_sq_length * (1.0 - base_to_vertex.lengthSq()) + edge_dot_base_to_vertex * edge_dot_base_to_vertex;

			// do we collide against infinite edge
			new_t = Collision.GetLowestRoot(a, b, c, t);
			if (new_t != null) {
				// check if intersect is within line segment
				var f = (edge_dot_velocity * new_t - edge_dot_base_to_vertex) / edge_sq_length;
				if (f >= 0.0 && f <= 1.0) {
					t = new_t;
					found_collision = true;
					collision_point = p1.add(edge.multiply(f));
				}
			}

			// p2 -> p3
			edge = p3.sub(p2);
			base_to_vertex = p2.sub(base);
			edge_sq_length = edge.lengthSq();
			edge_dot_velocity = edge.dot(velocity);
			edge_dot_base_to_vertex = edge.dot(base_to_vertex);

			// calculate params for equation
			a = edge_sq_length * -velocity_sq_length + edge_dot_velocity * edge_dot_velocity;
			b = edge_sq_length * (2.0 * velocity.dot(base_to_vertex)) - 2.0 * edge_dot_velocity * edge_dot_base_to_vertex;
			c = edge_sq_length * (1.0 - base_to_vertex.lengthSq()) + edge_dot_base_to_vertex * edge_dot_base_to_vertex;

			// do we collide against infinite edge
			new_t = Collision.GetLowestRoot(a, b, c, t);
			if (new_t != null) {
				// check if intersect is within line segment
				var f = (edge_dot_velocity * new_t - edge_dot_base_to_vertex) / edge_sq_length;
				if (f >= 0.0 && f <= 1.0) {
					t = new_t;
					found_collision = true;
					collision_point = p2.add(edge.multiply(f));
				}
			}

			// p3 -> p1
			edge = p1.sub(p3);
			base_to_vertex = p3.sub(base);
			edge_sq_length = edge.lengthSq();
			edge_dot_velocity = edge.dot(velocity);
			edge_dot_base_to_vertex = edge.dot(base_to_vertex);

			// calculate params for equation
			a = edge_sq_length * -velocity_sq_length + edge_dot_velocity * edge_dot_velocity;
			b = edge_sq_length * (2.0 * velocity.dot(base_to_vertex)) - 2.0 * edge_dot_velocity * edge_dot_base_to_vertex;
			c = edge_sq_length * (1.0 - base_to_vertex.lengthSq()) + edge_dot_base_to_vertex * edge_dot_base_to_vertex;

			// do we collide against infinite edge
			new_t = Collision.GetLowestRoot(a, b, c, t);
			if (new_t != null) {
				// check if intersect is within line segment
				var f = (edge_dot_velocity * new_t - edge_dot_base_to_vertex) / edge_sq_length;
				if (f >= 0.0 && f <= 1.0) {
					t = new_t;
					found_collision = true;
					collision_point = p3.add(edge.multiply(f));
				}
			}
		}

		// set results
		if (found_collision) {
			// distance to collision, t is time of collision
			var dist_to_coll = t * packet.e_velocity.length();

			// are we the closest hit?
			if (!packet.found_collision || dist_to_coll < packet.nearest_distance) {
				packet.nearest_distance = dist_to_coll;
				packet.intersect_point = collision_point;
				packet.found_collision = true;
			}

			// HACK: USE SENSORS FOR THIS AND YOU DON'T GET WALL HITS ANYMORE
			// Work out the hit normal so we can determine if the player is in
			// contact with a wall or the ground.
			var n = collision_point.sub(packet.e_base_point);
			n.normalize();

			var dz = n.dot(new Vector(0, 0, 1));
			if (dz <= -0.5) {
				packet.grounded = true;
			}
		}

		return packet;
	}
}
