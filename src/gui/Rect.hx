package gui;

import h3d.Vector;

@:publicFields
class Rect {
	var position:Vector;
	var extent:Vector;
	var scroll:Vector;

	public function new(position:Vector, extent:Vector) {
		this.position = position.clone();
		this.extent = extent.clone();
		this.scroll = new Vector();
	}

	public function inRect(point:Vector) {
		return (position.x <= point.x && (position.x + extent.x) >= point.x)
			&& (position.y <= point.y && (position.y + extent.y) >= point.y);
	}

	public function intersect(other:Rect) {
		var rectangle = new h2d.col.Bounds();
		rectangle.addPoint(new h2d.col.Point(position.x, position.y));
		rectangle.addPoint(new h2d.col.Point(position.x + extent.x, position.y + extent.y));

		var otherrectangle = new h2d.col.Bounds();
		otherrectangle.addPoint(new h2d.col.Point(other.position.x, other.position.y));
		otherrectangle.addPoint(new h2d.col.Point(other.position.x + other.extent.x, other.position.y + other.extent.y));

		var isec = rectangle.intersection(otherrectangle);

		return new Rect(new Vector(isec.xMin, isec.yMin), new Vector(isec.xMax - isec.xMin, isec.yMax - isec.yMin));
	}
}
