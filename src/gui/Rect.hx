package gui;

import h3d.Vector;

@:publicFields
class Rect {
	var position:Vector;
	var extent:Vector;

	public function new(position:Vector, extent:Vector) {
		this.position = position.clone();
		this.extent = extent.clone();
	}
}
