package octree;

import h3d.Vector;
import h3d.col.Bounds;

@:publicFields
@:structInit
class RayIntersectionData {
	var point:Vector;
	var normal:Vector;
	var object:IOctreeObject;
}

interface IOctreeObject extends IOctreeElement {
	var boundingBox:Bounds;
	function rayCast(rayOrigin:Vector, rayDirection:Vector):Array<RayIntersectionData>;
}
