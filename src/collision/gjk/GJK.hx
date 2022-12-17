package collision.gjk;

import h3d.Vector;

// Code taken from https://github.com/kevinmoran/GJK/blob/master/main.cpp
class GJK {
	public static var maxIterations = 64;
	public static var maxEpaFaces = 64;
	public static var epaTolerance = 0.0001;
	public static var maxEpaLooseEdges = 64;
	public static var maxEpaIterations = 64;

	static var epaFaces:Array<Array<Vector>>;
	static var loose_edges:Array<Array<Vector>>;

	public static function gjk(s1:GJKShape, s2:GJKShape, doEpa:Bool = true) {
		var searchDir = s1.getCenter().sub(s2.getCenter());
		var a = new Vector();
		var b = new Vector();
		var c = new Vector();
		var d = new Vector();

		c = s2.support(searchDir).sub(s1.support(searchDir.multiply(-1)));
		searchDir = c.multiply(-1);
		b = s2.support(searchDir).sub(s1.support(searchDir.multiply(-1)));
		if (b.dot(searchDir) < 0)
			return {
				result: false,
				epa: null
			};

		searchDir = c.sub(b).cross(b.multiply(-1)).cross(c.sub(b));
		if (searchDir.length() == 0) {
			searchDir = c.sub(b).cross(new Vector(1, 0, 0));
			if (searchDir.length() == 0.00)
				searchDir = c.sub(b).cross(new Vector(0, 0, -1));
		}

		var simpDim = 2;

		for (i in 0...maxIterations) {
			a = s2.support(searchDir).sub(s1.support(searchDir.multiply(-1)));
			if (a.dot(searchDir) < 0) {
				return {
					result: false,
					epa: null
				};
			}

			simpDim++;
			if (simpDim == 3) {
				var n = b.sub(a).cross(c.sub(a));
				var ao = a.multiply(-1);

				simpDim = 2;
				if (b.sub(a).cross(n).dot(ao) > 0) {
					c = a;
					searchDir = b.sub(a).cross(ao).cross(b.sub(a));
				} else if (n.cross(c.sub(a)).dot(ao) > 0) {
					b = a;
					searchDir = c.sub(a).cross(ao).cross(c.sub(a));
				} else {
					simpDim = 3;
					if (n.dot(ao) > 0) {
						d = c;
						c = b;
						b = a;
						searchDir = n;
					} else {
						d = b;
						b = a;
						searchDir = n.multiply(-1);
					}
				}
			} else {
				var abc = b.sub(a).cross(c.sub(a));
				var acd = c.sub(a).cross(d.sub(a));
				var adb = d.sub(a).cross(b.sub(a));
				var ao = a.multiply(-1);
				simpDim = 3;
				if (abc.dot(ao) > 0) {
					d = c;
					c = b;
					b = a;
					searchDir = abc;
				} else if (acd.dot(ao) > 0) {
					b = a;
					searchDir = acd;
				} else if (adb.dot(ao) > 0) {
					c = d;
					d = b;
					b = a;
					searchDir = adb;
				} else {
					if (doEpa)
						return {
							result: true,
							epa: epa(a, b, c, d, s1, s2)
						};
					return {
						result: true,
						epa: null
					};
				}
			}
		}
		return {
			result: false,
			epa: null
		};
	}

