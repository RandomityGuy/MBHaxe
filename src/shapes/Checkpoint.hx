package shapes;

import collision.CollisionInfo;
import mis.MisParser;
import src.DtsObject;
import src.ResourceLoader;
import src.ResourceLoaderWorker;
import src.AudioManager;
import mis.MissionElement.MissionElementStaticShape;

class Checkpoint extends DtsObject {
	public var disableOOB = false;

	var element:MissionElementStaticShape;
	var isPQ:Bool;

	public function new(element:MissionElementStaticShape) {
		super();
		var datablockLower = element.datablock.toLowerCase();
		this.isPQ = datablockLower == "checkpoint_pq";
		this.dtsPath = switch (datablockLower) {
			case "checkpoint_pq": "data/shapes_pq/gameplay/pads/checkpoint.dts";
			case "checkpoint_mbu": "data/shapes_mbu/pads/checkpad.dts";
			default: "data/shapes/buttons/checkpoint.dts";
		}
		this.isCollideable = true;
		this.isTSStatic = false;
		// Instancing batches by `identifier`, and the PQ variant uses a different mesh - keep the
		// dtsPath in the identifier so it doesn't get batched with the vanilla mesh.
		this.identifier = "Checkpoint" + this.dtsPath;
		this.element = element;

		this.disableOOB = element.fields.exists('disableOob') ? MisParser.parseBoolean(element.fields['disableOob'][0]) : false;
	}

	public override function init(level:src.MarbleWorld, onFinish:() -> Void) {
		super.init(level, () -> {
			var worker = new ResourceLoaderWorker(onFinish);
			AudioManager.preloadPitchedSound("checkpoint", worker);
			if (this.isPQ)
				worker.addTask(fwd -> this.spawnGlass(fwd));
			worker.run();
		});
	}

	/** Ported from `Checkpoint_PQ::onAdd` (`server/scripts/checkpoint.cs`) - `Checkpoint_PQ` (not
		the base MBG `checkPoint` datablock) spawns a purely decorative "silly glass" dome shape
		(`SillyGlass`, `className = ""` - no script behavior of its own) rigidly attached with zero
		offset/rotation change (`setParent(%obj, "0 0 0 1 0 0 0", true, "0 0 0")`) at the checkpoint's
		own position/rotation/scale. Ported as a genuine Heaps scene-graph child (`this.addChild`)
		instead of a separate top-level object kept in sync every frame (this port's usual approach
		for a *moving* rigid attachment, e.g. `shapes.CannonBase`) - a checkpoint never moves, so a
		real parent-child relationship, which inherits position/rotation/scale automatically and for
		free, is simpler and sufficient here. `useInstancing = false` so it goes through the plain
		`scene.addChild` path in `MarbleWorld.addDtsObject` (guaranteed real scene-graph parenting)
		rather than the GPU-instancing path, whose interaction with manual re-parenting afterward
		isn't established elsewhere in this port. */
	function spawnGlass(onFinish:Void->Void) {
		var glass = new DtsObject();
		glass.dtsPath = "data/shapes_pq/gameplay/pads/silly_cp_glass.dts";
		glass.identifier = "CheckpointSillyGlass";
		glass.isCollideable = false;
		glass.isBoundingBoxCollideable = false;
		glass.useInstancing = true;
		this.level.addDtsObject(glass, () -> {
			// Left at local identity position/rotation/scale (the `DtsObject` constructor's own
			// defaults) - being a child of `this` means Heaps composes the checkpoint's own
			// position/rotation/scale in automatically, matching the zero-offset/zero-rotation
			// parenting real source uses.
			this.addChild(glass);
			onFinish();
		});
	}

	public override function onMarbleContact(marble:src.Marble, time:src.TimeState, ?contact:CollisionInfo) {
		this.level.saveCheckpointState({
			obj: this,
			elem: this.element
		}, null);
	}
}
