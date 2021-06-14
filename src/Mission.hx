package src;

import mis.MissionElement.MissionElementSimGroup;
import src.ResourceLoader;

class Mission {
	public var root:MissionElementSimGroup;

	public function new() {}

	public function getDifPath(rawElementPath:String) {
		rawElementPath = rawElementPath.toLowerCase();
		var path = StringTools.replace(rawElementPath.substring(rawElementPath.indexOf('data/')), "\"", "");
		if (StringTools.contains(path, 'interiors_mbg/'))
			path = StringTools.replace(path, 'interiors_mbg/', 'interiors/');
		return path;
	}
}
