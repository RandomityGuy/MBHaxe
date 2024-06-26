package net;

import net.BitStream.OutputBitStream;
import net.BitStream.InputBitStream;
import net.NetPacket.MarbleUpdatePacket;
import shapes.PowerUp;
import net.NetPacket.MarbleMovePacket;
import src.TimeState;
import src.Console;
import net.ClientConnection;
import net.Net.NetPacketType;
import src.MarbleWorld;
import net.Move;
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
	var serverTicks:Int;

	public function new(move:Move, motionDir:Vector, timeState:TimeState, serverTicks:Int, id:Int) {
		this.move = move;
		this.motionDir = motionDir;
		this.id = id;
		this.serverTicks = serverTicks;
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
	var maxSendMoveListSize = 30;

	var serverTargetMoveListSize = 3;
	var serverMaxMoveListSize = 8;
	var serverAvgMoveListSize = 3.0;
	var serverSmoothMoveAvg = 0.15;
	var serverMoveListSizeSlack = 1.5;
	var serverDefaultMinTargetMoveListSize = 3;
	var serverAbnormalMoveCount = 0;
	var serverLastRecvMove = 0;
	var serverLastAckMove = 0;

	public var stall = false;

	public function new(connection:GameConnection) {
		queuedMoves = [];
		nextMoveId = 0;
		this.connection = connection;
		var mv = new Move();
		mv.d = new Vector(0, 0);
	}

	public function recordMove(marble:Marble, motionDir:Vector, timeState:TimeState, serverTicks:Int) {
		if (queuedMoves.length >= maxMoves || stall) {
			return queuedMoves[queuedMoves.length - 1];
		}
		var move = new Move();
		move.d = new Vector();
		if (!MarbleGame.instance.paused) {
			move.d.x = Gamepad.getAxis(Settings.gamepadSettings.moveYAxis);
			move.d.y = -Gamepad.getAxis(Settings.gamepadSettings.moveXAxis);
			// if (@:privateAccess !MarbleGame.instance.world.playGui.isChatFocused()) {
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

			if (Key.isDown(Settings.controlsSettings.respawn) || Gamepad.isDown(Settings.gamepadSettings.respawn)) {
				move.respawn = true;
				@:privateAccess Key.keyPressed[Settings.controlsSettings.respawn] = 0;
				Gamepad.releaseKey(Settings.gamepadSettings.respawn);
			}

			if (MarbleGame.instance.touchInput.movementInput.pressed) {
				move.d.y = -MarbleGame.instance.touchInput.movementInput.value.x;
				move.d.x = MarbleGame.instance.touchInput.movementInput.value.y;
			}
			// }

			// quantize moves for client
			var qx = Std.int((move.d.x * 16) + 16);
			var qy = Std.int((move.d.y * 16) + 16);
			move.d.x = (qx - 16) / 16.0;
			move.d.y = (qy - 16) / 16.0;
		}

		var netMove = new NetMove(move, motionDir, timeState.clone(), serverTicks, nextMoveId++);
		queuedMoves.push(netMove);

		if (nextMoveId >= 65535) // 65535 is reserved for null move
			nextMoveId = 0;

		var moveStartIdx = queuedMoves.length - maxSendMoveListSize;
		if (moveStartIdx < 0)
			moveStartIdx = 0;

		var b = new OutputBitStream();
		var movePacket = new MarbleMovePacket();
		movePacket.clientId = Net.clientId;
		movePacket.moves = queuedMoves.slice(moveStartIdx);
		movePacket.clientTicks = timeState.ticks;
		b.writeByte(NetPacketType.MarbleMove);
		movePacket.serialize(b);

		Net.sendPacketToHostUnreliable(b);

		return netMove;
	}

	function copyMove(to:Int, from:Int) {
		queuedMoves[to].move = queuedMoves[from].move;
		queuedMoves[to].motionDir.load(queuedMoves[from].motionDir);
	}

	public inline function duplicateLastMove() {
		if (queuedMoves.length == 0)
			return;
		queuedMoves.insert(0, queuedMoves[0]);
	}

	public static inline function packMove(m:NetMove, b:OutputBitStream) {
		b.writeUInt16(m.id);
		b.writeByte(Std.int((m.move.d.x * 16) + 16));
		b.writeByte(Std.int((m.move.d.y * 16) + 16));
		b.writeFlag(m.move.jump);
		b.writeFlag(m.move.powerup);
		b.writeFlag(m.move.blast);
		b.writeFlag(m.move.respawn);
		b.writeFloat(m.motionDir.x);
		b.writeFloat(m.motionDir.y);
		b.writeFloat(m.motionDir.z);
		return b;
	}

	public static inline function unpackMove(b:InputBitStream) {
		var moveId = b.readUInt16();
		var move = new Move();
		move.d = new Vector();
		move.d.x = (b.readByte() - 16) / 16.0;
		move.d.y = (b.readByte() - 16) / 16.0;
		move.jump = b.readFlag();
		move.powerup = b.readFlag();
		move.blast = b.readFlag();
		move.respawn = b.readFlag();
		var motionDir = new Vector();
		motionDir.x = b.readFloat();
		motionDir.y = b.readFloat();
		motionDir.z = b.readFloat();
		var netMove = new NetMove(move, motionDir, MarbleGame.instance.world.timeState.clone(), 0, moveId);
		return netMove;
	}

	public inline function queueMove(m:NetMove) {
		if (serverLastRecvMove < m.id && serverLastAckMove < m.id) {
			queuedMoves.push(m);
			serverLastRecvMove = m.id;
		}
		// if (queuedMoves.length != 0) {
		// 	var lastQueuedMove = queuedMoves[queuedMoves.length - 1];
		// 	if (lastQueuedMove.id < m.id)
		// 		queuedMoves.push(m);
		// } else if (lastMove == null || lastMove.id < m.id) {
		// 	queuedMoves.push(m);
		// }
	}

	public function getNextMove() {
		if (Net.isHost) {
			serverAvgMoveListSize *= (1 - serverSmoothMoveAvg);
			serverAvgMoveListSize += serverSmoothMoveAvg * queuedMoves.length;
			if (serverAvgMoveListSize < serverTargetMoveListSize - serverMoveListSizeSlack
				&& queuedMoves.length < serverTargetMoveListSize
				&& queuedMoves.length != 0) {
				serverAvgMoveListSize = Math.max(Std.int(serverAvgMoveListSize + serverMoveListSizeSlack + 0.5), queuedMoves.length);
				// serverAbnormalMoveCount++;
				// if (serverAbnormalMoveCount > 3) {
				// 	serverTargetMoveListSize += 1;
				// 	if (serverTargetMoveListSize > serverMaxMoveListSize)
				// 		serverTargetMoveListSize = serverMaxMoveListSize;
				// }
				// Send null move
				return null;
			}
			if (queuedMoves.length > serverMaxMoveListSize
				|| (serverAvgMoveListSize > serverTargetMoveListSize + serverMoveListSizeSlack
					&& queuedMoves.length > serverTargetMoveListSize)) {
				// if (queuedMoves.length > serverMaxMoveListSize) {
				var dropAmt = queuedMoves.length - serverTargetMoveListSize;
				while (dropAmt-- > 0) {
					queuedMoves.pop();
				}
				// }
				serverAvgMoveListSize = serverTargetMoveListSize;
				// serverAbnormalMoveCount++;
				// if (serverAbnormalMoveCount > 3) {
				// 	serverTargetMoveListSize -= 1;
				// 	if (serverTargetMoveListSize < serverDefaultMinTargetMoveListSize)
				// 		serverTargetMoveListSize = serverDefaultMinTargetMoveListSize;
				// } else {
				// 	serverAbnormalMoveCount = 0;
				// }
			}
		}
		if (queuedMoves.length == 0) {
			// if (lastMove != null) {
			//	lastMove.id++; // So that we force client's move to be overriden by this one
			// }
			return lastMove;
		} else {
			lastMove = queuedMoves[0];
			queuedMoves.shift();
			lastAckMoveId = lastMove.id;
			return lastMove;
		}
	}

	public inline function getQueueSize() {
		return queuedMoves.length;
	}

	public function acknowledgeMove(m:NetMove, timeState:TimeState) {
		if (m.id == 65535 || m.id == -1) {
			return null;
		}
		if (m.id <= lastAckMoveId)
			return null; // Already acked
		if (queuedMoves.length == 0)
			return null;
		if (m.id >= nextMoveId) {
			return queuedMoves[0]; // Input lag
		}
		while (m.id != queuedMoves[0].id) {
			queuedMoves.shift();
		}
		var delta = -1;
		var mv = null;
		if (m.id == queuedMoves[0].id) {
			delta = queuedMoves[0].id - lastAckMoveId;
			mv = queuedMoves.shift();
			ackRTT = timeState.ticks - mv.timeState.ticks;
			// maxMoves = ackRTT + 2;
		}
		lastAckMoveId = m.id;
		return mv;
	}

	public function getMoveForTick(m:Int) {
		if (m <= lastAckMoveId)
			return null;
		if (m == 65535 || m == -1)
			return null;
		if (queuedMoves.length == 0)
			return null;
		for (i in 0...queuedMoves.length) {
			if (queuedMoves[i].id == m)
				return queuedMoves[i];
			if (queuedMoves[i].id > m)
				return null;
		}
		return null;
	}
}
