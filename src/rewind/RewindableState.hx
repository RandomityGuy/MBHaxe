package rewind;

import src.MarbleWorld;

interface RewindableState {
	function apply(level:MarbleWorld):Void;
	function clone():RewindableState;
}
