package collision;

import h3d.col.Point;
import h3d.col.Bounds;
import h3d.Vector;

@:publicFields
class KDTreeNode {
	var axis:Int;
	var d:Float;
	var data:Array<Int> = [];
	var leftIndex:Int;
	var rightIndex:Int;

	public function new() {}
}

class KDTree {
	public var boxesPerBin = 8;
	public var maxDepth = 10;

	var elements:Array<CollisionSurface>;

	var nodes:Array<KDTreeNode> = [];

	static var searchArray:Array<Int> = [];
	static var searchArraySize = 0;
	static var searchKey = 0;

	public function new() {
		elements = [];
	}

	public inline function add(element:CollisionSurface) {
		elements.push(element);
	}

	public function build() {
		nodes = [];
		addNodes(elements, 0, elements.length, 0);
		for (i in 0...elements.length) {
			var element = elements[i];
			var insNodes = boundingSearchForLeaves(element.boundingBox);
			for (node in insNodes) {
				node.data.push(i);
			}
		}
	}

	public function boundingSearch(searchbox:Bounds) {
		var res = [];
		if (nodes.length == 0)
			return res;
		searchArraySize = 1;
		if (searchArray.length < searchArraySize)
			searchArray.push(0);
		searchArray[0] = 0;
		searchKey += 1;
		var arr = [0];
		while (arr.length != 0) {
			var idx = arr.pop(); // searchArray[searchArraySize - 1];
			searchArraySize--;
			var node = nodes[idx];
			if (node.leftIndex == node.rightIndex) {
				for (x in node.data) {
					if (elements[x].key != searchKey) {
						elements[x].key = searchKey;
						res.push(elements[x]);
					}
				}
			} else {
				var minVal = getValuePt(searchbox.getMin(), node.axis);
				var maxVal = getValuePt(searchbox.getMax(), node.axis);
				if (minVal <= node.d)
					arr.push(node.leftIndex);
				// pushToSearchArray(node.leftIndex);
				if (maxVal >= node.d)
					arr.push(node.rightIndex);
				// pushToSearchArray(node.rightIndex);
			}
		}
		return res;
	}

	public inline function pushToSearchArray(i:Int) {
		searchArraySize++;
		while (searchArray.length < searchArraySize)
			searchArray.push(0);
		searchArray[searchArraySize - 1] = i;
	}

	function boundingSearchForLeaves(searchbox:Bounds) {
		var res = [];
		if (nodes.length == 0)
			return res;
		var stack = [0];
		while (stack.length != 0) {
			var idx = stack.pop();
			var node = nodes[idx];
			if (node.leftIndex == node.rightIndex) {
				res.push(node);
			} else {
				var minVal = getValuePt(searchbox.getMin(), node.axis);
				var maxVal = getValuePt(searchbox.getMax(), node.axis);
				if (minVal <= node.d)
					stack.push(node.leftIndex);
				if (maxVal >= node.d)
					stack.push(node.rightIndex);
			}
		}
		return res;
	}

	function addNodes(boxes:Array<CollisionSurface>, start:Int, end:Int, depth:Int) {
		var node = new KDTreeNode();
		if (end - start < this.boxesPerBin || depth == maxDepth) {
			node.axis = -1;
			node.leftIndex = -1;
			node.rightIndex = -1;
			nodes.push(node);
			return nodes.length - 1;
		}
		var ret = nodes.length;
		nodes.push(node);
		sortOnMinAxis(boxes, start, end, depth % 3);
		var minSplitIndex = start + end >> 1;
		var minSplitVal = 0.5 * (getMinValue(boxes[minSplitIndex], depth % 3) + getMinValue(boxes[minSplitIndex + 1], depth % 3));
		sortOnMaxAxis(boxes, start, end, depth % 3);
		var maxSplitIndex = start + end >> 1;
		var maxSplitVal = 0.5 * (getMaxValue(boxes[maxSplitIndex], depth % 3) + getMaxValue(boxes[maxSplitIndex + 1], depth % 3));
		var splitVal = 0.5 * (minSplitVal + maxSplitVal);
		var splitIndex = start;
		while (splitIndex < end && getMaxValue(boxes[splitIndex], depth % 3) <= splitVal) {
			splitIndex++;
		}
		node.rightIndex = addNodes(boxes, splitIndex, end, depth + 1);
		sortOnMinAxis(boxes, start, end, depth % 3);
		splitIndex = start;
		while (splitIndex < end && getMinValue(boxes[splitIndex], depth % 3) <= splitVal) {
			splitIndex++;
		}
		node.leftIndex = addNodes(boxes, start, splitIndex, depth + 1);
		node.axis = depth % 3;
		node.d = splitVal;
		nodes[ret] = node;
		return ret;
	}

