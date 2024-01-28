package net;

import h3d.Vector;
import net.MoveManager.NetMove;

interface NetPacket {
	public function serialize(b:haxe.io.BytesOutput):Void;
	public function deserialize(b:haxe.io.BytesInput):Void;
}

@:publicFields
class MarbleMovePacket implements NetPacket {
	var clientId:Int;
	var clientTicks:Int;
	var move:NetMove;

	public function new() {}

	public inline function deserialize(b:haxe.io.BytesInput) {
		clientId = b.readUInt16();
		clientTicks = b.readUInt16();
		move = MoveManager.unpackMove(b);
	}

	public inline function serialize(b:haxe.io.BytesOutput) {
		b.writeUInt16(clientId);
		b.writeUInt16(clientTicks);
		MoveManager.packMove(move, b);
	}
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
	var collisionToken:Int;

	public function new() {}

	public inline function serialize(b:haxe.io.BytesOutput) {
		b.writeUInt16(clientId);
		MoveManager.packMove(move, b);
		b.writeUInt16(serverTicks);
		b.writeUInt16(collisionToken);
		b.writeFloat(position.x);
		b.writeFloat(position.y);
		b.writeFloat(position.z);
		b.writeFloat(velocity.x);
		b.writeFloat(velocity.y);
		b.writeFloat(velocity.z);
		b.writeFloat(omega.x);
		b.writeFloat(omega.y);
		b.writeFloat(omega.z);
	}

	public inline function deserialize(b:haxe.io.BytesInput) {
		clientId = b.readUInt16();
		move = MoveManager.unpackMove(b);
		serverTicks = b.readUInt16();
		collisionToken = b.readUInt16();
		position = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
		velocity = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
		omega = new Vector(b.readFloat(), b.readFloat(), b.readFloat());
	}
}
