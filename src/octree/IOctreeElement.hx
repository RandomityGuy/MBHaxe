package octree;

import polygonal.ds.Prioritizable;

interface IOctreeElement extends Prioritizable {
	function getElementType():Int;
	function setPriority(priority:Int):Void;
}
