package shapes;

import src.DtsObject;
import src.TimeState;
import src.MarbleWorld;
import src.Marble;
import src.Util;
import collision.CollisionInfo;
import mis.MissionElement.MissionElementStaticShape;

class MegaManPlatform extends DtsObject {
	static inline final FADE_S = 0.5; // $VV::MegaManFadeInOut
	static inline final IDLE_S = 1.5; // $VV::MegaManTimer
	static inline final FADE_OUT_START = FADE_S + IDLE_S; // 2s - fade-out begins
	static inline final HIDE_TIME = FADE_OUT_START + FADE_S; // 2.5s - fully hidden/non-collideable
	static inline final NEXT_DELAY = IDLE_S; // 1.5s - when the chain shows the next platform

	var nextName:String;
	var next:MegaManPlatform;

	public var respondToCollision:Bool = false;
	public var hasCollided:Bool = false;

	var showTime:Float = -1e8;
	var queuedNext:Bool = false;

	public function new(element:MissionElementStaticShape) {
		super();
		var datablockLower = element.datablock.toLowerCase();
		this.dtsPath = switch (datablockLower) {
			case "megamanplatform2_1x1": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x1.dts";
			case "megamanplatform2_1x2": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x2.dts";
			case "megamanplatform2_1x3": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x3.dts";
			case "megamanplatform2_1x5": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x5.dts";
			case "megamanplatform2_2x2": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_2x2.dts";
			case "megamanplatform2_3x3": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_3x3.dts";
			case "megamanplatform2_5x5": "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_5x5.dts";
			default: "data/shapes_pq/gameplay/hazards/FadePlatform/FadePlatform2_1x1.dts";
		}
		this.isCollideable = true;
		this.enableCollideCallbacks = true;
		// `MegaManPlatform::onAdd`'s `setSkinName("skin2")` ("pink skin").
		this.skinOverride = "skin2";
		this.identifier = "MegaManPlatform" + this.dtsPath;
		this.useInstancing = true;

		var nextField = element.fields.get("next");
		this.nextName = nextField != null ? nextField[0] : null;
	}

	public override function init(level:MarbleWorld, onFinish:Void->Void) {
		super.init(level, () -> {
			this.setHide(true);
			onFinish();
		});
	}

	function resolveNext():MegaManPlatform {
		if (this.next == null && this.nextName != null) {
			var obj = this.level.namedGameObjects.get(this.nextName.toLowerCase());
			if (obj != null && obj is MegaManPlatform)
				this.next = cast obj;
		}
		return this.next;
	}

	public function show(timeState:TimeState) {
		this.showTime = timeState.currentAttemptTime;
		this.queuedNext = false;
	}

	public override function onMarbleContact(marble:Marble, timeState:TimeState, ?contact:CollisionInfo) {
		super.onMarbleContact(marble, timeState, contact);
		var hasNext = resolveNext() != null;
		if (hasNext && (!this.respondToCollision || this.hasCollided))
			return;
		this.hasCollided = true;
		this.showTime = timeState.currentAttemptTime - FADE_S;
	}

	public override function update(timeState:TimeState) {
		super.update(timeState);
		if (this.showTime <= -1e7) {
			this.setCollisionEnabled(false);
			this.setOpacity(0);
			return;
		}

		var elapsed = timeState.currentAttemptTime - this.showTime;
		if (!this.queuedNext && elapsed >= NEXT_DELAY) {
			this.queuedNext = true;
			var n = resolveNext();
			if (n != null)
				n.show(timeState);
		}

		if (elapsed < FADE_S) {
			this.setCollisionEnabled(true);
			this.setOpacity(Util.clamp(elapsed / FADE_S, 0, 1));
		} else if (elapsed < FADE_OUT_START) {
			this.setCollisionEnabled(true);
			this.setOpacity(1);
		} else if (elapsed < HIDE_TIME) {
			this.setCollisionEnabled(true);
			this.setOpacity(1 - Util.clamp((elapsed - FADE_OUT_START) / FADE_S, 0, 1));
		} else {
			this.setCollisionEnabled(false);
			this.setOpacity(0);
		}
	}

	public override function reset() {
		super.reset();
		this.showTime = -1e8;
		this.hasCollided = false;
		this.queuedNext = false;
	}
}
