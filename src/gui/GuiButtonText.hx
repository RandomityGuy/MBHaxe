package gui;

import h3d.Vector;
import h2d.Tile;

class GuiButtonText extends GuiButton {
	var txtCtrl:GuiText;

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
		txtCtrl.position.y = 5 * extent.y / 16; // Weird ratio shit that makes it as centered as possible
	}
}
