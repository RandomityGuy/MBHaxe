import src.MissionList;
import gui.MessageBoxOkDlg;
import haxe.zip.Reader;
import haxe.io.BytesInput;
import haxe.Json;
import src.Http;
import src.Console;
import src.MarbleGame;
import src.ResourceLoader;

typedef MPCustomEntry = {
	artist:String,
	description:String,
	path:String,
	title:String
};

class MPCustoms {
	public static var missionList:Array<MPCustomEntry> = [];

	static var _requestSent = false;

	public static function loadMissionList() {
		if (missionList.length == 0 && !_requestSent) {
			_requestSent = true;
			Http.get("https://marbleblastultra.randomityguy.me/data/ultraCustom.json", (b) -> {
				var misList = Json.parse(b.toString());
				missionList = misList;
				missionList.sort((a, b) -> {
					var a1 = a.title.toLowerCase();
					var b1 = b.title.toLowerCase();
					return a1 < b1 ? -1 : (a1 > b1 ? 1 : 0);
				});
				Console.log('Loaded ${misList.length} custom missions.');
				_requestSent = false;
			}, (e) -> {
				Console.log('Error getting custom list from marbleland.');
				_requestSent = false;
			});
		}
	}

	public static function download(mission:MPCustomEntry, onFinish:() -> Void, onFail:() -> Void) {
		var lastSlashIdx = mission.path.lastIndexOf('/');
		var dlPath = "https://marbleblastultra.randomityguy.me/" + StringTools.urlEncode(mission.path.substr(0, lastSlashIdx)) + ".zip";
		Http.get(dlPath, (zipData) -> {
			var reader = new Reader(new BytesInput(zipData));
			var entries:Array<haxe.zip.Entry> = null;
			try {
				entries = [for (x in reader.read()) x];
			} catch (e) {}
			ResourceLoader.loadZip(entries, 'missions/mpcustom/');
			if (entries != null) {
				onFinish();
			} else {
				MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to download mission"));
				onFail();
			}
		}, (e) -> {
			MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to download mission"));
			onFail();
		});
	}

	public static function play(mission:MPCustomEntry, onFinish:() -> Void, onFail:() -> Void) {
		download(mission, () -> {
			var f = ResourceLoader.getFileEntry(mission.path);
			var mis = MissionList.parseMisHeader(f.entry.getBytes().toString(), mission.path);
			MarbleGame.instance.playMission(mis, true);
			onFinish();
		}, onFail);
	}
}
