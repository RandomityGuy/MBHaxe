package collision;

import haxe.Exception;
import h3d.Vector;
import h3d.col.Bounds;
import src.Util;

@:publicFields
@:structInit
class GridBroadphaseProxy {
	var index:Int;
	var object:CollisionEntity;
	var xMin:Int;
	var xMax:Int;
	var yMin:Int;
	var yMax:Int;
}

class GridBroadphase {
	public var bounds:Bounds; // The bounds of the grid

	public var cellSize:Vector; // The dimensions of one cell

	static var CELL_SIZE = 16;

	public var CELL_DIV = new Vector(CELL_SIZE, CELL_SIZE); // split the bounds into cells of dimensions 1/16th of the corresponding dimensions of the bounds

	var cells:Array<Array<Int>> = [];

	var objects:Array<GridBroadphaseProxy> = [];
	var objectToProxy:Map<CollisionEntity, GridBroadphaseProxy> = [];
	var searchKey:Int = 0;

	var _built = false;
	var hasBounds:Bool = false;

	public function new() {
		// this.bounds = bounds.clone();

		// this.cellSize = new Vector(bounds.xSize / CELL_DIV.x, bounds.ySize / CELL_DIV.y);
		for (i in 0...CELL_SIZE) {
			for (j in 0...CELL_SIZE) {
				this.cells.push([]);
			}
		}
	}

	public function insert(object:CollisionEntity) {
		if (!_built) {
			var idx = this.objects.length;
			this.objects.push({
				object: object,
				xMin: 1000,
				yMin: 1000,
				xMax: -1000,
				yMax: -1000,
				index: idx,
			});
			objectToProxy.set(object, this.objects[this.objects.length - 1]);
		} else {
			var idx = this.objects.length;
			var proxy:GridBroadphaseProxy = {
				object: object,
				xMin: 1000,
				yMin: 1000,
				xMax: -1000,
				yMax: -1000,
				index: idx,
			};
			this.objects.push(proxy);
			objectToProxy.set(object, proxy);

			var queryMinX = Math.max(object.boundingBox.xMin, bounds.xMin);
			var queryMinY = Math.max(object.boundingBox.yMin, bounds.yMin);
			var queryMaxX = Math.min(object.boundingBox.xMax, bounds.xMax);
			var queryMaxY = Math.min(object.boundingBox.yMax, bounds.yMax);
			var xStart = Math.floor((queryMinX - bounds.xMin) / this.cellSize.x);
			var yStart = Math.floor((queryMinY - bounds.yMin) / this.cellSize.y);
			var xEnd = Math.ceil((queryMaxX - bounds.xMin) / this.cellSize.x);
			var yEnd = Math.ceil((queryMaxY - bounds.yMin) / this.cellSize.y);

			for (i in xStart...xEnd) {
				for (j in yStart...yEnd) {
					this.cells[16 * i + j].push(idx);
					proxy.xMin = Std.int(Math.min(proxy.xMin, i));
					proxy.yMin = Std.int(Math.min(proxy.yMin, j));
					proxy.xMax = Std.int(Math.max(proxy.xMax, i));
					proxy.yMax = Std.int(Math.max(proxy.yMax, j));
				}
			}
		}
	}

	public function remove(object:CollisionEntity) {
		var proxy = objectToProxy.get(object);
		if (proxy == null)
			return;
		for (i in proxy.xMin...(proxy.xMax + 1)) {
			for (j in proxy.yMin...(proxy.yMax + 1)) {
				this.cells[16 * i + j].remove(proxy.index);
			}
		}
		this.objects[proxy.index] = null; // Preserve indices pls
		objectToProxy.remove(object);
	}

