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

/** Delegates every `GameMode` hook to a fixed set of child modes - a mission's `gameMode` field is
	a space-separated list of *independently active* modes (e.g. `"Hunt Laps"`, confirmed against
	PQ's `shared/mission.cs::resolveMissionGameModes`), not a single mode. Void hooks (scoring
	side-effects, HUD updates, etc.) run on every child. `canFinish` is a plain AND across children
	("Quota Haste" needs the quota met AND the speed requirement met); the position/time/score hooks
	aren't realistically ever overridden by more than one mode in the same mission at once, so the
	last child in the list wins (mission authors list their "primary" mode last). */
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
		return this.children[this.children.length - 1].getRespawnTransform(marble);
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

	public function getFinishScore():Float {
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
			m.onGemPickup(marble, gem);
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

	/** Every child still runs (for side effects), but if any child takes over, the default OOB
		flow is suppressed. */
	public function onOutOfBounds(marble:Marble):Bool {
		var handled = false;
		for (m in this.children)
			if (m.onOutOfBounds(marble))
				handled = true;
		return handled;
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
}
