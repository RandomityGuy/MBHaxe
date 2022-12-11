package collision;

import haxe.Exception;
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
		var d = end.sub(start);
		var v = center.sub(start);
		var t = v.dot(d) / d.lengthSq();
		if (t < 0)
			t = 0;
		if (t > 1)
			t = 1;
		var p = start.add(d.multiply(t));
		var dist = center.distance(p);

		if (dist > radius) {
			return null;
		} else
			return p;
	}

	public static function ClosestPointLine(start:Vector, end:Vector, center:Vector) {
		var d = end.sub(start);
		var v = center.sub(start);
		var t = v.dot(d) / d.lengthSq();
		if (t < 0)
			t = 0;
		if (t > 1)
			t = 1;
		var p = start.add(d.multiply(t));
		return p;
	}

	// EdgeData is bitfield
	// 001b: v0v1 is edge
	// 010b: v1v2 is edge
	// 100b: v0v2 is edge
	public static function IntersectTriangleSphere(v0:Vector, v1:Vector, v2:Vector, normal:Vector, center:Vector, radius:Float, edgeData:Int,
			edgeDots:Array<Float>) {
		var radiusSq = radius * radius;

		var res:ITSResult = {
			result: false,
			point: null,
			normal: null
		};

		var pnorm = normal.clone();
		var d = -v0.dot(pnorm);

		var pdist = center.dot(pnorm) + d;

		if (pdist < 0.001) {
			return res; // Dont collide internal edges
		}

		if (pdist < radius) {
			var n = normal.normalized();
			var t = center.dot(n) - v0.dot(n);

			var pt = center.sub(n.multiply(t));

			if (PointInTriangle(pt, v0, v1, v2)) {
				res.result = true;
				res.point = pt;
				res.normal = center.sub(pt).normalized();
				return res;
			}
			// return res;
		}

		// Check edges

		var r1 = ClosestPointLine(v0, v1, center);
		var r2 = ClosestPointLine(v1, v2, center);
		var r3 = ClosestPointLine(v2, v0, center);

		var chosenEdge = 0; // Bitfield

		var chosenPt:Vector;
		if (r1.distanceSq(center) < r2.distanceSq(center)) {
			chosenPt = r1;
			chosenEdge = 1;
		} else {
			chosenPt = r2;
			chosenEdge = 2;
		}
		if (chosenPt.distanceSq(center) < r3.distanceSq(center))
			res.point = chosenPt;
		else {
			chosenEdge = 4;
			res.point = r3;
		}

		if (res.point.distanceSq(center) <= radiusSq) {
			res.result = true;

			if (chosenEdge & edgeData > 0) {
				res.normal = center.sub(res.point).normalized();
			} else { // We hit an internal edge
				chosenEdge -= 1;
				if (chosenEdge > 2)
					chosenEdge--;
				// if (edgeNormals[chosenEdge].length() < 0.5) {
				//	res.normal = center.sub(res.point).normalized();
				// } else
				var edgeDotAng = Math.acos(edgeDots[chosenEdge]);
				if (edgeDotAng < Math.PI / 12) {
					// if (edgeDotAng == 0) {
					// 	res.normal = center.sub(res.point).normalized();
					// } else {
					// 	res.normal = normal; // edgeNormals[chosenEdge];
					// }
					res.point = null;
					res.normal = null;
					res.result = false;
				} else {
					res.result = false;
					res.normal = center.sub(res.point).normalized();
				}
				// trace("Internal Edge Collision");
			}

			return res;
		}

		// var r1 = IntersectLineSphere(v0, v1, center, radius);
		// if (r1 != null) {
		// 	res.result = true;
		// 	res.point = r1;
		// 	res.normal = center.sub(r1).normalized();
		// 	return res;
		// }
		// var r2 = IntersectLineSphere(v1, v2, center, radius);
		// if (r2 != null) {
		// 	res.result = true;
		// 	res.point = r2;
		// 	res.normal = center.sub(r2).normalized();
		// 	return res;
		// }
		// var r3 = IntersectLineSphere(v2, v0, center, radius);
		// if (r3 != null) {
		// 	res.result = true;
		// 	res.point = r3;
		// 	res.normal = center.sub(r3).normalized();
		// 	return res;
		// }
		// Check points
		// if (center.sub(v0).lengthSq() < radiusSq) {
		// 	res.result = true;
		// 	res.point = v0;
		// 	res.normal = center.sub(v0).normalized();
		// 	// center.sub(v0).normalized();
		// 	return res;
		// }
		// if (center.sub(v1).lengthSq() < radiusSq) {
		// 	res.result = true;
		// 	res.point = v1;
		// 	res.normal = center.sub(v1).normalized();
		// 	return res;
		// }
		// if (center.sub(v2).lengthSq() < radiusSq) {
		// 	res.result = true;
		// 	res.point = v2;
		// 	res.normal = center.sub(v2).normalized();
		// 	return res;
		// }
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

	public static function PointInTriangle(point:Vector, v0:Vector, v1:Vector, v2:Vector):Bool {
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

	public static function PointInTriangle2(point:Vector, a:Vector, b:Vector, c:Vector):Bool {
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

	public static function IntersectTriangleCapsule(start:Vector, end:Vector, radius:Float, p1:Vector, p2:Vector, p3:Vector, normal:Vector, edgeData:Int,
			edgeDots:Array<Float>) {
		var dir = end.sub(start);
		var d = -(p1.dot(normal));
		var t = -(start.dot(normal) - d) / dir.dot(normal);
		if (t > 1)
			t = 1;
		if (t < 0)
			t = 0;
		var tracePoint = start.add(dir.multiply(t));
		return IntersectTriangleSphere(p1, p2, p3, normal, tracePoint, radius, edgeData, edgeDots);
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
}
