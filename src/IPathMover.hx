package src;

/** Anything that advances along a path every frame/substep - `PathedInterior` and path-following
	`GameObject`s. See `MarbleWorld.movingObjects` / `Marble.advancePhysics`. */
interface IPathMover {
	function computeNextPathStep(dt:Float):Void;
	function advancePath(timeStep:Float):Void;
}