	public inline function getValue(pt:Vector, axis:Int) {
		if (axis == 0)
			return pt.x;
		else if (axis == 1)
			return pt.y;
		else
			return pt.z;
	}

	public inline function getValuePt(pt:Point, axis:Int) {
		if (axis == 0)
			return pt.x;
		else if (axis == 1)
			return pt.y;
		else
			return pt.z;
	}

	public inline function getMinValue(element:CollisionSurface, axis:Int) {
		if (axis == 0)
			return element.boundingBox.xMin;
		else if (axis == 1)
			return element.boundingBox.yMin;
		else
			return element.boundingBox.zMin;
	}

	public inline function getMaxValue(element:CollisionSurface, axis:Int) {
		if (axis == 0)
			return element.boundingBox.xMax;
		else if (axis == 1)
			return element.boundingBox.yMax;
		else
			return element.boundingBox.zMax;
	}

	public inline function sortOnAxis(points:Array<Vector>, start:Int, end:Int, axis:Int) {
		var slice = points.slice(start, end);
		slice.sort(function(a:Vector, b:Vector) {
			if (axis == 0)
				return (a.x > b.x) ? 1 : (a.x < b.x) ? -1 : 0;
			else if (axis == 1)
				return (a.y > b.y) ? 1 : (a.y < b.y) ? -1 : 0;
			else
				return (a.z > b.z) ? 1 : (a.z < b.z) ? -1 : 0;
		});
		return points.slice(start, end).concat(slice).concat(points.slice(end));
	}

	public inline function sortOnMinAxis(elements:Array<CollisionSurface>, start:Int, end:Int, axis:Int) {
		var slice = elements.slice(start, end);
		slice.sort(function(a:CollisionSurface, b:CollisionSurface) {
			if (axis == 0)
				return (a.boundingBox.xMin > b.boundingBox.xMin) ? 1 : (a.boundingBox.xMin < b.boundingBox.xMin) ? -1 : 0;
			else if (axis == 1)
				return (a.boundingBox.yMin > b.boundingBox.yMin) ? 1 : (a.boundingBox.yMin < b.boundingBox.yMin) ? -1 : 0;
			else
				return (a.boundingBox.zMin > b.boundingBox.zMin) ? 1 : (a.boundingBox.zMin < b.boundingBox.zMin) ? -1 : 0;
		});
		return elements.slice(start, end).concat(slice).concat(elements.slice(end));
	}

	public inline function sortOnMaxAxis(elements:Array<CollisionSurface>, start:Int, end:Int, axis:Int) {
		var slice = elements.slice(start, end);
		slice.sort(function(a:CollisionSurface, b:CollisionSurface) {
			if (axis == 0)
				return (a.boundingBox.xMax > b.boundingBox.xMax) ? 1 : (a.boundingBox.xMax < b.boundingBox.xMax) ? -1 : 0;
			else if (axis == 1)
				return (a.boundingBox.yMax > b.boundingBox.yMax) ? 1 : (a.boundingBox.yMax < b.boundingBox.yMax) ? -1 : 0;
			else
				return (a.boundingBox.zMax > b.boundingBox.zMax) ? 1 : (a.boundingBox.zMax < b.boundingBox.zMax) ? -1 : 0;
		});
		return elements.slice(start, end).concat(slice).concat(elements.slice(end));
	}
}
