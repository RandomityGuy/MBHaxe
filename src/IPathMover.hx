package src;

interface IPathMover {
	function computeNextPathStep(dt:Float):Void;
	function advancePath(timeStep:Float):Void;
}
