package gui;

import gui.GuiControl.MouseState;
import h3d.Vector;
import src.Gamepad;
import hxd.Key;

class GuiXboxOptionsListCollection extends GuiControl {
	var offset:Float = 0;
	var selected:Int = 0;

	var options:Array<GuiXboxOptionsList> = [];

	public function new() {
		super();
	}

	public function addOption(icon:Int, name:String, options:Array<String>, onChange:Int->Bool, midColumn:Float = 0.3, textOff = 155.5) {
		var opt = new GuiXboxOptionsList(icon, name, options, midColumn, textOff);
		opt.vertSizing = Bottom;
		opt.horizSizing = Right;
		opt.position = new Vector(0, offset);
		offset += 60;
		opt.extent = new Vector(815, 94);
		opt.onChangeFunc = onChange;
		opt.list = this;
		this.addChild(opt);
		this.options.push(opt);
		return opt;
	}

	override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);

		if (!options[selected].selected)
			options[selected].selected = true;

		var prevSelected = selected;
		if (Key.isPressed(Key.DOWN) || Gamepad.isPressed(["dpadDown"]))
			selected++;
		if (Key.isPressed(Key.UP) || Gamepad.isPressed(["dpadUp"]))
			selected--;
		if (selected < 0)
			selected = options.length - 1;
		if (selected >= options.length)
			selected = 0;
		if (prevSelected != selected) {
			options[prevSelected].selected = false;
			options[selected].selected = true;
		}
	}
}
