package rewind;

interface RewindableState {
	function clone():RewindableState;
	function getSize():Int;
	function serialize(rm:RewindManager, bw:haxe.io.BytesOutput):Void;
	function deserialize(rm:RewindManager, br:haxe.io.BytesInput):Void;
}
