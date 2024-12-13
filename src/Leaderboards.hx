package src;

import net.Net;
import haxe.Json;
import src.Http;
import src.Console;
import src.Settings;

typedef LBScore = {
	name:String,
	has_rec:Int,
	score:Float,
	platform:Int,
	rewind:Int,
}

enum abstract LeaderboardsKind(Int) {
	var All;
	var Rewind;
	var NoRewind;
}

class Leaderboards {
	static var host = "https://lb.randomityguy.me";
	static var game = "Platinum";

	public static function submitScore(mission:String, score:Float, rewindUsed:Bool, needsReplayCb:(Bool, Int) -> Void) {
		if (!StringTools.startsWith(mission, "data/"))
			mission = "data/" + mission;
		Http.post('${host}/api/submit', Json.stringify({
			mission: mission,
			score: score,
			game: game,
			name: Settings.highscoreName,
			uid: Settings.userId,
			rewind: rewindUsed ? 1 : 0,
			platform: Net.getPlatform()
		}), (b) -> {
			var s = b.toString();
			var jd = Json.parse(s);
			var status = jd.status;
			Console.log("Score submitted");
			needsReplayCb(status == "new_record", status == "new_record" ? jd.rowid : 0);
		}, (e) -> {
			Console.log("Score submission failed: " + e);
		});
	}

	public static function getScores(mission:String, kind:LeaderboardsKind, cb:Array<LBScore>->Void) {
		if (!StringTools.startsWith(mission, "data/"))
			mission = "data/" + mission;
		return Http.get('${host}/api/scores?mission=${StringTools.urlEncode(mission)}&game=${game}&view=${kind}&count=10', (b) -> {
			var s = b.toString();
			var scores:Array<LBScore> = Json.parse(s).scores;
			cb(scores);
		}, (e) -> {
			Console.log("Failed to get scores: " + e);
			cb([]);
		});
	}

	public static function submitReplay(ref:Int, replay:haxe.io.Bytes) {
		return Http.uploadFile('${host}/api/record?ref=${ref}', replay, (b) -> {
			Console.log("Replay submitted");
		}, (e) -> {
			Console.log("Replay submission failed: " + e);
		});
	}

	public static function watchTopReplay(mission:String, kind:LeaderboardsKind, cb:haxe.io.Bytes->Void) {
		if (!StringTools.startsWith(mission, "data/"))
			mission = "data/" + mission;
		return Http.get('${host}/api/replay?mission=${StringTools.urlEncode(mission)}&game=${game}&view=${kind}', (b) -> {
			cb(b);
		}, (e) -> {
			Console.log("Failed to get replay: " + e);
			cb(null);
		});
	}
}
