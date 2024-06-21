package net;

import haxe.io.Bytes;
import datachannel.RTCPeerConnection;
import datachannel.RTCDataChannel;
import net.MoveManager;
import src.TimeState;

enum abstract GameplayState(Int) from Int to Int {
	var UNKNOWN;
	var LOBBY;
	var GAME;
}

enum abstract NetPlatform(Int) from Int to Int {
	var Unknown;
	var PC;
	var MacOS;
	var Web;
	var Android;
}

@:publicFields
class ClientConnection extends GameConnection {
	var socket:RTCPeerConnection;
	var datachannel:RTCDataChannel;
	var datachannelUnreliable:RTCDataChannel;
	var rtt:Float;
	var pingSendTime:Float;
	var _rttRecords:Array<Float> = [];
	var lastRecvTime:Float;
	var didWarnTimeout:Bool = false;

	public function new(id:Int, socket:RTCPeerConnection, datachannel:RTCDataChannel, datachannelUnreliable:RTCDataChannel) {
		super(id);
		this.socket = socket;
		this.datachannel = datachannel;
		this.datachannelUnreliable = datachannelUnreliable;
		this.state = GameplayState.LOBBY;
		this.rtt = 0;
		this.name = "Unknown";
	}

	override function sendBytes(b:Bytes) {
		datachannel.sendBytes(b);
	}

	override function sendBytesUnreliable(b:Bytes) {
		datachannelUnreliable.sendBytes(b);
	}

	public inline function needsTimeoutWarn(t:Float) {
		return (t - lastRecvTime) > 10 && !didWarnTimeout;
	}

	public inline function needsTimeoutKick(t:Float) {
		return (t - lastRecvTime) > 15 && didWarnTimeout;
	}
}

@:publicFields
class DummyConnection extends GameConnection {
	public function new(id:Int) {
		super(id);
		this.state = GameplayState.GAME;
		this.lobbyReady = true;
	}
}

@:publicFields
abstract class GameConnection {
	var id:Int;
	var state:GameplayState;
	var moveManager:MoveManager;
	var name:String;
	var lobbyReady:Bool;
	var platform:NetPlatform;
	var marbleId:Int;
	var marbleCatId:Int;

	function new(id:Int) {
		this.id = id;
		this.moveManager = new MoveManager(this);
		this.lobbyReady = false;
	}

	public function ready() {
		state = GameplayState.GAME;
	}

	public function toggleLobbyReady() {
		lobbyReady = !lobbyReady;
	}

	public function queueMove(m:NetMove) {
		moveManager.queueMove(m);
	}

	public inline function acknowledgeMove(m:NetMove, timeState:TimeState) {
		return moveManager.acknowledgeMove(m, timeState);
	}

	public inline function getQueuedMoves() {
		return @:privateAccess moveManager.queuedMoves;
	}

	public inline function getQueuedMovesLength() {
		return moveManager.getQueueSize();
	}

	public function recordMove(marble:src.Marble, motionDir:h3d.Vector, timeState:TimeState, serverTicks:Int) {
		return moveManager.recordMove(marble, motionDir, timeState, serverTicks);
	}

	public function getNextMove() {
		return moveManager.getNextMove();
	}

	public function sendBytes(b:haxe.io.Bytes) {}

	public function sendBytesUnreliable(b:haxe.io.Bytes) {}

	public inline function getName() {
		return name;
	}

	public inline function setName(value:String) {
		name = value;
	}

	public inline function setMarbleId(value:Int, category:Int) {
		marbleId = value;
		marbleCatId = category;
	}

	public inline function getMarbleId() {
		return marbleId;
	}

	public inline function getMarbleCatId() {
		return marbleCatId;
	}
}
