package gui;

import h3d.Vector;
import h2d.Tile;

class GuiBorderButtonTextCtrl extends GuiBorderButtonCtrl {
	var txtCtrl:GuiText;

	public var ratio = 0.3;

	public function new(atlas:Tile, font:h2d.Font, exts:{
		tl:Vector,
		tr:Vector,
		bl:Vector,
		br:Vector,
		top:Vector,
		left:Vector,
		right:Vector,
		bottom:Vector,
		fill:Vector,
		separation:Float
	} = null) {
		super(atlas, exts);
		txtCtrl = new GuiText(font);
		txtCtrl.position = new Vector();
		txtCtrl.extent = this.extent;
		txtCtrl.justify = Center;
		txtCtrl.text.textColor = 0;
		this.addChild(txtCtrl);
	}

	public function setExtent(extent:Vector) {
		this.extent = extent;
		txtCtrl.extent = extent;
		txtCtrl.position.y = extent.y * ratio; // Weird ratio shit that makes it as centered as possible
	}
}
