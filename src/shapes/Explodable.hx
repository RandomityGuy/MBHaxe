package shapes;

import src.ParticleSystem.ParticleEmitter;
import src.Marble;
import h3d.Vector;
import src.ParticleSystem.ParticleEmitterOptions;
import net.BitStream.OutputBitStream;
import net.NetPacket.ExplodableUpdatePacket;
import collision.CollisionInfo;
import src.ParticleSystem.ParticleData;
import src.DtsObject;
import src.TimeState;
import src.Util;
import net.Net;
import src.MarbleWorld;
import src.ResourceLoader;
import src.AudioManager;

abstract class Explodable extends DtsObject {
	var particle:ParticleEmitterOptions;
	var smokeParticle:ParticleEmitterOptions;
	var sparksParticle:ParticleEmitterOptions;

	var particleData:ParticleData;
	var smokeParticleData:ParticleData;
	var sparkParticleData:ParticleData;

	var disappearTime = -1e8;
	var lastContactTick:Int = -100000;

	var renewTime = 5000;

	var explodeSoundFile:String = "data/sound/explode1.wav";

	var emitter1:ParticleEmitter;
	var emitter2:ParticleEmitter;
	var emitter3:ParticleEmitter;

	public var netId:Int;

	override function update(timeState:TimeState) {
		super.update(timeState);

		if (Net.isMP) {
			if (Net.isHost) {
				if (timeState.ticks >= this.lastContactTick + (renewTime >> 5) || timeState.ticks < this.lastContactTick) {
					this.setHide(false);
				} else {
					this.setHide(true);
				}

				var opacity = Util.clamp((timeState.ticks - (this.lastContactTick + (renewTime >> 5))), 0, 1);
				this.setOpacity(opacity);
			} else {
				if (@:privateAccess level.marble.serverTicks >= this.lastContactTick + (renewTime >> 5) || @:privateAccess level.marble.serverTicks < this.lastContactTick) {
					this.setHide(false);
				} else {
					this.setHide(true);
				}

				var opacity = Util.clamp((@:privateAccess level.marble.serverTicks - (this.lastContactTick + (renewTime >> 5))), 0, 1);
				this.setOpacity(opacity);
			}
		} else {
			if (timeState.timeSinceLoad >= this.disappearTime + (renewTime / 1000) || timeState.timeSinceLoad < this.disappearTime) {
				this.setHide(false);
			} else {
				this.setHide(true);
			}

			var opacity = Util.clamp((timeState.timeSinceLoad - (this.disappearTime + (renewTime / 1000))), 0, 1);
			this.setOpacity(opacity);
		}
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			ResourceLoader.load(explodeSoundFile).entry.load(onFinish);
		});
	}

	/** Ported from `Explosion::explode`/`Explosion::onAdd` (`game/fx/explosion.cc`) - real source's
		`LandMineExplosion`/`NukeExplosion` both spawn their `emitter[0]/emitter[1]` (smoke+spark)
		point burst at the exact explosion center, *plus* two more identical bursts via their
		`subExplosion[0]/[1]` entries (`LandMineSubExplosion1/2`, `NukeSubBlow1/2` - both use
		`offset = 1.0` same as `CannonSubExplosion1/2`), each nudged to a random point within 1 unit
		of center (`randVec.set(rand(-1,1), rand(0,1), rand(-1,1)).normalize() * offset`, simplified
		here to a plain world-space offset - see `shapes.Cannon.spawnExplosionBurst`'s doc comment
		for the same simplification applied there). `emitter1`/`emitter2`/`emitter3` only track the
		*last* burst spawned (matching the pre-existing single-burst behavior enough for
		`revertContactTicks`'s rewind cleanup - the extra scattered bursts are short-lived one-shots
		that finish and get garbage-collected on their own regardless). */
	function spawnExplosionBurst(pos:Vector) {
		emitter2 = this.level.particleManager.createEmitter(smokeParticle, smokeParticleData, pos);
		emitter3 = this.level.particleManager.createEmitter(sparksParticle, sparkParticleData, pos);
	}

	public inline function playExplosion() {
		if (!this.level.rewinding && !Net.isClient)
			AudioManager.playSound(ResourceLoader.getResource(explodeSoundFile, ResourceLoader.getAudio, this.soundResources));

		var pos = this.getAbsPos().getPosition();
		emitter1 = this.level.particleManager.createEmitter(particle, particleData, pos);
		this.spawnExplosionBurst(pos);
		for (i in 0...2) {
			var randVec = new Vector(Math.random() * 2 - 1, Math.random(), Math.random() * 2 - 1);
			if (randVec.lengthSq() > 0.0001)
				randVec.normalize();
			this.spawnExplosionBurst(pos.add(randVec));
		}
	}

	override function onMarbleContact(marble:src.Marble, timeState:TimeState, ?contact:CollisionInfo) {
		if (this.isCollideable && !this.level.rewinding) {
			// marble.velocity = marble.velocity.add(vec);
			this.disappearTime = timeState.timeSinceLoad;
			if (Net.isClient) {
				this.lastContactTick = @:privateAccess marble.serverTicks;
			} else {
				this.lastContactTick = timeState.ticks;
			}
			this.setCollisionEnabled(false);

			if (!this.level.rewinding && @:privateAccess !marble.isNetUpdate && !Net.isClient)
				AudioManager.playSound(ResourceLoader.getResource(explodeSoundFile, ResourceLoader.getAudio, this.soundResources));
			if (@:privateAccess !marble.isNetUpdate) {
				var pos = this.getAbsPos().getPosition();
				emitter1 = this.level.particleManager.createEmitter(particle, particleData, pos);
				this.spawnExplosionBurst(pos);
				for (i in 0...2) {
					var randVec = new Vector(Math.random() * 2 - 1, Math.random(), Math.random() * 2 - 1);
					if (randVec.lengthSq() > 0.0001)
						randVec.normalize();
					this.spawnExplosionBurst(pos.add(randVec));
				}
			}

			if (Net.isClient) {
				if (!level.explodablesToTick.contains(netId))
					level.explodablesToTick.push(netId);
			}

			// var minePos = this.getAbsPos().getPosition();
			// var off = marble.getAbsPos().getPosition().sub(minePos);

			// var strength = computeExplosionStrength(off.length());

			// var impulse = off.normalized().multiply(strength);
			applyImpulse(marble);

			if (Net.isHost) {
				var packet = new ExplodableUpdatePacket();
				packet.explodableId = netId;
				packet.serverTicks = timeState.ticks;
				var os = new OutputBitStream();
				os.writeByte(ExplodableUpdate);
				packet.serialize(os);
				Net.sendPacketToIngame(os);
			}

			// light = new h3d.scene.fwd.PointLight(MarbleGame.instance.scene);
			// light.setPosition(minePos.x, minePos.y, minePos.z);
			// light.enableSpecular = false;

			// for (collider in this.colliders) {
			// 	var hull:CollisionHull = cast collider;
			// 	hull.force = strength;
			// }
		}
		// Normally, we would add a light here, but that's too expensive for THREE, apparently.

		// this.level.replay.recordMarbleContact(this);
	}

	public function revertContactTicks(ticks:Int) {
		this.lastContactTick = ticks;
		if (level.timeState.ticks >= this.lastContactTick + (renewTime >> 5) || level.timeState.ticks < this.lastContactTick) {
			if (emitter1 != null) {
				this.level.particleManager.removeEmitterWithParticles(emitter1);
				emitter1 = null;
			}

			if (emitter2 != null) {
				this.level.particleManager.removeEmitterWithParticles(emitter2);
				emitter2 = null;
			}

			if (emitter3 != null) {
				this.level.particleManager.removeEmitterWithParticles(emitter3);
				emitter3 = null;
			}
		}
	}

	abstract function applyImpulse(marble:Marble):Void;
}
