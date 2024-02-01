package net;

import haxe.io.Bytes;
import datachannel.RTCPeerConnection;
import datachannel.RTCDataChannel;
import net.MoveManager;

enum abstract GameplayState(Int) from Int to Int {
	var UNKNOWN;
	var LOBBY;
	var GAME;
}

@:publicFields
class ClientConnection extends GameConnection {
	var socket:RTCPeerConnection;
	var datachannel:RTCDataChannel;
	var rtt:Float;
	var pingSendTime:Float;
	var _rttRecords:Array<Float> = [];

	public function new(id:Int, socket:RTCPeerConnection, datachannel:RTCDataChannel) {
		super(id);
		this.socket = socket;
		this.datachannel = datachannel;
		this.state = GameplayState.LOBBY;
		this.rtt = 0;
	}

	override function sendBytes(b:Bytes) {
		datachannel.sendBytes(b);
	}
}

@:publicFields
class DummyConnection extends GameConnection {
	public function new(id:Int) {
		super(id);
		this.state = GameplayState.GAME;
	}
}

@:publicFields
abstract class GameConnection {
	var id:Int;
	var state:GameplayState;
	var moveManager:MoveManager;

	public function new(id:Int) {
		this.id = id;
		this.moveManager = new MoveManager(this);
	}

	public function ready() {
		state = GameplayState.GAME;
	}

	public function sendBytes(b:haxe.io.Bytes) {}
}
