package collision;

import h3d.Vector;

@:publicFields
class TraceInfo {
	var start:Vector;
	var end:Vector;
	var scaledStart:Vector;
	var radius:Float;
	var invRadius:Float;
	var vel:Vector;
	var scaledVel:Vector;
	var velLength:Float;
	var normVel:Vector;
	var collision:Bool;
	var t:Float;
	var intersectPoint:Vector;
	var tmp:Vector;

	public function new() {
		this.start = new Vector();
		this.end = new Vector();
		this.scaledStart = new Vector();
		this.radius = 0;
		this.invRadius = 0;
		this.vel = new Vector();
		this.scaledVel = new Vector();
		this.velLength = 0;
		this.normVel = new Vector();
		this.collision = false;
		this.t = 0;
		this.intersectPoint = new Vector();
	}

	public function resetTrace(start:Vector, end:Vector, radius:Float) {
		this.invRadius = 1 / radius;
		this.radius = radius;

		this.start.set(start.x, start.y, start.z);
		this.end.set(end.x, end.y, end.z);
		this.vel = this.end.sub(this.start);
		this.normVel = this.vel.normalized();

		this.scaledStart = start.multiply(this.invRadius);
		this.scaledVel = this.vel.multiply(this.invRadius);

		this.velLength = this.vel.length();

		this.collision = false;
		this.t = 1.0;
	}

	public function setCollision(t:Float, point:Vector) {
		this.collision = true;
		if (t < this.t) {
			this.t = t;
			this.intersectPoint = point.multiply(this.radius);
		}
	}

	public function getTraceEndpoint() {
		return this.start.add(this.vel.multiply(this.t));
	}

	public function getTraceDistance() {
		return this.vel.multiply(this.t).length();
	}

	public function traceSphereTriangle(a:Vector, b:Vector, c:Vector) {
		var invRadius = this.invRadius;
		var vel = this.scaledVel;
		var start = this.scaledStart;

		// Scale the triangle points so that we're colliding against a unit-radius sphere.
		var ta = a.multiply(invRadius);
		var tb = b.multiply(invRadius);
		var tc = c.multiply(invRadius);

		// Calculate triangle normal.
		// This may be better to do as a pre-process
		var pab = tb.sub(ta);
		var pac = tc.sub(ta);
		var norm = pab.cross(pac);
		norm.normalize();
		var planeD = -(norm.dot(ta));

		// Colliding against the backface of the triangle
		if (norm.dot(this.normVel) >= 0) {
			// Two choices at this point:

			// 1) Negate the normal so that it always points towards the start point
			// This feels kludgy, but I'm not sure if there's a better alternative
			/*vec3.negate(norm, norm);
				planeD = -planeD; */

			// 2) Or allow it to pass through
			return;
		}

		// Get interval of plane intersection:
		var t0, t1;
		var embedded = false;

		// Calculate the signed distance from sphere
		// position to triangle plane
		var distToPlane = start.dot(norm) + planeD;

		// cache this as we’re going to use it a few times below:
		var normDotVel = norm.dot(vel);

		if (normDotVel == 0.0) {
			// Sphere is travelling parrallel to the plane:
			if (Math.abs(distToPlane) >= 1.0) {
				// Sphere is not embedded in plane, No collision possible
				return;
			} else {
				// Sphere is completely embedded in plane.
				// It intersects in the whole range [0..1]
				embedded = true;
				t0 = 0.0;
				t1 = 1.0;
			}
		} else {
			// Calculate intersection interval:
			t0 = (-1.0 - distToPlane) / normDotVel;
			t1 = (1.0 - distToPlane) / normDotVel;
			// Swap so t0 < t1
			if (t0 > t1) {
				var temp = t1;
				t1 = t0;
				t0 = temp;
			}
			// Check that at least one result is within range:
			if (t0 > 1.0 || t1 < 0.0) {
				// No collision possible
				return;
			}
			// Clamp to [0,1]
			if (t0 < 0.0)
				t0 = 0.0;
			if (t1 < 0.0)
				t1 = 0.0;
			if (t0 > 1.0)
				t0 = 1.0;
			if (t1 > 1.0)
				t1 = 1.0;
		}

		// If the closest possible collision point is further away
		// than an already detected collision then there's no point
		// in testing further.
		if (t0 >= this.t) {
			return;
		}

		// t0 and t1 now represent the range of the sphere movement
		// during which it intersects with the triangle plane.
		// Collisions cannot happen outside that range.

		// Check for collision againt the triangle face:
		if (!embedded) {
			// Calculate the intersection point with the plane
			var planeIntersect = start.sub(norm);
			var v = vel.multiply(t0);
			planeIntersect = planeIntersect.add(v);

			// Is that point inside the triangle?
			if (pointInTriangle(planeIntersect, ta, tb, tc)) {
				this.setCollision(t0, planeIntersect);
				// Collisions against the face will always be closer than vertex or edge collisions
				// so we can stop checking now.
				return;
			}
		}

		var velSqrLen = vel.lengthSq();
		var t = this.t;

		// Check for collision againt the triangle vertices:
		t = testVertex(ta, velSqrLen, t, start, vel);
		t = testVertex(tb, velSqrLen, t, start, vel);
		t = testVertex(tc, velSqrLen, t, start, vel);

		// Check for collision against the triangle edges:
		t = testEdge(ta, tb, velSqrLen, t, start, vel);
		t = testEdge(tb, tc, velSqrLen, t, start, vel);
		testEdge(tc, ta, velSqrLen, t, start, vel);
	}

