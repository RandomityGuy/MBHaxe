package src;

import src.ResourceLoader;

class Mission {
	public function getDifPath(rawElementPath:String) {
		rawElementPath = rawElementPath.toLowerCase();
		var path = rawElementPath;
		if (StringTools.contains(path, 'interiors_mbg/'))
			path = StringTools.replace(path, 'interiors_mbg/', 'interiors/');
		return path;
	}
}