	public static function epa(a:Vector, b:Vector, c:Vector, d:Vector, s1:GJKShape, s2:GJKShape) {
		if (epaFaces == null) {
			epaFaces = [];
			for (i in 0...maxEpaFaces)
				epaFaces.push([new Vector(), new Vector(), new Vector(), new Vector()]);
		}

		epaFaces[0][0] = a;
		epaFaces[0][1] = b;
		epaFaces[0][2] = c;
		epaFaces[0][3] = b.sub(a).cross(c.sub(a)).normalized(); // ABC
		epaFaces[1][0] = a;
		epaFaces[1][1] = c;
		epaFaces[1][2] = d;
		epaFaces[1][3] = c.sub(a).cross(d.sub(a)).normalized();
		epaFaces[2][0] = a;
		epaFaces[2][1] = d;
		epaFaces[2][2] = b;
		epaFaces[2][3] = d.sub(a).cross(b.sub(a)).normalized();
		epaFaces[3][0] = b;
		epaFaces[3][1] = d;
		epaFaces[3][2] = c;
		epaFaces[3][3] = d.sub(b).cross(c.sub(b)).normalized();

		var numFaces = 4;
		var closestFace = 0;

		for (iteration in 0...maxEpaIterations) {
			// Find face that's closest to origin
			var min_dist = epaFaces[0][0].dot(epaFaces[0][3]);
			closestFace = 0;
			for (i in 1...numFaces) {
				var dist = epaFaces[i][0].dot(epaFaces[i][3]);
				if (dist < min_dist) {
					min_dist = dist;
					closestFace = i;
				}
			}

			// search normal to face that's closest to origin
			var search_dir = epaFaces[closestFace][3];
			var p = s2.support(search_dir).sub(s1.support(search_dir.multiply(-1)));
			if (p.dot(search_dir) - min_dist < epaTolerance) {
				// Convergence (new point is not significantly further from origin)
				return epaFaces[closestFace][3].multiply(p.dot(search_dir)); // dot vertex with normal to resolve collision along normal!
			}
			if (loose_edges == null) {
				loose_edges = [];
				for (i in 0...maxEpaLooseEdges)
					loose_edges.push([new Vector(), new Vector()]);
			}

			var num_loose_edges = 0;

			// Find all triangles that are facing p
			var i = 0;
			while (i < numFaces) {
				if (epaFaces[i][3].dot(p.sub(epaFaces[i][0])) > 0) // triangle i faces p, remove it
				{
					// Add removed triangle's edges to loose edge list.
					// If it's already there, remove it (both triangles it belonged to are gone)
					for (j in 0...3) // Three edges per face
					{
						var current_edge = [epaFaces[i][j], epaFaces[i][(j + 1) % 3]];
						var found_edge = false;
						for (k in 0...num_loose_edges) // Check if current edge is already in list
						{
							if (loose_edges[k][1] == current_edge[0] && loose_edges[k][0] == current_edge[1]) {
								// Edge is already in the list, remove it
								// THIS ASSUMES EDGE CAN ONLY BE SHARED BY 2 TRIANGLES (which should be true)
								// THIS ALSO ASSUMES SHARED EDGE WILL BE REVERSED IN THE TRIANGLES (which
								// should be true provided every triangle is wound CCW)
								loose_edges[k][0] = loose_edges[num_loose_edges - 1][0]; // Overwrite current edge
								loose_edges[k][1] = loose_edges[num_loose_edges - 1][1]; // with last edge in list
								num_loose_edges--;
								found_edge = true;
								break;
								// exit loop because edge can only be shared once
							}
						} // endfor loose_edges

						if (!found_edge) { // add current edge to list
							// assert(num_loose_edges<EPA_MAX_NUM_LOOSE_EDGES);
							if (num_loose_edges >= maxEpaLooseEdges)
								break;
							loose_edges[num_loose_edges][0] = current_edge[0];
							loose_edges[num_loose_edges][1] = current_edge[1];
							num_loose_edges++;
						}
					}

					// Remove triangle i from list
					epaFaces[i][0] = epaFaces[numFaces - 1][0];
					epaFaces[i][1] = epaFaces[numFaces - 1][1];
					epaFaces[i][2] = epaFaces[numFaces - 1][2];
					epaFaces[i][3] = epaFaces[numFaces - 1][3];
					numFaces--;
					i--;
				} // endif p can see triangle i

				i++;
			} // endfor num_faces

			// Reconstruct polytope with p added
			for (i in 0...num_loose_edges) {
				// assert(num_faces<EPA_MAX_NUM_FACES);
				if (numFaces >= maxEpaFaces)
					break;
				epaFaces[numFaces][0] = loose_edges[i][0];
				epaFaces[numFaces][1] = loose_edges[i][1];
				epaFaces[numFaces][2] = p;
				epaFaces[numFaces][3] = loose_edges[i][0].sub(loose_edges[i][1]).cross(loose_edges[i][0].sub(p)).normalized();

				// Check for wrong normal to maintain CCW winding
				var bias = 0.000001; // in case dot result is only slightly < 0 (because origin is on face)
				if (epaFaces[numFaces][0].dot(epaFaces[numFaces][3]) + bias < 0) {
					var temp = epaFaces[numFaces][0];
					epaFaces[numFaces][0] = epaFaces[numFaces][1];
					epaFaces[numFaces][1] = temp;
					epaFaces[numFaces][3] = epaFaces[numFaces][3].multiply(-1);
				}
				numFaces++;
			}
		}
		return epaFaces[closestFace][3].multiply(epaFaces[closestFace][0].dot(epaFaces[closestFace][3]));
	}
}
