package net;

import shapes.PowerUp;
import net.NetPacket.MarbleMovePacket;
import src.TimeState;
import src.Console;
import net.ClientConnection;
import net.Net.NetPacketType;
import src.MarbleWorld;
import src.Marble.Move;
import h3d.Vector;
import src.Gamepad;
import src.Settings;
import hxd.Key;
import src.MarbleGame;
import src.Util;
import src.Marble;

@:publicFields
class NetMove {
	var motionDir:Vector;
	var move:Move;
	var id:Int;
	var timeState:TimeState;
	// For rewind purposes
	var powerup:PowerUp;
	var powerupStates:Array<Float>;
	var helicopterState:Float;
	var megaState:Float;
	var blastAmt:Float;

	public function new(move:Move, motionDir:Vector, timeState:TimeState, id:Int) {
		this.move = move;
		this.motionDir = motionDir;
		this.id = id;
		this.timeState = timeState;
	}
}

class MoveManager {
	var connection:GameConnection;
	var queuedMoves:Array<NetMove>;
	var nextMoveId:Int;
	var lastMove:NetMove;
	var lastAckMoveId:Int = -1;
	var ackRTT:Int = -1;

	var maxMoves = 45;

	public var stall = false;

	public function new(connection:GameConnection) {
		queuedMoves = [];
		nextMoveId = 0;
		this.connection = connection;
		var mv = new Move();
		mv.d = new Vector(0, 0);
	}

	public function recordMove(marble:Marble, motionDir:Vector, timeState:TimeState) {
		if (queuedMoves.length >= maxMoves || stall)
			return queuedMoves[queuedMoves.length - 1];
		var move = new Move();
		move.d = new Vector();
		move.d.x = Gamepad.getAxis(Settings.gamepadSettings.moveYAxis);
		move.d.y = -Gamepad.getAxis(Settings.gamepadSettings.moveXAxis);
		if (Key.isDown(Settings.controlsSettings.forward)) {
			move.d.x -= 1;
		}
		if (Key.isDown(Settings.controlsSettings.backward)) {
			move.d.x += 1;
		}
		if (Key.isDown(Settings.controlsSettings.left)) {
			move.d.y += 1;
		}
		if (Key.isDown(Settings.controlsSettings.right)) {
			move.d.y -= 1;
		}
		if (Key.isDown(Settings.controlsSettings.jump)
			|| MarbleGame.instance.touchInput.jumpButton.pressed
			|| Gamepad.isDown(Settings.gamepadSettings.jump)) {
			move.jump = true;
		}
		if ((!Util.isTouchDevice() && Key.isDown(Settings.controlsSettings.powerup))
			|| (Util.isTouchDevice() && MarbleGame.instance.touchInput.powerupButton.pressed)
			|| Gamepad.isDown(Settings.gamepadSettings.powerup)) {
			move.powerup = true;
		}

		if (Key.isDown(Settings.controlsSettings.blast)
			|| (MarbleGame.instance.touchInput.blastbutton.pressed)
			|| Gamepad.isDown(Settings.gamepadSettings.blast))
			move.blast = true;

		if (MarbleGame.instance.touchInput.movementInput.pressed) {
			move.d.y = -MarbleGame.instance.touchInput.movementInput.value.x;
			move.d.x = MarbleGame.instance.touchInput.movementInput.value.y;
		}

		var netMove = new NetMove(move, motionDir, timeState.clone(), nextMoveId++);
		netMove.powerup = marble.heldPowerup;
		netMove.powerupStates = [];
		netMove.helicopterState = @:privateAccess marble.helicopterEnableTime;
		netMove.megaState = @:privateAccess marble.megaMarbleEnableTime;
		netMove.blastAmt = marble.blastAmount;
		for (pw in marble.level.powerUps) {
			netMove.powerupStates.push(pw.lastPickUpTime);
		}
		queuedMoves.push(netMove);

		if (nextMoveId >= 65535) // 65535 is reserved for null move
			nextMoveId = 0;

		var b = new haxe.io.BytesOutput();
		var movePacket = new MarbleMovePacket();
		movePacket.clientId = Net.clientId;
		movePacket.move = netMove;
		movePacket.clientTicks = timeState.ticks;
		b.writeByte(NetPacketType.MarbleMove);
		movePacket.serialize(b);

		Net.sendPacketToHost(b);

		return netMove;
	}

	public static inline function packMove(m:NetMove, b:haxe.io.BytesOutput) {
		b.writeUInt16(m.id);
		b.writeByte(Std.int((m.move.d.x * 16) + 16));
		b.writeByte(Std.int((m.move.d.y * 16) + 16));
		var flags = 0;
		if (m.move.jump)
			flags |= 1;
		if (m.move.powerup)
			flags |= 2;
		if (m.move.blast)
			flags |= 4;
		b.writeByte(flags);
		b.writeFloat(m.motionDir.x);
		b.writeFloat(m.motionDir.y);
		b.writeFloat(m.motionDir.z);
		return b;
	}

	public static inline function unpackMove(b:haxe.io.BytesInput) {
		var moveId = b.readUInt16();
		var move = new Move();
		move.d = new Vector();
		move.d.x = (b.readByte() - 16) / 16.0;
		move.d.y = (b.readByte() - 16) / 16.0;
		var flags = b.readByte();
		move.jump = (flags & 1) != 0;
		move.powerup = (flags & 2) != 0;
		move.blast = (flags & 4) != 0;
		var motionDir = new Vector();
		motionDir.x = b.readFloat();
		motionDir.y = b.readFloat();
		motionDir.z = b.readFloat();
		var netMove = new NetMove(move, motionDir, MarbleGame.instance.world.timeState.clone(), moveId);
		return netMove;
	}

	public function queueMove(m:NetMove) {
		queuedMoves.push(m);
	}

	public function getNextMove() {
		if (queuedMoves.length == 0)
			return lastMove;
		else {
			lastMove = queuedMoves[0];
			queuedMoves.shift();
			return lastMove;
		}
	}

	public function getQueueSize() {
		return queuedMoves.length;
	}

	public function acknowledgeMove(m:Int, timeState:TimeState) {
		if (m == 65535 || m == -1)
			return null;
		if (m <= lastAckMoveId)
			return null; // Already acked
		if (queuedMoves.length == 0)
			return null;
		while (m != queuedMoves[0].id) {
			queuedMoves.shift();
		}
		var delta = -1;
		var mv = null;
		if (m == queuedMoves[0].id) {
			delta = queuedMoves[0].id - lastAckMoveId;
			mv = queuedMoves.shift();
			ackRTT = timeState.ticks - mv.timeState.ticks;
			maxMoves = ackRTT + 2;
		}
		lastAckMoveId = m;
		return mv;
	}
}
