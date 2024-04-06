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
	var move:NetMove;

	public function new() {}

	public inline function deserialize(b:InputBitStream) {
		clientId = b.readByte();
		clientTicks = b.readUInt16();
		move = MoveManager.unpackMove(b);
	}

	public inline function serialize(b:OutputBitStream) {
		b.writeByte(clientId);
		b.writeUInt16(clientTicks);
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
		powerupItemId = b.readInt(9);
	}

	public inline function serialize(b:OutputBitStream) {
		b.writeByte(clientId);
		b.writeUInt16(serverTicks);
		b.writeInt(powerupItemId, 9);
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
			b.writeInt(gemId, 10);
		}
	}

	public function deserialize(b:InputBitStream) {
		var count = b.readInt(5);
		for (i in 0...count) {
			gemIds.push(b.readInt(10));
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
		gemId = b.readInt(10);
		scoreIncr = b.readInt(4);
	}

	public inline function serialize(b:OutputBitStream) {
		b.writeByte(clientId);
		b.writeUInt16(serverTicks);
		b.writeInt(gemId, 10);
		b.writeInt(scoreIncr, 4);
	}
}
