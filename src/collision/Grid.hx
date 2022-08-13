package collision;

import haxe.Exception;
import h3d.Vector;
import h3d.col.Bounds;

class Grid {
	public var bounds:Bounds; // The bounds of the grid

	public var cellSize:Vector; // The dimensions of one cell

	public static var CELL_DIV = new Vector(16, 16, 16); // split the bounds into cells of dimensions 1/16th of the corresponding dimensions of the bounds

	var map:Map<Int, Array<Int>> = new Map();

	var surfaces:Array<CollisionSurface> = [];

	public function new(bounds:Bounds) {
		this.bounds = bounds;

		this.cellSize = new Vector(bounds.xSize / CELL_DIV.x, bounds.ySize / CELL_DIV.y, bounds.zSize / CELL_DIV.z);
	}

	public function insert(surface:CollisionSurface) {
		// Assuming surface has built a bounding box already
		if (this.bounds.containsBounds(surface.boundingBox)) {
			var idx = this.surfaces.length;
			this.surfaces.push(surface);

			var xStart = Math.floor((surface.boundingBox.xMin - bounds.xMin) / this.cellSize.x);
			var yStart = Math.floor((surface.boundingBox.yMin - bounds.yMin) / this.cellSize.y);
			var zStart = Math.floor((surface.boundingBox.zMin - bounds.zMin) / this.cellSize.z);
			var xEnd = Math.ceil((surface.boundingBox.xMax - bounds.xMin) / this.cellSize.x) + 1;
			var yEnd = Math.ceil((surface.boundingBox.yMax - bounds.yMin) / this.cellSize.y) + 1;
			var zEnd = Math.ceil((surface.boundingBox.zMax - bounds.zMin) / this.cellSize.z) + 1;

			// Insert the surface references from [xStart, yStart, zStart] to [xEnd, yEnd, zEnd] into the map
			for (i in xStart...xEnd) {
				for (j in yStart...yEnd) {
					for (k in zStart...zEnd) {
						var hash = hashVector(i, j, k);
						if (!this.map.exists(hash)) {
							this.map.set(hash, []);
						}
						this.map.get(hash).push(idx);
					}
				}
			}
		} else {
			throw new Exception("Surface is not contained in the grid's bounds");
		}
	}

	// searchbox should be in LOCAL coordinates
	public function boundingSearch(searchbox:Bounds) {
		var xStart = Math.floor((searchbox.xMin - bounds.xMin) / this.cellSize.x);
		var yStart = Math.floor((searchbox.yMin - bounds.yMin) / this.cellSize.y);
		var zStart = Math.floor((searchbox.zMin - bounds.zMin) / this.cellSize.z);
		var xEnd = Math.ceil((searchbox.xMax - bounds.xMin) / this.cellSize.x) + 1;
		var yEnd = Math.ceil((searchbox.yMax - bounds.yMin) / this.cellSize.y) + 1;
		var zEnd = Math.ceil((searchbox.zMax - bounds.zMin) / this.cellSize.z) + 1;

		var foundSurfaces = [];

		for (surf in this.surfaces) {
			surf.key = false;
		}

		// Insert the surface references from [xStart, yStart, zStart] to [xEnd, yEnd, zEnd] into the map
		for (i in xStart...xEnd) {
			for (j in yStart...yEnd) {
				for (k in zStart...zEnd) {
					var hash = hashVector(i, j, k);
					if (this.map.exists(hash)) {
						var surfs = this.map.get(hash);
						var actualsurfs = surfs.map(x -> this.surfaces[x]);
						for (surf in actualsurfs) {
							if (surf.key)
								continue;
							if (searchbox.containsBounds(surf.boundingBox) || searchbox.collide(surf.boundingBox)) {
								foundSurfaces.push(surf);
								surf.key = true;
							}
						}
					}
				}
			}
		}

		return foundSurfaces;
	}

	function elegantPair(x:Int, y:Int) {
		return (x >= y) ? (x * x + x + y) : (y * y + x);
	}

	function hashVector(x:Int, y:Int, z:Int) {
		return elegantPair(elegantPair(x, y), z);
	}

	public function rayCast(origin:Vector, direction:Vector) {
		var cell = origin.sub(this.bounds.getMin().toVector());
		cell.x /= this.cellSize.x;
		cell.y /= this.cellSize.y;
		cell.z /= this.cellSize.z;

		var stepX, outX, X = Math.floor(cell.x);
		var stepY, outY, Y = Math.floor(cell.y);
		var stepZ, outZ, Z = Math.floor(cell.z);

		if ((X < 0) || (X >= CELL_DIV.x) || (Y < 0) || (Y >= CELL_DIV.y) || (Z < 0) || (Z >= CELL_DIV.z))
			return [];

		var cb = new Vector();

		if (direction.x > 0) {
			stepX = 1;
			outX = CELL_DIV.x;
			cb.x = this.bounds.getMin().x + (X + 1) * this.cellSize.x;
		} else {
			stepX = -1;
			outX = -1;
			cb.x = this.bounds.getMin().x + X * this.cellSize.x;
		}
		if (direction.y > 0.0) {
			stepY = 1;
			outY = CELL_DIV.y;
			cb.y = this.bounds.getMin().y + (Y + 1) * this.cellSize.y;
		} else {
			stepY = -1;
			outY = -1;
			cb.y = this.bounds.getMin().y + Y * this.cellSize.y;
		}
		if (direction.z > 0.0) {
			stepZ = 1;
			outZ = CELL_DIV.z;
			cb.z = this.bounds.getMin().z + (Z + 1) * this.cellSize.z;
		} else {
			stepZ = -1;
			outZ = -1;
			cb.z = this.bounds.getMin().z + Z * this.cellSize.z;
		}

		var tmax = new Vector();
		var tdelta = new Vector();

		var rxr, ryr, rzr;
		if (direction.x != 0) {
			rxr = 1.0 / direction.x;
			tmax.x = (cb.x - origin.x) * rxr;
			tdelta.x = this.cellSize.x * stepX * rxr;
		} else
			tmax.x = 1000000;
		if (direction.y != 0) {
			ryr = 1.0 / direction.y;
			tmax.y = (cb.y - origin.y) * ryr;
			tdelta.y = this.cellSize.y * stepY * ryr;
		} else
			tmax.y = 1000000;
		if (direction.z != 0) {
			rzr = 1.0 / direction.z;
			tmax.z = (cb.z - origin.z) * rzr;
			tdelta.z = this.cellSize.z * stepZ * rzr;
		} else
			tmax.z = 1000000;

		for (surf in this.surfaces) {
			surf.key = false;
		}

		var results = [];

		while (true) {
			var hash = hashVector(X, Y, Z);
			if (this.map.exists(hash)) {
				var currentSurfaces = this.map.get(hash).map(x -> this.surfaces[x]);

				for (surf in currentSurfaces) {
					if (surf.key)
						continue;
					results = results.concat(surf.rayCast(origin, direction));
					surf.key = true;
				}
			}
			if (tmax.x < tmax.y) {
				if (tmax.x < tmax.z) {
					X = X + stepX;
					if (X == outX)
						break;
					tmax.x += tdelta.x;
				} else {
					Z = Z + stepZ;
					if (Z == outZ)
						break;
					tmax.z += tdelta.z;
				}
			} else {
				if (tmax.y < tmax.z) {
					Y = Y + stepY;
					if (Y == outY)
						break;
					tmax.y += tdelta.y;
				} else {
					Z = Z + stepZ;
					if (Z == outZ)
						break;
					tmax.z += tdelta.z;
				}
			}
		}

		return results;
	}
}
