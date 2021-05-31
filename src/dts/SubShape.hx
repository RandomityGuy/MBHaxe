package dts;

class SubShape {
	public var firstNode:Int;
	public var firstObject:Int;
	public var firstDecal:Int;
	public var numNodes:Int;
	public var numObjects:Int;
	public var numDecals:Int;

	public function new(firstNode:Int, firstObject:Int, firstDecal:Int, numNodes:Int, numObjects:Int, numDecals:Int) {
		this.firstNode = firstNode;
		this.firstObject = firstObject;
		this.firstDecal = firstDecal;
		this.numNodes = numNodes;
		this.numObjects = numObjects;
		this.numDecals = numDecals;
	}
}