	public function update(object:CollisionEntity) {
		if (!_built)
			return;
		var queryMinX = Math.max(object.boundingBox.xMin, bounds.xMin);
		var queryMinY = Math.max(object.boundingBox.yMin, bounds.yMin);
		var queryMaxX = Math.min(object.boundingBox.xMax, bounds.xMax);
		var queryMaxY = Math.min(object.boundingBox.yMax, bounds.yMax);
		var xStart = Math.floor((queryMinX - bounds.xMin) / this.cellSize.x);
		var yStart = Math.floor((queryMinY - bounds.yMin) / this.cellSize.y);
		var xEnd = Math.floor((queryMaxX - bounds.xMin) / this.cellSize.x);
		var yEnd = Math.floor((queryMaxY - bounds.yMin) / this.cellSize.y);
		var proxy = objectToProxy.get(object);
		if (proxy == null) {
			insert(object);
		} else {
			// Update the cells
			if (xStart != proxy.xMin || yStart != proxy.yMin || xEnd != proxy.xMax || yEnd != proxy.yMax) {
				// Rebin the object
				for (i in proxy.xMin...(proxy.xMax + 1)) {
					for (j in proxy.yMin...(proxy.yMax + 1)) {
						this.cells[16 * i + j].remove(proxy.index);
					}
				}
				for (i in xStart...(xEnd + 1)) {
					for (j in yStart...(yEnd + 1)) {
						this.cells[16 * i + j].push(proxy.index);
					}
				}
				proxy.xMin = xStart;
				proxy.yMin = yStart;
				proxy.xMax = xEnd;
				proxy.yMax = yEnd;
			}
		}
	}

	public function setBounds(bounds:Bounds) {
		this.bounds = bounds.clone();
		this.cellSize = new Vector(bounds.xSize / CELL_DIV.x, bounds.ySize / CELL_DIV.y);
		this.hasBounds = true;
	}

	public function build() {
		if (_built)
			return;
		_built = true;
		// Find the bounds
		if (!hasBounds) {
			var xMin = 1e8;
			var xMax = -1e8;
			var yMin = 1e8;
			var yMax = -1e8;
			var zMin = 1e8;
			var zMax = -1e8;
			for (i in 0...this.objects.length) {
				if (this.objects[i] == null)
					continue;
				var surface = this.objects[i].object;
				xMin = Math.min(xMin, surface.boundingBox.xMin);
				xMax = Math.max(xMax, surface.boundingBox.xMax);
				yMin = Math.min(yMin, surface.boundingBox.yMin);
				yMax = Math.max(yMax, surface.boundingBox.yMax);
				zMin = Math.min(zMin, surface.boundingBox.zMin);
				zMax = Math.max(zMax, surface.boundingBox.zMax);
			}
			// Some padding
			xMin -= 100;
			xMax += 100;
			yMin -= 100;
			yMax += 100;
			zMin -= 100;
			zMax += 100;
			this.bounds = Bounds.fromValues(xMin, yMin, zMin, xMax - xMin, yMax - yMin, zMax - zMin);
			this.cellSize = new Vector(this.bounds.xSize / CELL_DIV.x, this.bounds.ySize / CELL_DIV.y);
		}

		// Insert the objects
		for (i in 0...CELL_SIZE) {
			var minX = this.bounds.xMin;
			var maxX = this.bounds.xMin;
			minX += i * this.cellSize.x;
			maxX += (i + 1) * this.cellSize.x;
			for (j in 0...CELL_SIZE) {
				var minY = this.bounds.yMin;
				var maxY = this.bounds.yMin;
				minY += j * this.cellSize.y;
				maxY += (j + 1) * this.cellSize.y;

				var binRect = new h2d.col.Bounds();
				binRect.xMin = minX;
				binRect.yMin = minY;
				binRect.xMax = maxX;
				binRect.yMax = maxY;

				for (idx in 0...this.objects.length) {
					if (this.objects[idx] == null)
						continue;
					var surface = this.objects[idx];
					var hullRect = new h2d.col.Bounds();
					hullRect.xMin = surface.object.boundingBox.xMin;
					hullRect.yMin = surface.object.boundingBox.yMin;
					hullRect.xMax = surface.object.boundingBox.xMax;
					hullRect.yMax = surface.object.boundingBox.yMax;

					if (hullRect.intersects(binRect)) {
						this.cells[16 * i + j].push(idx);
						surface.xMin = Std.int(Math.min(surface.xMin, i));
						surface.yMin = Std.int(Math.min(surface.yMin, j));
						surface.xMax = Std.int(Math.max(surface.xMax, i));
						surface.yMax = Std.int(Math.max(surface.yMax, j));
					}
				}
			}
		}
	}

