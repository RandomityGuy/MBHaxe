package triggers;

import mis.MissionElement.MissionElementSimGroup;
import shapes.Checkpoint;
import h3d.Vector;
import src.MarbleWorld;
import mis.MissionElement.MissionElementTrigger;
import src.ResourceLoader;
import mis.MisParser;

class CheckpointTrigger extends Trigger {
	public var disableOOB = false;
	public var add:Vector = null;
	public var simGroup:MissionElementSimGroup;
	public var seqNum:Int;

	override public function new(element:MissionElementTrigger, level:MarbleWorld) {
		super(element, level);

		this.disableOOB = element.fields.exists('disableOob') ? MisParser.parseBoolean(element.fields['disableOob'][0]) : false;
		this.add = element.fields.exists('add') ? MisParser.parseVector3(element.fields['add'][0]) : null;
		this.seqNum = element.fields.exists('sequence') ? Std.parseInt(element.sequence) : 1;
	}

	public override function init(onFinish:() -> Void) {
		super.init(() -> {
			ResourceLoader.load("sound/checkpoint.wav").entry.load(onFinish);
		});
	}

	public override function onMarbleEnter(time:src.TimeState) {
		super.onMarbleEnter(time);
		if (simGroup == null)
			return;
		var shape = level.simGroups[simGroup].filter(x -> x.identifier == "Checkpoint");
		if (shape.length == 0)
			return;
		var chk:Checkpoint = cast shape[0];
		var prevChk = @:privateAccess this.level.currentCheckpoint;
		var issame = prevChk == chk;
		if (this.level.saveCheckpointState(chk, this)) {
			if (!issame) {
				chk.lastActivatedTime = time.timeSinceLoad;
				for (obj in this.level.dtsObjects) {
					if (obj.identifier == "Checkpoint" && obj != chk)
						cast(obj, Checkpoint).lastActivatedTime = Math.POSITIVE_INFINITY;
				}
			}
		}
	}
}
