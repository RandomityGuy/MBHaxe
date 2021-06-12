package mis;

import mis.MissionElement.MissionElementSimGroup;

@:publicFields
class MisFile {
	var root:MissionElementSimGroup;

	/** The custom marble attributes overrides specified in the file. */
	var marbleAttributes:Map<String, String>;

	var activatedPackages:Array<String>;

	public function new() {}
}
