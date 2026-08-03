package mis;

import mis.MissionElement.MissionElementScriptObject;

/** Parses PQ's `.mcs` (multiplayer-coop) mission format. Structurally the same SimGroup-based
	body as a `.mis` file, but wrapped with an embedded `_GetMissionInfo()` function returning an
	anonymous `new ScriptObject() { ... };` block that has to be sliced out and parsed separately,
	then reinserted as a `MissionInfo`-named element (matching how `.mis` files have their
	`MissionInfo` ScriptObject inline in the SimGroup body already). */
class McsParser {
	var text:String;

	final activatePackageRegEx = ~/activatePackage\((.+?)\);/g;

	public function new(text:String) {
		this.text = text;
	}

	public function parse():MisFile {
		var indexOfMissionGroup = this.text.indexOf('new SimGroup(MissionGroup)');
		var missionEnd = this.text.indexOf('//--- MISSION END ---');
		var misData = "//--- OBJECT WRITE BEGIN ---\n" + this.text.substring(indexOfMissionGroup, missionEnd) + "//--- OBJECT WRITE END ---\n";

		var mdata = new MisParser(misData).parse();

		var minfo = getMissionInfo();
		if (minfo != null) {
			minfo._name = "MissionInfo";
			mdata.root.elements.insert(0, minfo);
		}

		var activatedPackages = [];
		var startText = this.text;

		// scan all the activated packages
		while (activatePackageRegEx.match(startText)) {
			activatedPackages.push(StringTools.replace(activatePackageRegEx.matched(1), "\"", "").toLowerCase());
			startText = activatePackageRegEx.matchedRight();
		}
		mdata.activatedPackages = mdata.activatedPackages.concat(activatedPackages);

		return mdata;
	}

	public function getMissionInfo():MissionElementScriptObject {
		var indexOfGMI = this.text.indexOf('_GetMissionInfo()');
		if (indexOfGMI == -1)
			return null;
		var indexOfMIStart = this.text.indexOf('new ScriptObject()', indexOfGMI);
		if (indexOfMIStart == -1)
			return null;
		var infoEnd = this.text.indexOf('};', indexOfMIStart);
		if (infoEnd == -1)
			return null;
		var miData = this.text.substring(indexOfMIStart, infoEnd + 2);
		miData = StringTools.replace(miData, "new ScriptObject()", "new ScriptObject(MissionInfo)");
		var miParser = new MisParser("//--- OBJECT WRITE BEGIN ---\n" + miData + "\n//--- OBJECT WRITE END ---\n");
		return miParser.parseMissionInfo();
	}
}