	// searchbox should be in LOCAL coordinates
	public function boundingSearch(searchbox:Bounds) {
		var queryMinX = Math.max(searchbox.xMin, bounds.xMin);
		var queryMinY = Math.max(searchbox.yMin, bounds.yMin);
		var queryMaxX = Math.min(searchbox.xMax, bounds.xMax);
		var queryMaxY = Math.min(searchbox.yMax, bounds.yMax);
		var xStart = Math.floor((queryMinX - bounds.xMin) / this.cellSize.x);
		var yStart = Math.floor((queryMinY - bounds.yMin) / this.cellSize.y);
		var xEnd = Math.ceil((queryMaxX - bounds.xMin) / this.cellSize.x);
		var yEnd = Math.ceil((queryMaxY - bounds.yMin) / this.cellSize.y);

		if (xStart < 0)
			xStart = 0;
		if (yStart < 0)
			yStart = 0;
		if (xEnd > CELL_SIZE)
			xEnd = CELL_SIZE;
		if (yEnd > CELL_SIZE)
			yEnd = CELL_SIZE;

		var foundSurfaces = [];

		searchKey++;

		// Insert the surface references from [xStart, yStart, zStart] to [xEnd, yEnd, zEnd] into the map
		for (i in xStart...xEnd) {
			for (j in yStart...yEnd) {
				for (surfIdx in cells[16 * i + j]) {
					var surf = objects[surfIdx].object;
					if (surf.key == searchKey)
						continue;
					surf.key = searchKey;
					if (searchbox.containsBounds(surf.boundingBox) || searchbox.collide(surf.boundingBox)) {
						foundSurfaces.push(surf);
						surf.key = searchKey;
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

	public function rayCast(origin:Vector, direction:Vector, bestT:Float) {
		var cell = origin.sub(this.bounds.getMin().toVector());
		cell.x /= this.cellSize.x;
		cell.y /= this.cellSize.y;
		var destCell = origin.add(direction.multiply(bestT)).sub(this.bounds.getMin().toVector());
		destCell.x /= this.cellSize.x;
		destCell.y /= this.cellSize.y;
		var stepX, outX, X = Math.floor(cell.x);
		var stepY, outY, Y = Math.floor(cell.y);
		var destX = Util.clamp(Math.max(Math.floor(destCell.x), 0), 0, CELL_DIV.x);
		var destY = Util.clamp(Math.max(Math.floor(destCell.y), 0), 0, CELL_DIV.y);
		if ((X < 0) || (X >= CELL_DIV.x) || (Y < 0) || (Y >= CELL_DIV.y)) {
			return [];
		}
		var cb = new Vector();
		if (direction.x > 0) {
			stepX = 1;
			outX = destX;
			if (outX == X)
				outX = Math.min(CELL_DIV.x, outX + 1);
			cb.x = this.bounds.xMin + (X + 1) * this.cellSize.x;
		} else {
			stepX = -1;
			outX = destX - 1;
			cb.x = this.bounds.xMin + X * this.cellSize.x;
		}
		if (direction.y > 0.0) {
			stepY = 1;
			outY = destY;
			if (outY == Y)
				outY = Math.min(CELL_DIV.y, outY + 1);
			cb.y = this.bounds.yMin + (Y + 1) * this.cellSize.y;
		} else {
			stepY = -1;
			outY = destY - 1;
			cb.y = this.bounds.yMin + Y * this.cellSize.y;
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
		searchKey++;
		var results = [];
		while (true) {
			var cell = cells[16 * X + Y];
			for (idx in cell) {
				var surf = objects[idx].object;
				if (surf.key == searchKey)
					continue;
				surf.key = searchKey;
				bestT = surf.rayCast(origin, direction, results, bestT);
			}
			if (tmax.x < tmax.y) {
				X = X + stepX;
				if (X == outX)
					break;
				tmax.x += tdelta.x;
			} else {
				Y = Y + stepY;
				if (Y == outY)
					break;
				tmax.y += tdelta.y;
			}
		}
		return results;
	}
}
