package gui;

@:publicFields
class GuiEvent {
	var sender:GuiControl;
	var propagate:Bool;

	public function new(sender:GuiControl) {
		this.sender = sender;
		this.propagate = true;
	}
}
