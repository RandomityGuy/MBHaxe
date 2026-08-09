package modes;

import src.TimeState;
import src.Marble;
import shapes.Gem;
import h3d.Quat;
import h3d.Vector;
import src.MarbleWorld;
import src.Mission;
import modes.GameMode.ScoreType;
import rewind.RewindableState;
import rewind.RewindManager;
import net.Move;
import collision.CollisionInfo;

@:publicFields
class CompositeRewindState implements RewindableState {
	var states:Array<RewindableState>;

	public function new(states:Array<RewindableState>) {
		this.states = states;
	}

	public function clone():RewindableState {
		return new CompositeRewindState(states.map(s -> s != null ? s.clone() : null));
	}

	public function getSize():Int {
		var size = 2; // states.length
		for (s in states) {
			size += 1; // has-state byte
			if (s != null)
				size += s.getSize();
		}
		return size;
	}

	public function serialize(rm:RewindManager, bw:haxe.io.BytesOutput) {
		bw.writeInt16(states.length);
		for (s in states) {
			bw.writeByte(s == null ? 0 : 1);
			if (s != null)
				s.serialize(rm, bw);
		}
	}

	public function deserialize(rm:RewindManager, br:haxe.io.BytesInput) {
		var len = br.readInt16();
		for (i in 0...len) {
			var hasState = br.readByte() != 0;
			if (hasState && states[i] != null)
				states[i].deserialize(rm, br);
		}
	}
}

class CompositeMode implements GameMode {
	var level:MarbleWorld;

	public var children:Array<GameMode>;

	public function new(level:MarbleWorld, children:Array<GameMode>) {
		this.level = level;
		this.children = children;
	}

	public function getSpawnTransform():{position:Vector, orientation:Quat, up:Vector} {
		return this.children[this.children.length - 1].getSpawnTransform();
	}

	public function getRespawnTransform(marble:Marble):{position:Vector, orientation:Quat, up:Vector} {
		for (i in 0...this.children.length) {
			var resp = this.children[this.children.length - i - 1].getRespawnTransform(marble);
			if (resp != null)
				return resp;
		}
		return null;
	}

	public function missionScan(mission:Mission) {
		for (m in this.children)
			m.missionScan(mission);
	}

	public function onMissionLoad() {
		for (m in this.children)
			m.onMissionLoad();
	}

	public function getStartTime():Float {
		return this.children[this.children.length - 1].getStartTime();
	}

	public function timeMultiplier():Float {
		return this.children[this.children.length - 1].timeMultiplier();
	}

	public function getScoreType():ScoreType {
		return this.children[this.children.length - 1].getScoreType();
	}

	public function getFinishScore():{score:Float, type:ScoreType} {
		return this.children[this.children.length - 1].getFinishScore();
	}

	public function onTimeExpire() {
		for (m in this.children)
			m.onTimeExpire();
	}

	public function onRestart() {
		for (m in this.children)
			m.onRestart();
	}

	public function onClientRestart() {
		for (m in this.children)
			m.onClientRestart();
	}

	public function onRespawn(marble:Marble) {
		for (m in this.children)
			m.onRespawn(marble);
	}

	public function onGemPickup(marble:Marble, gem:Gem) {
		for (m in this.children)
			if (m.onGemPickup(marble, gem))
				return true;
		return false;
	}

	public function update(t:TimeState) {
		for (m in this.children)
			m.update(t);
	}

	public function getPreloadFiles():Array<String> {
		var files = [];
		for (m in this.children)
			for (f in m.getPreloadFiles())
				if (!files.contains(f))
					files.push(f);
		return files;
	}

	public function canFinish(marble:Marble):Bool {
		for (m in this.children)
			if (!m.canFinish(marble))
				return false;
		return true;
	}

	public function getFinishMessage(marble:Marble):String {
		for (m in this.children)
			if (!m.canFinish(marble))
				return m.getFinishMessage(marble);
		return "";
	}

	public function onOutOfBounds(marble:Marble):Bool {
		var handled = false;
		for (m in this.children)
			if (m.onOutOfBounds(marble))
				handled = true;
		return handled;
	}

	public function processMaterialContact(marble:Marble, contact:CollisionInfo) {
		for (m in this.children)
			m.processMaterialContact(marble, contact);
	}

	public function onJump(marble:Marble) {
		for (m in this.children)
			m.onJump(marble);
	}

	public function getRewindState():RewindableState {
		var states = [for (m in this.children) m.getRewindState()];
		if (states.filter(s -> s != null).length == 0)
			return null;
		return new CompositeRewindState(states);
	}

	public function applyRewindState(state:RewindableState) {
		var cs:CompositeRewindState = cast state;
		for (i in 0...this.children.length)
			if (cs.states[i] != null)
				this.children[i].applyRewindState(cs.states[i]);
	}

	public function constructRewindState():RewindableState {
		return new CompositeRewindState([for (m in this.children) m.constructRewindState()]);
	}

	public function processMove(marble:Marble, move:Move) {
		for (m in this.children)
			m.processMove(marble, move);
	}

	public function saveReplayData(bw:haxe.io.BytesOutput) {
		for (m in this.children)
			m.saveReplayData(bw);
	}

	public function loadReplayData(br:haxe.io.BytesInput) {
		for (m in this.children)
			m.loadReplayData(br);
	}
}
