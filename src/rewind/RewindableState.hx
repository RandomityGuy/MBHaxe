package rewind;

import src.MarbleWorld;

interface RewindableState {
	function apply(level:MarbleWorld):Void;
	function clone():RewindableState;
	function getSize():Int;
	function serialize(rm:RewindManager, bw:haxe.io.BytesOutput):Void;
	function deserialize(rm:RewindManager, br:haxe.io.BytesInput):Void;
}
