package dts;

@:publicFields
class TSDrawPrimitive {
	static var Triangles = 0 << 30;
	static var Strip = 1 << 30;
	static var Fan = 2 << 30;
	static var Indexed = 1 << 29;
	static var NoMaterial = 1 << 28;
	static var MaterialMask = ~(1 << 30 | 2 << 30 | 0 << 30 | 1 << 29 | 1 << 28);
	static var TypeMask = (1 << 30 | 2 << 30 | 0 << 30);
}
