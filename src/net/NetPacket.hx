package net;

import net.BitStream.InputBitStream;
import net.BitStream.OutputBitStream;
import h3d.Vector;
import net.MoveManager.NetMove;

interface NetPacket {
	public function serialize(b:OutputBitStream):Void;
	public function deserialize(b:InputBitStream):Void;
}

@:publicFields
class MarbleMovePacket implements NetPacket {
	var clientId:Int;
	var clientTicks:Int;
	var moves:Array<NetMove>;

	public function new() {
		moves = [];
	}

	public inline function deserialize(b:InputBitStream) {
		clientId = b.readByte();
		clientTicks = b.readUInt16();
		var count = b.readInt(5);
		moves = [];
		for (i in 0...count) {
			moves.push(MoveManager.unpackMove(b));
		}
	}

	public inline function serialize(b:OutputBitStream) {
		b.writeByte(clientId);
		b.writeUInt16(clientTicks);
		b.writeInt(moves.length, 5);
		for (move in moves)
			MoveManager.packMove(move, b);
	}
}

enum abstract MarbleNetFlags(Int) from Int to Int {
	var NullFlag = 0;
	var DoBlast = 1 << 0;
	var DoHelicopter = 1 << 1;
	var DoMega = 1 << 2;
	var PickupPowerup = 1 << 3;
	var GravityChange = 1 << 4;
	var UsePowerup = 1 << 5;
}

@:publicFields
class MarbleUpdatePacket implements NetPacket {
	var clientId:Int;
	var move:NetMove;
	var serverTicks:Int;
	var calculationTicks:Int = -1;
	var position:Vector;
	var velocity:Vector;
	var omega:Vector;
	var lastContactNormal:Vector;
	var blastAmount:Int;
	var blastTick:Int;
	var megaTick:Int;
	var heliTick:Int;
	var gravityDirection:Vector;
	var oob:Bool;
	var powerUpId:Int;
	var moveQueueSize:Int;
	var netFlags:Int;

	public function new() {}

	public inline function serialize(b:OutputBitStream) {
		b.writeByte(clientId);
		MoveManager.packMove(move, b);
		b.writeUInt16(serverTicks);
		b.writeByte(moveQueueSize);
		b.writeFloat(position.x);
		b.writeFloat(position.y);
		b.writeFloat(position.z);
		b.writeFloat(velocity.x);
		b.writeFloat(velocity.y);
		b.writeFloat(velocity.z);
		b.writeFloat(omega.x);
		b.writeFloat(omega.y);
		b.writeFloat(omega.z);
		b.writeFloat(lastContactNormal.x);
		b.writeFloat(lastContactNormal.y);
		b.writeFloat(lastContactNormal.z);
		b.writeInt(blastAmount, 11);
		if (netFlags & MarbleNetFlags.DoBlast > 0) {
			b.writeFlag(true);
			b.writeUInt16(blastTick);
		} else {
			b.writeFlag(false);
		}
		if (netFlags & MarbleNetFlags.DoHelicopter > 0) {
			b.writeFlag(true);
			b.writeUInt16(heliTick);
		} else {
			b.writeFlag(false);
		}
		if (netFlags & MarbleNetFlags.DoMega > 0) {
			b.writeFlag(true);
			b.writeUInt16(megaTick);
		} else {
			b.writeFlag(false);
		}
		b.writeFlag(oob);
		if (netFlags & MarbleNetFlags.UsePowerup > 0) {
			b.writeFlag(true);
		} else {
			b.writeFlag(false);
		}

		if (netFlags & MarbleNetFlags.PickupPowerup > 0) {
			b.writeFlag(true);
			b.writeInt(powerUpId, 9);
		} else {
			b.writeFlag(false);
		}
		if (netFlags & MarbleNetFlags.GravityChange > 0) {
			b.writeFlag(true);
			b.writeFloat(gravityDirection.x);
			b.writeFloat(gravityDirection.y);
			b.writeFloat(gravityDirection.z);
		} else {
			b.writeFlag(false);
		}
	}

	public inline function deserialize(b:InputBitStream) {
		clientId = b.readByte();
		move = MoveManager.unpackMove(b);
		serverTicks = b.readUInt16();
		moveQueueSize = b.readByte();
		position = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
		velocity = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
		omega = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
		lastContactNormal = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
		blastAmount = b.readInt(11);
		this.netFlags = 0;
		if (b.readFlag()) {
			blastTick = b.readUInt16();
			this.netFlags |= MarbleNetFlags.DoBlast;
		}
		if (b.readFlag()) {
			heliTick = b.readUInt16();
			this.netFlags |= MarbleNetFlags.DoHelicopter;
		}
		if (b.readFlag()) {
			megaTick = b.readUInt16();
			this.netFlags |= MarbleNetFlags.DoMega;
		}
		oob = b.readFlag();
		if (b.readFlag())
			this.netFlags |= MarbleNetFlags.UsePowerup;
		if (b.readFlag()) {
			powerUpId = b.readInt(9);
			this.netFlags |= MarbleNetFlags.PickupPowerup;
		}
		if (b.readFlag()) {
			gravityDirection = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
			this.netFlags |= MarbleNetFlags.GravityChange;
		}
	}
}

@:publicFields
class PowerupPickupPacket implements NetPacket {
	var clientId:Int;
	var serverTicks:Int;
	var powerupItemId:Int;

	public function new() {}

	public inline function deserialize(b:InputBitStream) {
		clientId = b.readByte();
		serverTicks = b.readUInt16();
		powerupItemId = b.readInt(10);
	}

	public inline function serialize(b:OutputBitStream) {
		b.writeByte(clientId);
		b.writeUInt16(serverTicks);
		b.writeInt(powerupItemId, 10);
	}
}

@:publicFields
class GemSpawnPacket implements NetPacket {
	var gemIds:Array<Int>;

	public function new() {
		gemIds = [];
	}

	public function serialize(b:OutputBitStream) {
		b.writeInt(gemIds.length, 5);
		for (gemId in gemIds) {
			b.writeInt(gemId, 11);
		}
	}

	public function deserialize(b:InputBitStream) {
		var count = b.readInt(5);
		for (i in 0...count) {
			gemIds.push(b.readInt(11));
		}
	}
}

@:publicFields
class GemPickupPacket implements NetPacket {
	var clientId:Int;
	var serverTicks:Int;
	var gemId:Int;
	var scoreIncr:Int;

	public function new() {}

	public inline function deserialize(b:InputBitStream) {
		clientId = b.readByte();
		serverTicks = b.readUInt16();
		gemId = b.readInt(11);
		scoreIncr = b.readInt(4);
	}

	public inline function serialize(b:OutputBitStream) {
		b.writeByte(clientId);
		b.writeUInt16(serverTicks);
		b.writeInt(gemId, 11);
		b.writeInt(scoreIncr, 4);
	}
}

@:publicFields
class ScoreboardPacket implements NetPacket {
	var scoreBoard:Map<Int, Int>;

	public function new() {
		scoreBoard = new Map();
	}

	public inline function deserialize(b:InputBitStream) {
		var count = b.readInt(4);
		for (i in 0...count) {
			scoreBoard[b.readInt(6)] = b.readInt(10);
		}
	}

	public inline function serialize(b:OutputBitStream) {
		var keycount = 0;
		for (k => v in scoreBoard)
			keycount++;
		b.writeInt(keycount, 4);
		for (key => v in scoreBoard) {
			b.writeInt(key, 6);
			b.writeInt(v, 10);
		}
	}
}
