package gui;

import h3d.Vector;
import h2d.Tile;

class GuiButtonText extends GuiButton {
	var txtCtrl:GuiText;

	public var ratio = 0.25;

	public function new(images:Array<Tile>, font:h2d.Font) {
		super(images);
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
