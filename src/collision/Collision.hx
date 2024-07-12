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

@:publicFields
class ITSResult {
	var result:Bool = false;
	var normal:Vector;
	var point:Vector;
	var resIdx:Int = -1;

	public inline function new() {
		this.point = new Vector();
		this.normal = new Vector();
	}
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

	public static inline function ClosestPointLine(start:Vector, end:Vector, center:Vector) {
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
			edgeConcavities:Array<Bool>) {
		var radiusSq = radius * radius;

		var res = new ITSResult();

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
				res.normal = pnorm;
				return res;
			}
			// return res;
		}

		// Check edges

		var r1 = ClosestPointLine(v0, v1, center);
		var r2 = ClosestPointLine(v1, v2, center);
		var r3 = ClosestPointLine(v2, v0, center);

		var chosenEdge = 0; // Bitfield

		var chosenPt = new Vector();
		if (r1.distanceSq(center) < r2.distanceSq(center)) {
			chosenPt.load(r1);
			chosenEdge = 1;
		} else {
			chosenPt.load(r2);
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

			res.normal = center.sub(res.point).normalized();

			if (res.normal.dot(normal) > 0.8) {
				// Internal edge
				if (chosenEdge & edgeData > 0) {
					chosenEdge -= 1;
					if (chosenEdge > 2)
						chosenEdge--;
					// if (edgeNormals[chosenEdge].length() < 0.5) {
					//	res.normal = center.sub(res.point).normalized();
					// } else
					if (edgeConcavities[chosenEdge]) { // Our edge is concave
						res.normal = pnorm;
					}
				}
			}

			return res;
		}
		return res;
	}

	public static inline function TriangleSphereIntersection(v0:Vector, v1:Vector, v2:Vector, N:Vector, P:Vector, r:Float, point:Vector, normal:Vector) {
		ClosestPtPointTriangle(P, v0, v1, v2, point);
		var v = point.sub(P);
		if (v.dot(v) <= r * r) {
			normal.load(P.sub(point));
			normal.normalize();
			return true;
		} else {
			return false;
		}
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

	public static inline function PointInTriangle(point:Vector, v0:Vector, v1:Vector, v2:Vector):Bool {
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
			edgeConcavities:Array<Bool>) {
		var dir = end.sub(start);
		var d = -(p1.dot(normal));
		var t = -(start.dot(normal) - d) / dir.dot(normal);
		if (t > 1)
			t = 1;
		if (t < 0)
			t = 0;
		var tracePoint = start.add(dir.multiply(t));
		return IntersectTriangleSphere(p1, p2, p3, normal, tracePoint, radius, edgeData, edgeConcavities);
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

	public static inline function ClosestPtPointTriangle(p:Vector, a:Vector, b:Vector, c:Vector, outP:Vector) {
		// Check if P in vertex region outside A
		var ab = b.sub(a);
		var ac = c.sub(a);
		var ap = p.sub(a);
		var d1 = ab.dot(ap);
		var d2 = ac.dot(ap);
		if (d1 <= 0.0 && d2 <= 0.0) { // barycentric coordinates (1,0,0)
			outP.load(a);
			return;
		}
		// Check if P in vertex region outside B
		var bp = p.sub(b);
		var d3 = ab.dot(bp);
		var d4 = ac.dot(bp);
		if (d3 >= 0.0 && d4 <= d3) { // barycentric coordinates (0,1,0
			outP.load(b);
			return;
		}

		// Check if P in edge region of AB, if so return projection of P onto AB
		var vc = d1 * d4 - d3 * d2;
		if (vc <= 0.0 && d1 >= 0.0 && d3 <= 0.0) {
			var v = d1 / (d1 - d3);
			outP.load(a.add(ab.multiply(v)));
			return;
		}

		// Check if P in vertex region outside C
		var cp = p.sub(c);
		var d5 = ab.dot(cp);
		var d6 = ac.dot(cp);
		if (d6 >= 0.0 && d5 <= d6) { // barycentric coordinates (0,0,1)
			outP.load(c);
			return;
		}

		// Check if P in edge region of AC, if so return projection of P onto AC
		var vb = d5 * d2 - d1 * d6;
		if (vb <= 0.0 && d2 >= 0.0 && d6 <= 0.0) {
			var w = d2 / (d2 - d6);
			outP.load(a.add(ac.multiply(w)));
			return;
		}

		// Check if P in edge region of BC, if so return projection of P onto BC
		var va = d3 * d6 - d5 * d4;
		if (va <= 0.0 && (d4 - d3) >= 0.0 && (d5 - d6) >= 0.0) {
			var w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
			outP.load(b.add((c.sub(b)).multiply(w)));
			return;
		}
		// P inside face region. Compute Q through its barycentric coordinates (u,v,w)

		var denom = 1.0 / (va + vb + vc);
		var v = vb * denom;
		var w = vc * denom;
		outP.load(a.add(ab.multiply(v)).add(ac.multiply(w)));
		return;
	}

	public static function capsuleSphereNearestOverlap(a0:Vector, a1:Vector, radA:Float, b:Vector, radB:Float) {
		var V = a1.sub(a0);
		var A0B = a0.sub(b);
		var d1 = A0B.dot(V);
		var d2 = A0B.dot(A0B);
		var d3 = V.dot(V);
		var R2 = (radA + radB) * (radA + radB);
		if (d2 < R2) {
			// starting in collision state
			return {
				result: true,
				t: 0.0
			}
		}
		if (d3 < 0.01) // no movement, and don't start in collision state, so no collision
			return {
				result: false,
				t: 0.0
			}

		var b24ac = Math.sqrt(d1 * d1 - d2 * d3 + d3 * R2);
		var t1 = (-d1 - b24ac) / d3;
		if (t1 > 0 && t1 < 1.0) {
			return {
				result: true,
				t: t1
			}
		}
		var t2 = (-d1 + b24ac) / d3;
		if (t2 > 0 && t2 < 1.0) {
			return {
				result: true,
				t: t2
			}
		}
		if (t1 < 0 && t2 > 0) {
			return {
				result: true,
				t: 0.0
			}
		}
		return {
			result: false,
			t: 0.0
		}
	}
}
