package gui;

import src.Gamepad;
import hxd.Key;
import gui.GuiControl.MouseState;
import h3d.Vector;

class GuiXboxList extends GuiControl {
	var currentOffset:Float = 0;
	var selected:Int = 0;

	var buttons:Array<GuiXboxListButton> = [];

	public function new() {
		super();
	}

	public function addButton(icon:Int, name:String, func:GuiEvent->Void, addOffset:Float = 0) {
		var btn = new GuiXboxListButton(icon, name);
		btn.position = new Vector(0, currentOffset + addOffset);
		btn.extent = new Vector(502, 94);
		btn.pressedAction = func;
		btn.list = this;
		this.addChild(btn);
		buttons.push(btn);
		currentOffset += 60 + addOffset;
		return btn;
	}

	override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);

		var prevSelected = selected;
		if (Key.isPressed(Key.DOWN) || Gamepad.isPressed(["dpadDown"]))
			selected++;
		if (Key.isPressed(Key.UP) || Gamepad.isPressed(["dpadUp"]))
			selected--;
		if (selected < 0)
			selected = buttons.length - 1;
		if (selected >= buttons.length)
			selected = 0;
		if (prevSelected != selected) {
			buttons[prevSelected].selected = false;
			buttons[selected].selected = true;
		}
		if (Key.isPressed(Key.ENTER) || Gamepad.isPressed(["A"]))
			buttons[selected].pressedAction(new GuiEvent(buttons[selected]));
	}
}
