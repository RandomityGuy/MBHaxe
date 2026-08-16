package gui;

#if sys
enum abstract CursorKind(Int) {
	var Arrow = 0;
	var IBeam = 1;
	var Wait = 2;
	var CrossHair = 3;
	var WaitArrow = 4;
	var SizeNWSE = 5;
	var SizeNESW = 6;
	var SizeWE = 7;
	var SizeNS = 8;
	var SizeALL = 9;
	var No = 10;
	var Hand = 11;
}

class Cursors {
	static var cursors:Map<CursorKind, sdl.Cursor> = [];

	public static function setCursor(kind:CursorKind) {
		if (!cursors.exists(kind))
			cursors[kind] = sdl.Cursor.createSystem(cast kind);

		cursors[kind].set();
	}
}
#end
