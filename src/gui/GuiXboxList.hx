package gui;

import h3d.Vector;

class GuiXboxList extends GuiControl {
	var currentOffset:Float = 0;

	public function new() {
		super();
	}

	public function addButton(icon:Int, name:String, func:GuiEvent->Void, addOffset:Float = 0) {
		var btn = new GuiXboxListButton(icon, name);
		btn.position = new Vector(0, currentOffset + addOffset);
		btn.extent = new Vector(502, 94);
		btn.pressedAction = func;
		this.addChild(btn);
		currentOffset += 60 + addOffset;
	}
}
