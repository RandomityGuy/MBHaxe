package modes;

import h3d.Vector;
import rewind.RewindableState;
import rewind.RewindManager;
import triggers.ILapsRespawnTrigger;

@:publicFields
class LapsState implements RewindableState {
	var lapsCounter:Int;
	var lapsCPCheck:Int;
	var lapsHitLastCP:Bool;
	var lapsStartTime:Float;
	var checkpointLapsCounter:Int;
	var checkpointLapsCPCheck:Int;
	var checkpointLapsHitLastCP:Bool;
	var checkpointLapsStartTime:Float;
	var lapsCheckpoint:ILapsRespawnTrigger;
	var lapsPosition:Vector;
	var lapsCameraYaw:Float;
	var lapsUp:Vector;

	public function new() {}

	public function clone():RewindableState {
		var c = new LapsState();
		c.lapsCounter = lapsCounter;
		c.lapsCPCheck = lapsCPCheck;
		c.lapsHitLastCP = lapsHitLastCP;
		c.lapsStartTime = lapsStartTime;
		c.checkpointLapsCounter = checkpointLapsCounter;
		c.checkpointLapsCPCheck = checkpointLapsCPCheck;
		c.checkpointLapsHitLastCP = checkpointLapsHitLastCP;
		c.checkpointLapsStartTime = checkpointLapsStartTime;
		c.lapsCheckpoint = lapsCheckpoint;
		c.lapsPosition = lapsPosition != null ? lapsPosition.clone() : null;
		c.lapsCameraYaw = lapsCameraYaw;
		c.lapsUp = lapsUp != null ? lapsUp.clone() : null;
		return c;
	}

	public function getSize():Int {
		var size = 2 + 2 + 1 + 8; // lapsCounter, lapsCPCheck, lapsHitLastCP, lapsStartTime
		size += 2 + 2 + 1 + 8; // checkpointLaps*
		size += 2; // lapsCheckpoint id
		size += 1; // Null<lapsPosition>
		if (lapsPosition != null)
			size += 24;
		size += 8; // lapsCameraYaw
		size += 1; // Null<lapsUp>
		if (lapsUp != null)
			size += 24;
		return size;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeInt16(lapsCounter);
		bw.writeInt16(lapsCPCheck);
		bw.writeByte(lapsHitLastCP ? 1 : 0);
		bw.writeDouble(lapsStartTime);
		bw.writeInt16(checkpointLapsCounter);
		bw.writeInt16(checkpointLapsCPCheck);
		bw.writeByte(checkpointLapsHitLastCP ? 1 : 0);
		bw.writeDouble(checkpointLapsStartTime);
		bw.writeInt16(rm.allocGO(lapsCheckpoint != null ? cast lapsCheckpoint : null));
		bw.writeByte(lapsPosition == null ? 0 : 1);
		if (lapsPosition != null) {
			bw.writeDouble(lapsPosition.x);
			bw.writeDouble(lapsPosition.y);
			bw.writeDouble(lapsPosition.z);
		}
		bw.writeDouble(lapsCameraYaw);
		bw.writeByte(lapsUp == null ? 0 : 1);
		if (lapsUp != null) {
			bw.writeDouble(lapsUp.x);
			bw.writeDouble(lapsUp.y);
			bw.writeDouble(lapsUp.z);
		}
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		lapsCounter = br.readInt16();
		lapsCPCheck = br.readInt16();
		lapsHitLastCP = br.readByte() != 0;
		lapsStartTime = br.readDouble();
		checkpointLapsCounter = br.readInt16();
		checkpointLapsCPCheck = br.readInt16();
		checkpointLapsHitLastCP = br.readByte() != 0;
		checkpointLapsStartTime = br.readDouble();
		var go = rm.getGO(br.readInt16());
		lapsCheckpoint = go != null ? cast(go, ILapsRespawnTrigger) : null;
		if (br.readByte() != 0) {
			lapsPosition = new Vector();
			lapsPosition.x = br.readDouble();
			lapsPosition.y = br.readDouble();
			lapsPosition.z = br.readDouble();
		} else {
			lapsPosition = null;
		}
		lapsCameraYaw = br.readDouble();
		if (br.readByte() != 0) {
			lapsUp = new Vector();
			lapsUp.x = br.readDouble();
			lapsUp.y = br.readDouble();
			lapsUp.z = br.readDouble();
		} else {
			lapsUp = null;
		}
	}
}