	function pointInTriangle(p:Vector, t0:Vector, t1:Vector, t2:Vector) {
		var pt0 = t0.sub(p);
		var pt1 = t1.sub(p);
		var pt2 = t2.sub(p);

		pt0.normalize();
		pt1.normalize();
		pt2.normalize();

		var a = pt0.dot(pt1);
		var b = pt1.dot(pt2);
		var c = pt2.dot(pt0);

		var angle = Math.acos(a) + Math.acos(b) + Math.acos(c);

		// If the point is on the triangle all the interior angles should add up to 360 deg.
		var collision = Math.abs(angle - (2 * Math.PI)) < 0.01;
		return collision;
	}

	function getLowestRoot(a:Float, b:Float, c:Float, maxR:Float) {
		var det = b * b - 4.0 * a * c;
		if (det < 0) {
			return -1.0;
		}

		var sqrtDet = Math.sqrt(det);
		var r1 = (-b - sqrtDet) / (2.0 * a);
		var r2 = (-b + sqrtDet) / (2.0 * a);

		if (r1 > r2) {
			var tmp = r2;
			r2 = r1;
			r1 = tmp;
		}

		if (r1 > 0 && r1 < maxR) {
			return r1;
		}

		if (r2 > 0 && r2 < maxR) {
			return r2;
		}

		return -1.0;
	}

	function testVertex(p:Vector, velSqrLen:Float, t:Float, start:Vector, vel:Vector) {
		var v = start.sub(p);
		var b = 2.0 * vel.dot(v);
		var c = v.lengthSq() - 1.0;
		var newT = getLowestRoot(velSqrLen, b, c, t);
		if (newT != -1) {
			this.setCollision(newT, p);
			return newT;
		}
		return t;
	}

	function testEdge(pa:Vector, pb:Vector, velSqrLen:Float, t:Float, start:Vector, vel:Vector) {
		var edge = pb.sub(pa);
		var v = pa.sub(start);

		var edgeSqrLen = edge.lengthSq();
		var edgeDotVel = edge.dot(vel);
		var edgeDotSphereVert = edge.dot(v);

		var a = edgeSqrLen * -velSqrLen + edgeDotVel * edgeDotVel;
		var b = edgeSqrLen * (2.0 * vel.dot(v)) - 2.0 * edgeDotVel * edgeDotSphereVert;
		var c = edgeSqrLen * (1.0 - v.lengthSq()) + edgeDotSphereVert * edgeDotSphereVert;

		// Check for intersection against infinite line
		var newT = getLowestRoot(a, b, c, t);
		if (newT != -1 && newT < this.t) {
			// Check if intersection against the line segment:
			var f = (edgeDotVel * newT - edgeDotSphereVert) / edgeSqrLen;
			if (f >= 0.0 && f <= 1.0) {
				v = edge.multiply(f);
				v = v.add(pa);
				this.setCollision(newT, v);
				return newT;
			}
		}
		return t;
	}
}
