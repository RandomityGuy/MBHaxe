package octree;

import h3d.Vector;
import h3d.col.Bounds;

interface IOctreeObject extends IOctreeElement {
	var boundingBox:Bounds;
	function isIntersectedByRay(rayOrigin:Vector, rayDirection:Vector, intersectionPoint:Vector, intersectionNormal:Vector):Bool;
}
