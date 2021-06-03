package collision.gjk;

import h3d.Vector;

// Code taken from https://github.com/kevinmoran/GJK/blob/master/main.cpp
class GJK {
	public static var maxIterations = 64;
	public static var maxEpaFaces = 64;
	public static var epaTolerance = 0.0001;
	public static var maxEpaLooseEdges = 64;
	public static var maxEpaIterations = 64;

	public static function gjk(sphere:Sphere, hull:ConvexHull) {
		var searchDir = sphere.position.sub(hull.centre);
		var a = new Vector();
		var b = new Vector();
		var c = new Vector();
		var d = new Vector();

		c = hull.support(searchDir).sub(sphere.support(searchDir.multiply(-1)));
		searchDir = c.multiply(-1);
		b = hull.support(searchDir).sub(sphere.support(searchDir.multiply(-1)));
		if (b.dot(searchDir) < 0)
			return null;

		searchDir = c.sub(b).cross(b.multiply(-1)).cross(c.sub(b));
		if (searchDir.length() == 0) {
			searchDir = c.sub(b).cross(new Vector(1, 0, 0));
			if (searchDir.length() == 0.00)
				searchDir = c.sub(b).cross(new Vector(0, 0, -1));
		}

		var simpDim = 2;

		for (i in 0...maxIterations) {
			a = hull.support(searchDir).sub(sphere.support(searchDir.multiply(-1)));
			if (a.dot(searchDir) < 0) {
				return null;
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
					return epa(a, b, c, d, sphere, hull);
				}
			}
		}
		return null;
	}

	public static function epa(a:Vector, b:Vector, c:Vector, d:Vector, sphere:Sphere, hull:ConvexHull) {
		var faces = [];
		for (i in 0...maxEpaFaces)
			faces.push([new Vector(), new Vector(), new Vector(), new Vector()]);

		faces[0][0] = a;
		faces[0][1] = b;
		faces[0][2] = c;
		faces[0][3] = b.sub(a).cross(c.sub(a)).normalized(); // ABC
		faces[1][0] = a;
		faces[1][1] = c;
		faces[1][2] = d;
		faces[1][3] = c.sub(a).cross(d.sub(a)).normalized();
		faces[2][0] = a;
		faces[2][1] = d;
		faces[2][2] = b;
		faces[2][3] = d.sub(a).cross(b.sub(a)).normalized();
		faces[3][0] = b;
		faces[3][1] = d;
		faces[3][2] = c;
		faces[3][3] = d.sub(b).cross(c.sub(b)).normalized();

		var numFaces = 4;
		var closestFace = 0;

		for (iteration in 0...maxEpaIterations) {
			// Find face that's closest to origin
			var min_dist = faces[0][0].dot(faces[0][3]);
			closestFace = 0;
			for (i in 1...numFaces) {
				var dist = faces[i][0].dot(faces[i][3]);
				if (dist < min_dist) {
					min_dist = dist;
					closestFace = i;
				}
			}

			// search normal to face that's closest to origin
			var search_dir = faces[closestFace][3];
			var p = hull.support(search_dir).sub(sphere.support(search_dir.multiply(-1)));
			if (p.dot(search_dir) - min_dist < epaTolerance) {
				// Convergence (new point is not significantly further from origin)
				return faces[closestFace][3].multiply(p.dot(search_dir)); // dot vertex with normal to resolve collision along normal!
			}
			var loose_edges = [];
			for (i in 0...maxEpaLooseEdges)
				loose_edges.push([new Vector(), new Vector()]);

			var num_loose_edges = 0;

			// Find all triangles that are facing p
			var i = 0;
			while (i < numFaces) {
				if (faces[i][3].dot(p.sub(faces[i][0])) > 0) // triangle i faces p, remove it
				{
					// Add removed triangle's edges to loose edge list.
					// If it's already there, remove it (both triangles it belonged to are gone)
					for (j in 0...3) // Three edges per face
					{
						var current_edge = [faces[i][j], faces[i][(j + 1) % 3]];
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
					faces[i][0] = faces[numFaces - 1][0];
					faces[i][1] = faces[numFaces - 1][1];
					faces[i][2] = faces[numFaces - 1][2];
					faces[i][3] = faces[numFaces - 1][3];
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
				faces[numFaces][0] = loose_edges[i][0];
				faces[numFaces][1] = loose_edges[i][1];
				faces[numFaces][2] = p;
				faces[numFaces][3] = loose_edges[i][0].sub(loose_edges[i][1]).cross(loose_edges[i][0].sub(p)).normalized();

				// Check for wrong normal to maintain CCW winding
				var bias = 0.000001; // in case dot result is only slightly < 0 (because origin is on face)
				if (faces[numFaces][0].dot(faces[numFaces][3]) + bias < 0) {
					var temp = faces[numFaces][0];
					faces[numFaces][0] = faces[numFaces][1];
					faces[numFaces][1] = temp;
					faces[numFaces][3] = faces[numFaces][3].multiply(-1);
				}
				numFaces++;
			}
		}
		return faces[closestFace][3].multiply(faces[closestFace][0].dot(faces[closestFace][3]));
	}
}
