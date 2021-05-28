package dif.math;

import dif.io.BytesWriter;
import dif.io.BytesReader;

@:expose
class Box3F {
	public var minX:Float;
	public var minY:Float;
	public var minZ:Float;
	public var maxX:Float;
	public var maxY:Float;
	public var maxZ:Float;

	public function new(minX = 0.0, minY = 0.0, minZ = 0.0, maxX = 0.0, maxY = 0.0, maxZ = 0.0) {
		this.minX = minX;
		this.minY = minY;
		this.minZ = minZ;
		this.maxX = maxX;
		this.maxY = maxY;
		this.maxZ = maxZ;
	}

	public function center() {
		return new Point3F(minX + maxX, minY + maxY, minZ + maxZ).scalarDiv(2);
	}

	public function Expand(point:Point3F) {
		if (minX > point.x)
			minX = point.x;
		if (minY > point.y)
			minY = point.y;
		if (minZ > point.z)
			minZ = point.z;

		if (maxX < point.x)
			maxX = point.x;
		if (maxY < point.y)
			maxY = point.y;
		if (maxZ < point.z)
			maxZ = point.z;
	}

	public static function PointBounds(point:Point3F, size:Point3F) {
		var ret = new Box3F();
		ret.minX = point.x;
		ret.minY = point.y;
		ret.minZ = point.z;
		ret.maxX = point.x + size.x;
		ret.maxY = point.y + size.y;
		ret.maxZ = point.z + size.z;
		return ret;
	}

	public function contains(p:Point3F) {
		return (minX <= p.x && p.x <= maxX && minY <= p.y && p.y <= maxY && minZ <= p.z && p.z <= maxZ);
	}

	public function getClosestPoint(point:Point3F) {
		var closest = new Point3F();
		if (minX > point.x)
			closest.x = minX;
		else if (maxX < point.x)
			closest.x = maxX;
		else
			closest.x = point.x;

		if (minY > point.y)
			closest.y = minY;
		else if (maxY < point.y)
			closest.y = maxY;
		else
			closest.y = point.y;

		if (minZ > point.z)
			closest.z = minZ;
		else if (maxZ < point.z)
			closest.z = maxZ;
		else
			closest.z = point.z;

		return closest;
	}

	public static function read(io:BytesReader) {
		var ret = new Box3F();
		ret.minX = io.readFloat();
		ret.minY = io.readFloat();
		ret.minZ = io.readFloat();
		ret.maxX = io.readFloat();
		ret.maxY = io.readFloat();
		ret.maxZ = io.readFloat();
		return ret;
	}

	public function write(io:BytesWriter) {
		io.writeFloat(this.minX);
		io.writeFloat(this.minY);
		io.writeFloat(this.minZ);
		io.writeFloat(this.maxX);
		io.writeFloat(this.maxY);
		io.writeFloat(this.maxZ);
	}
}
