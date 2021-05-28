package octreenarrowphase;

import polygonal.ds.Prioritizable;

interface IOctreeNode<T> extends Prioritizable {
	function getNodeType():Int;
}
