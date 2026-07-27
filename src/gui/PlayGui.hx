package gui;

import h2d.Flow.FlowOverflow;
import hxsl.Types.Vec;
import net.NetPacket.ScoreboardPacket;
import net.Net;
import src.ProfilerUI;
import hxd.App;
import hxd.res.Image;
import hxd.Window;
import h3d.shader.AlphaMult;
import h3d.shader.ColorKey;
import hxd.snd.WavData;
import gui.GuiControl.HorizSizing;
import src.TimeState;
import format.gif.Data.Block;
import hxd.res.BitmapFont;
import h2d.Text;
import h3d.Vector;
import hxd.fmt.hmd.Data.AnimationEvent;
import h2d.Tile;
import h3d.mat.DepthBuffer;
import h3d.mat.Texture;
import h3d.mat.Material;
import h3d.scene.Mesh;
import h3d.prim.Cube;
import src.DtsObject;
import h2d.Anim;
import h2d.Bitmap;
import src.ResourceLoader;
import src.MarbleGame;
import src.Resource;
import hxd.res.Sound;
import h3d.mat.Texture;
import src.Settings;
import src.Util;
import src.AudioManager;

@:publicFields
@:structInit
class MiddleMessage {
	var ctrl:GuiText;
	var age:Float;
}

/** One active "toast" notification - ported from `chathud.cs`'s `createHelpMessage`/
	`addHelpLine`/`updateMessages`/`shiftMessages` (`PG_MessageListBox`'s stack of sliding
	messages), built from the SAME `GuiControl`/`GuiBitmapBorderCtrl`/`GuiMLText` system (and the
	same field values - position/extent/horizSizing/vertSizing - as the real `.gui`/script) every
	other `PlayGui` element already uses, rather than raw `h2d` objects with hand-derived pixel
	math - `GuiControl`'s `horizSizing`/`vertSizing` handling is already a correct, tested port of
	Torque's own anchor semantics, so building the exact same control tree with the exact same
	field values sidesteps needing to re-derive any of that math by hand. This is what this port's
	own `alertTextForeground`/`setAlertText`/`displayAlert` naming was always *meant* to represent
	(pickup/status notifications) - that was previously just a single-message fade placeholder, now
	fully replaced. NOT the same system as `PlayGui.helpTextForeground`/`setHelpText` (that's
	`addBubbleLine`'s separate persistent help-bubble machinery, for mission help-trigger text). */
class ToastMessage {
	/** Matches `createHelpMessage`'s own `%width = min(getWord(PG_ChatBubbleBox.position, 0) + 20,
		400)` - `PG_ChatBubbleBox.position`'s x is itself a fixed constant (80) in `playGui.gui`, so
		this always evaluates to a fixed 100 regardless of anything runtime-computed. */
	public static inline var WIDTH = 400.0;

	/** Default box height before the post-reflow resize (`createHelpMessage`'s own initial
		`extent = %width SPC "70"`). */
	public static inline var DEFAULT_HEIGHT = 70.0;

	/** `$ChatHudMessageXSpeed[1]`/`[-1]`/`$ChatHudMessageYSpeed`, reference-canvas px/sec. */
	public static inline var X_SPEED_IN = 900.0;

	public static inline var X_SPEED_OUT = 600.0;
	public static inline var Y_SPEED = 250.0;

	/** Matches `shiftMessages`'s own `+ 24`. */
	public static inline var SPACING = 0.0;

	public var box:GuiControl;
	public var border:GuiBitmapBorderCtrl;
	public var fg:GuiMLText;
	public var x:Float;
	public var y:Float;
	public var targetX:Float;
	public var targetY:Float;
	public var direction:Int;

	/** The full vertical space this message occupies in the stack (box height + `SPACING`) -
		matches `shiftMessages(getWord(%foregroundName.getExtent(), 1) + 24)`. */
	public var height:Float;

	public var age:Float = 0;
	public var timeout:Float;
	public var retreating:Bool = false;

	public function new() {}
}

@:publicFields
@:structInit
class PlayerInfo {
	var id:Int;
	var name:String;
	var us:Bool;
	var score:Int;
	var r:Int;
	var y:Int;
	var b:Int;
	var p:Int;
}

class PlayGui {
	var scene2d:h2d.Scene;

	public function new() {}

	public static final timerNormal:Int = 0xFFFFFFFF;
	public static final timerStopped:Int = 0xFF99FF99;
	public static final timerDanger:Int = 0xFFFF9999;

	var timerNumbers:Array<GuiAnim> = [];
	var timerPoint:GuiAnim;
	var timerColon:GuiAnim;

	var countdownNumbers:Array<GuiAnim> = [];
	var countdownPoint:GuiAnim;
	var countdownIcon:GuiImage;

	var gemCountNumbers:Array<GuiAnim> = [];
	var gemCountSlash:GuiImage;
	var gemImageScene:h3d.scene.Scene;
	var gemImageSceneTarget:Texture;
	var gemImageObject:DtsObject;
	var gemImageSceneTargetBitmap:Bitmap;

	/** Ported from PQ's `GemsQuota` control (`client/ui/playGui.gui`) - a small "/trueTotal" suffix
		shown beside the main gem counter while `QuotaMode` is active (whose own main counter shows
		`collected/quota` instead of `collected/totalGems`), so the level's real 100%-completion
		total is still visible. No rainbow/green "100%" visual effect - out of scope per instruction. */
	var gemsQuota:GuiText;

	/** Ported from PQ's `PGLapsCounter` (`client/ui/playGui.gui`) - shown while `LapsMode` is
		active. Uses the same bitmap-digit-strip + `anim.color` tint convention as `gemCountNumbers`/
		the speedometer digits (PQ's own `PGLapsOneComplete`/`PGLapsOneTotal` are `GuiBitmapCtrl`s
		using `./game/numbers/N`, not a text control - unlike `GemsQuota`, which really is a
		`GuiMLTextCtrl` in the source). */
	var lapsCounterCtrl:GuiControl;

	var lapsCounterTransparency:GuiImage;
	var lapsCounterLabel:GuiImage;
	var lapsCounterDigitComplete:GuiAnim;
	var lapsCounterDigitTotal:GuiAnim;
	var lapsCounterSlash:GuiImage;

	/** Ported from PQ's `PGCountdownThTimer` (`client/ui/playGui.gui`, thousandths-precision
		variant - `client/scripts/playGui.cs`'s `updateCountdown`) - `CountdownStartTrigger`/
		`CountdownStopTrigger`'s dedicated HUD element. Explicitly NOT the same counter as
		`countdownNumbers`/`formatCountdownTimer` (that one's `PG_HuntCounter`'s Hunt-mode gem-respawn
		countdown, MP-only, and empty/uninitialized in SP) - the two are unrelated PQ controls that
		happen to look similar. Same on-screen position as `PGLapsCounter` in the source, but the two
		are never shown at once (Laps vs. a `CountdownStartTrigger`-using mission). */
	var countdownThCtrl:GuiControl;

	var countdownThImage:GuiImage;
	var countdownThNumbers:Array<GuiAnim> = [];
	var countdownThColon:GuiAnim;
	var countdownThPoint:GuiAnim;

	/** Ported from PQ's analog speedometer (`client/scripts/speedometer.cs`,
		`client/ui/playGui.gui`'s `PGSpeedometer` control tree) - shown while `ConsistencyMode`
		and/or `HasteMode` are active. 3 stacked copies of the same scrolling tape texture
		(`spdbackground1/2/3.png`, each taller than the visible border) are repositioned every frame
		so whichever copy currently overlaps the border's visible window shows the right tick marks
		under the fixed arrow - the border `GuiControl`'s `h2d.Flow` clips everything outside its own
		extent automatically (Heaps' `overflow = Hidden`), no manual clip mask needed. Repositioning
		happens on the bare `.bmp`/`.anim` objects directly every frame (not `GuiControl.position` +
		`.render()`, which is only for initial layout) since this needs to run every tick. */
	var speedometerCtrl:GuiControl;

	var speedometerBorder:GuiControl;
	var speedometerBackground1:GuiImage;
	var speedometerBackground2:GuiImage;
	var speedometerBackground3:GuiImage;
	var speedometerArrow:GuiImage;
	var speedometerConsMarker:GuiImage;
	var speedometerHasteMarker:GuiImage;
	var speedometerConsNormalTile:Tile;
	var speedometerConsTooSlowTile:Tile;
	var speedometerHasteAchievedTile:Tile;
	var speedometerHasteNotAchievedTile:Tile;
	var speedometerDigitHun:GuiAnim;
	var speedometerDigitTen:GuiAnim;
	var speedometerDigitOne:GuiAnim;

	// Rest (velocity = 0, "not hundreds") bare-element positions, captured once after the initial
	// `render()` - every subsequent frame just adds a `Settings.uiScale`-multiplied delta on top of
	// these, matching how `getRenderRectangle()` scales `position` by `uiScaleFactor` at setup time.
	var speedometerRestCaptured:Bool = false;
	var speedometerBackground1RestY:Float = 0;
	var speedometerMarkerRestY:Float = 0;
	var speedometerDigitOneRestX:Float = 0;
	var speedometerDigitTenRestX:Float = 0;

	/** `MissionInfo.MinimumSpeed`/`MissionInfo.SpeedToQualify` - `0` means "that mode isn't active",
		matching PQ's own truthy-check convention (`MissionInfo.MinimumSpeed && ...`). Set once by
		`ConsistencyMode`/`HasteMode`'s constructors; read every frame by `updateSpeedometer` so the
		speedometer/digit-coloring/marker logic is computed once per frame regardless of how many of
		the two modes are simultaneously active (avoids each mode's own `update()` stomping on the
		other's marker if both ran the full speedometer update independently). */
	var speedometerMinimumSpeed:Float = 0;

	var speedometerSpeedToQualify:Float = 0;

	/** Ported from PQ's `UnderwaterOL` (`client/ui/playGui.gui`) - a full-screen overlay shown while
		the *camera* (not necessarily the marble) is inside a water trigger (`performWaterOverlay`,
		`client/scripts/water.cs`). Added directly to `scene2d` rather than through `GuiControl`
		(matching `RSGOCenterText`/`gemImageSceneTargetBitmap`'s existing raw-bitmap convention),
		since it's just a fixed full-screen quad with no layout needs. */
	var underwaterOverlay:Bitmap;

	/** Ported from PQ's `PG_BubbleContainer` (`client/ui/playGui.gui`) - the Bubble PowerUp's
		remaining-time bar. Ported from `PlayGui::updatePowerupTimerPos` (`client/scripts/
		playGui.cs`) - unlike every other HUD element in this file, this one isn't at a fixed
		reference-canvas position at all: it tracks the marble's *projected screen position* every
		frame (`getGuiSpace`/`getPixelSpace` off a point offset to the marble's side by its collision
		radius), so it's built from raw `h2d` objects added directly to `scene2d` (matching
		`RSGOCenterText`/marble radar nametags' existing raw-object convention) rather than
		`GuiControl`, which only knows how to lay out a fixed reference-canvas position. Uses this
		codebase's existing `blastFill`-style direct-stretch technique (`bubbleBarFillBmp.width`
		scaled by remaining-time fraction) for the "shrinking bar" effect. */
	var bubbleBarFillBmp:Bitmap;

	var bubbleBarFillFlow:h2d.Flow;

	var bubbleBarMeterBmp:Bitmap;
	var bubbleBarText:h2d.Text;
	var bubbleBarNormalTile:Tile;
	var bubbleBarInfiniteTile:Tile;

	/** Ported from PQ's `PG_FireballContainer` - same raw-`h2d`-object/marble-tracking convention as
		the Bubble bar above (`PlayGui::updateFireballBar`/`updateBarPositions`). The meter image
		itself swaps between "lit"/"unlit" tiles depending on whether a blast is currently off
		cooldown (`Marble.canFireballBlast`). */
	var fireballBarFillBmp:Bitmap;

	var fireballBarFillFlow:h2d.Flow;
	var fireballBarMeterBmp:Bitmap;
	var fireballBarText:h2d.Text;
	var fireballBarLitTile:Tile;
	var fireballBarUnlitTile:Tile;

	/** Cannon HUD (`client/scripts/cannon.cs`'s `updateCannonUI`) - only the `!showAim` half (a
		colored reticle plus a 4-quadrant charge gauge); the aim-assist trajectory rings
		(`showAim`/`aimSize`/`aimTriggers`) are a separate, not-yet-ported feature, per direct
		instruction. Never shown for `instant` cannons (matches `clientCmdEnterCannon`'s instant
		branch never reaching the camera-override calls this HUD is conceptually paired with in real
		source - see `CameraController.updateCannonCamera`). */
	var cannonHudCtrl:GuiControl;

	var cannonRetImage:GuiImage;
	var cannonRetTiles:Map<String, Tile>;
	var cannonChargeCtrl:GuiControl;
	var cannonChargeIm1:GuiImage;
	var cannonChargeIm2:GuiImage;
	var cannonChargeIm3:GuiImage;
	var cannonChargeIm4:GuiImage;

	/** `cannonChargeTiles[quadrant 0-3][step 0-5]` - step 0 is always the shared "empty" tile
		(`cannon_0.png`, matches real source reusing that same file for every quadrant's zero
		state). */
	var cannonChargeTiles:Array<Array<Tile>>;

	var powerupBox:GuiImage;
	var powerupLockedTile:Tile;
	var powerupUnlockedTile:Tile;
	var powerupImageScene:h3d.scene.Scene;
	var powerupImageSceneTarget:Texture;
	var powerupImageSceneTargetBitmap:Bitmap;
	var powerupImageObject:DtsObject;

	var blastBarTile:h2d.Tile;
	var blastBarGreenTile:h2d.Tile;
	var blastBarGrayTile:h2d.Tile;
	var blastBarChargedTile:h2d.Tile;

	var RSGOCenterText:Anim;

	var helpTextContainer:GuiControl;
	var helpTextBorder:GuiBitmapBorderCtrl;
	var helpTextForeground:GuiText;
	var helpTextBackground:GuiText;

	var helpTextDuration:Float = 0;
	var helpTextStartTime = -1e8;

	/** Ported from PQ's `PG_MessageListBox` (`createHelpMessage`/`updateMessages`,
		`client/scripts/chathud.cs`) - see `ToastMessage`'s doc comment for how this maps to (and
		replaces) this port's earlier single-message `alertText*`/`setAlertText` placeholder. Real
		values: `horizSizing="right"`, `vertSizing="height"`, `position="0 70"`, `extent="500 500"`. */
	var toastListBox:GuiControl;

	var toastMessages:Array<ToastMessage> = [];
	var toastMessageFont:h2d.Font;

	var blastBar:GuiControl;
	var blastFill:GuiImage;
	var blastFrame:GuiImage;

	var playerListContainer:GuiControl;
	var playerListCtrl:GuiMLTextListCtrl;
	var playerListScoresCtrl:GuiMLTextListCtrl;
	var playerList:Array<PlayerInfo> = [];

	var imageResources:Array<Resource<Image>> = [];
	var textureResources:Array<Resource<Texture>> = [];
	var soundResources:Array<Resource<Sound>> = [];

	var playGuiCtrl:GuiControl;
	var chatCtrl:ChatCtrl;
	var spectatorCtrl:GuiControl;
	var spectatorTxt:GuiMLText;
	var spectatorTxtMode:Int = -1;

	var resizeEv:Void->Void;

	var _init:Bool;

	var fpsMeter:GuiText;

	var middleMessages:Array<MiddleMessage> = [];

	public function dispose() {
		if (_init) {
			playGuiCtrl.dispose();

			if (playerListContainer != null) {
				playerListContainer.dispose();
				playerListContainer = null;
				playerListCtrl.dispose();
				playerListCtrl = null;
				playerListScoresCtrl.dispose();
				playerListScoresCtrl = null;
			}

			if (chatCtrl != null) {
				chatCtrl.dispose();
				chatCtrl = null;
			}

			if (spectatorCtrl != null) {
				spectatorCtrl.dispose();
				spectatorCtrl = null;
			}

			gemImageScene.dispose();
			gemImageSceneTarget.dispose();
			gemImageSceneTargetBitmap.remove();
			powerupImageScene.dispose();
			powerupImageSceneTarget.dispose();
			powerupImageSceneTargetBitmap.remove();
			RSGOCenterText.remove();

			// These are raw h2d objects added directly to scene2d (not through playGuiCtrl's
			// GuiControl tree, which `playGuiCtrl.dispose()` above already handles) - matching the
			// gem/powerup image scene targets and RSGOCenterText above, they need their own explicit
			// removal or they'd be silently orphaned in scene2d past this level unloading.
			if (underwaterOverlay != null)
				underwaterOverlay.remove();
			if (bubbleBarFillBmp != null) {
				bubbleBarFillBmp.remove();
				bubbleBarMeterBmp.remove();
				bubbleBarText.remove();
			}
			if (fireballBarFillBmp != null) {
				fireballBarFillBmp.remove();
				fireballBarMeterBmp.remove();
				fireballBarText.remove();
			}

			for (textureResource in textureResources) {
				textureResource.release();
			}
			for (imageResource in imageResources) {
				imageResource.release();
			}
			for (audioResource in soundResources) {
				audioResource.release();
			}

			Window.getInstance().removeResizeEvent(resizeEv);
		}
	}

	public function init(scene2d:h2d.Scene, game:String) {
		this.scene2d = scene2d;
		this._init = true;

		playGuiCtrl = new GuiControl();
		playGuiCtrl.position = new Vector();
		playGuiCtrl.extent = new Vector(800, 600);
		playGuiCtrl.horizSizing = Width;
		playGuiCtrl.vertSizing = Height;

		var numberTiles = [];
		for (i in 0...10) {
			var tile = ResourceLoader.getResource('data/ui/game/numbers/${i}.png', ResourceLoader.getImage, this.imageResources).toTile();
			numberTiles.push(tile);
		}

		for (i in 0...7) {
			timerNumbers.push(new GuiAnim(numberTiles));
		}

		if (MarbleGame.instance.world.isMultiplayer) {
			for (i in 0...3) {
				countdownNumbers.push(new GuiAnim(numberTiles));
			}
		}

		for (i in 0...6) {
			gemCountNumbers.push(new GuiAnim(numberTiles));
		}

		speedometerDigitHun = new GuiAnim(numberTiles);
		speedometerDigitTen = new GuiAnim(numberTiles);
		speedometerDigitOne = new GuiAnim(numberTiles);

		lapsCounterDigitComplete = new GuiAnim(numberTiles);
		lapsCounterDigitTotal = new GuiAnim(numberTiles);

		for (i in 0...7) {
			countdownThNumbers.push(new GuiAnim(numberTiles));
		}

		var rsgo = [];
		rsgo.push(ResourceLoader.getResource("data/ui/game/ready.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/set.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/go.png", ResourceLoader.getImage, this.imageResources).toTile());
		rsgo.push(ResourceLoader.getResource("data/ui/game/outofbounds.png", ResourceLoader.getImage, this.imageResources).toTile());
		RSGOCenterText = new Anim(rsgo, 0, scene2d);

		powerupUnlockedTile = ResourceLoader.getResource('data/ui/game/powerup.png', ResourceLoader.getImage, this.imageResources).toTile();
		powerupLockedTile = ResourceLoader.getResource('data/ui/game/powerup_locked.png', ResourceLoader.getImage, this.imageResources).toTile();
		powerupBox = new GuiImage(powerupUnlockedTile);
		initTimer();
		initGemCounter();
		initCenterText();
		initPowerupBox();
		initQuotaCounter();
		initLapsCounter();
		initCountdownThTimer();
		initSpeedometer();
		initUnderwaterOverlay();
		initBubbleBar();
		initFireballBar();
		initCannonHud();
		if (game == 'ultra' || Net.isMP)
			initBlastBar();
		initTexts();
		if (Settings.optionsSettings.frameRateVis)
			initFPSMeter();

		if (MarbleGame.instance.world.isMultiplayer) {
			initPlayerList();
			initChatHud();
			if (Net.hostSpectate || Net.clientSpectate)
				initSpectatorMenu();

			initGemCountdownTimer();
		}

		if (Util.isTouchDevice()) {
			MarbleGame.instance.touchInput.showControls(this.playGuiCtrl, game == 'ultra' || MarbleGame.instance.world.isMultiplayer);
		}

		playGuiCtrl.render(scene2d);

		resizeEv = () -> {
			var wnd = Window.getInstance();
			playGuiCtrl.render(MarbleGame.canvas.scene2d);
			powerupImageSceneTargetBitmap.x = wnd.width - 88;
		};

		Window.getInstance().addResizeEvent(resizeEv);
	}

	public function initTimer() {
		var timerCtrl = new GuiControl();
		timerCtrl.horizSizing = HorizSizing.Center;
		timerCtrl.position = new Vector(219, 0);
		timerCtrl.extent = new Vector(362, 69);

		var timerTransparency = new GuiImage(ResourceLoader.getResource('data/ui/game/transparency.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		timerTransparency.horizSizing = Center;
		timerTransparency.position = new Vector(77, -7);
		timerTransparency.extent = new Vector(216, 79);
		timerTransparency.doClipping = false;
		timerCtrl.addChild(timerTransparency);

		timerNumbers[0].position = new Vector(80, 3);
		timerNumbers[0].extent = new Vector(43, 55);

		timerNumbers[1].position = new Vector(104, 3);
		timerNumbers[1].extent = new Vector(43, 55);

		var colonCols = [
			ResourceLoader.getResource('data/ui/game/numbers/colon.png', ResourceLoader.getImage, this.imageResources).toTile(),
		];

		timerColon = new GuiAnim(colonCols);
		timerColon.position = new Vector(124, 3);
		timerColon.extent = new Vector(43, 55);

		timerNumbers[2].position = new Vector(140, 3);
		timerNumbers[2].extent = new Vector(43, 55);

		timerNumbers[3].position = new Vector(164, 3);
		timerNumbers[3].extent = new Vector(43, 55);

		var pointCols = [
			ResourceLoader.getResource('data/ui/game/numbers/point.png', ResourceLoader.getImage, this.imageResources).toTile(),
		];

		timerPoint = new GuiAnim(pointCols);
		timerPoint.position = new Vector(184, 3);
		timerPoint.extent = new Vector(43, 55);

		timerNumbers[4].position = new Vector(200, 3);
		timerNumbers[4].extent = new Vector(43, 55);

		timerNumbers[5].position = new Vector(224, 3);
		timerNumbers[5].extent = new Vector(43, 55);

		timerNumbers[6].position = new Vector(248, 0);
		timerNumbers[6].extent = new Vector(43, 55);

		timerCtrl.addChild(timerNumbers[0]);
		timerCtrl.addChild(timerNumbers[1]);
		timerCtrl.addChild(timerColon);
		timerCtrl.addChild(timerNumbers[2]);
		timerCtrl.addChild(timerNumbers[3]);
		timerCtrl.addChild(timerPoint);
		timerCtrl.addChild(timerNumbers[4]);
		timerCtrl.addChild(timerNumbers[5]);
		timerCtrl.addChild(timerNumbers[6]);

		playGuiCtrl.addChild(timerCtrl);
	}

	public function initGemCountdownTimer() {
		var timerCtrl = new GuiControl();
		timerCtrl.horizSizing = HorizSizing.Center;
		timerCtrl.position = new Vector(215, 1);
		timerCtrl.extent = new Vector(374, 58);

		countdownNumbers[0].position = new Vector(33, 10);
		countdownNumbers[0].extent = new Vector(28, 37);

		countdownNumbers[1].position = new Vector(49, 10);
		countdownNumbers[1].extent = new Vector(28, 37);

		var pointCols = [
			ResourceLoader.getResource('data/ui/game/numbers/point.png', ResourceLoader.getImage, this.imageResources).toTile(),
		];

		countdownPoint = new GuiAnim(pointCols);
		countdownPoint.position = new Vector(59, 10);
		countdownPoint.extent = new Vector(28, 37);

		countdownNumbers[2].position = new Vector(70, 10);
		countdownNumbers[2].extent = new Vector(28, 37);

		countdownIcon = new GuiImage(ResourceLoader.getResource("data/ui/game/timerhuntrespawn.png", ResourceLoader.getImage, this.imageResources).toTile());
		countdownIcon.position = new Vector(0, 10);
		countdownIcon.extent = new Vector(36, 36);

		timerCtrl.addChild(countdownIcon);
		timerCtrl.addChild(countdownNumbers[0]);
		timerCtrl.addChild(countdownNumbers[1]);
		timerCtrl.addChild(countdownPoint);
		timerCtrl.addChild(countdownNumbers[2]);

		playGuiCtrl.addChild(timerCtrl);
	}

	public function initCenterText() {
		RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[0].width * Settings.uiScale / 2;
		RSGOCenterText.y = scene2d.height * 0.3; // - RSGOCenterText.frames[0].height / 2;
		RSGOCenterText.setScale(Settings.uiScale);
	}

	public function setCenterText(identifier:String) {
		if (identifier == 'none') {
			this.RSGOCenterText.visible = false;
		} else if (identifier == 'ready') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 0;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[0].width * Settings.uiScale / 2;
		} else if (identifier == 'set') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 1;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[1].width * Settings.uiScale / 2;
		} else if (identifier == 'go') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 2;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[2].width * Settings.uiScale / 2;
		} else if (identifier == 'outofbounds') {
			this.RSGOCenterText.visible = true;
			this.RSGOCenterText.currentFrame = 3;
			RSGOCenterText.x = scene2d.width / 2 - RSGOCenterText.frames[3].width * Settings.uiScale / 2;
		}
	}

	public function doStateChangeSound(state:String) {
		static var curState = "none";
		if (curState != state) {
			if (state == "ready") {
				AudioManager.playSound(ResourceLoader.getResource('data/sound/ready.wav', ResourceLoader.getAudio, @:privateAccess this.soundResources));
			}
			if (state == "set") {
				AudioManager.playSound(ResourceLoader.getResource('data/sound/set.wav', ResourceLoader.getAudio, @:privateAccess this.soundResources));
			}
			if (state == "go") {
				AudioManager.playSound(ResourceLoader.getResource('data/sound/go.wav', ResourceLoader.getAudio, @:privateAccess this.soundResources));
			}
		}

		curState = state;
	}

	public function initGemCounter() {
		gemCountNumbers[0].position = new Vector(30, 0);
		gemCountNumbers[0].extent = new Vector(43, 55);

		gemCountNumbers[1].position = new Vector(54, 0);
		gemCountNumbers[1].extent = new Vector(43, 55);

		gemCountNumbers[2].position = new Vector(78, 0);
		gemCountNumbers[2].extent = new Vector(43, 55);

		gemCountSlash = new GuiImage(ResourceLoader.getResource('data/ui/game/numbers/slash.png', ResourceLoader.getImage, this.imageResources).toTile());
		gemCountSlash.position = new Vector(101, 0);
		gemCountSlash.extent = new Vector(43, 55);

		gemCountNumbers[3].position = new Vector(120, 0);
		gemCountNumbers[3].extent = new Vector(43, 55);

		gemCountNumbers[4].position = new Vector(144, 0);
		gemCountNumbers[4].extent = new Vector(43, 55);

		gemCountNumbers[5].position = new Vector(168, 0);
		gemCountNumbers[5].extent = new Vector(43, 55);

		playGuiCtrl.addChild(gemCountNumbers[0]);
		playGuiCtrl.addChild(gemCountNumbers[1]);
		playGuiCtrl.addChild(gemCountNumbers[2]);
		playGuiCtrl.addChild(gemCountSlash);
		playGuiCtrl.addChild(gemCountNumbers[3]);
		playGuiCtrl.addChild(gemCountNumbers[4]);
		playGuiCtrl.addChild(gemCountNumbers[5]);

		this.gemImageScene = new h3d.scene.Scene();
		// var gemImageRenderer = cast(this.gemImageScene.renderer, h3d.scene.Renderer);
		// gemImageRenderer.skyMode = Hide;

		gemImageSceneTarget = new Texture(60, 60, [Target]);
		gemImageSceneTarget.depthBuffer = new DepthBuffer(60, 60);

		gemImageSceneTargetBitmap = new Bitmap(Tile.fromTexture(gemImageSceneTarget), scene2d);
		gemImageSceneTargetBitmap.x = -8 * Settings.uiScale;
		gemImageSceneTargetBitmap.y = -8 * Settings.uiScale;
		gemImageSceneTargetBitmap.setScale(Settings.uiScale);
		// gemImageSceneTargetBitmap.blendMode = None;
		// gemImageSceneTargetBitmap.addShader(new ColorKey());

		var GEM_COLORS = ["blue", "red", "yellow", "purple", "green", "turquoise", "orange", "black"];
		var gemColor = GEM_COLORS[Math.floor(Math.random() * GEM_COLORS.length)];

		if (MarbleGame.instance.world.mission.missionInfo.game == "PlatinumQuest")
			gemColor = "platinum";

		gemImageObject = new DtsObject();
		gemImageObject.dtsPath = "data/shapes/items/gem.dts";
		gemImageObject.ambientRotate = true;
		gemImageObject.showSequences = false;
		gemImageObject.matNameOverride.set('base.gem', gemColor + ".gem");
		// gemImageObject.matNameOverride.set("base.gem", "base.gem.");
		gemImageObject.ambientSpinFactor /= -2;
		// ["base.gem"] = color + ".gem";
		gemImageObject.init(null, () -> {});

		for (mat in gemImageObject.materials) {
			mat.mainPass.enableLights = false;

			// Huge hacks
			if (mat.blendMode != Add) {
				var alphaShader = new h3d.shader.AlphaChannel();
				mat.mainPass.addShader(alphaShader);
			}
		}
		gemImageScene.addChild(gemImageObject);
		var gemImageCenter = gemImageObject.getBounds().getCenter();

		gemImageScene.camera.pos = new Vector(0, 3, gemImageCenter.z);
		gemImageScene.camera.target = new Vector(gemImageCenter.x, gemImageCenter.y, gemImageCenter.z);
		onFinish();
	}

	function initQuotaCounter() {
		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		gemsQuota = new GuiText(markerFelt32);
		gemsQuota.position = new Vector(205, 28);
		gemsQuota.extent = new Vector(55, 55);
		gemsQuota.text.color = Vector.fromColor(0xFFFFFFFF);
		playGuiCtrl.addChild(gemsQuota);

		setQuotaCounterVisible(false);
	}

	/** Shows/hides the small "/trueTotal" suffix beside the main gem counter (`QuotaMode` only). */
	public function setQuotaCounterVisible(visible:Bool) {
		gemsQuota.text.visible = visible;
	}

	/** Sets the "/trueTotal" digits to the level's real total gem count (`level.totalGems`) - this
		doesn't change during a run, so it's set once when Quota activates, not every pickup. */
	public function formatQuotaCounter(trueTotal:Int) {
		gemsQuota.text.text = '/${trueTotal}';
	}

	function initLapsCounter() {
		lapsCounterCtrl = new GuiControl();
		lapsCounterCtrl.horizSizing = Center;
		lapsCounterCtrl.position = new Vector(316, 62);
		lapsCounterCtrl.extent = new Vector(168, 41);
		playGuiCtrl.addChild(lapsCounterCtrl);

		lapsCounterTransparency = new GuiImage(ResourceLoader.getResource('data/ui/game/laps/transparency_laps.png', ResourceLoader.getImage,
			this.imageResources)
			.toTile());
		lapsCounterTransparency.position = new Vector(0, 0);
		lapsCounterTransparency.extent = new Vector(168, 41);
		lapsCounterCtrl.addChild(lapsCounterTransparency);

		lapsCounterLabel = new GuiImage(ResourceLoader.getResource('data/ui/game/laps/laps_label.png', ResourceLoader.getImage, this.imageResources).toTile());
		lapsCounterLabel.position = new Vector(11, 1);
		lapsCounterLabel.extent = new Vector(57, 41);
		lapsCounterCtrl.addChild(lapsCounterLabel);

		lapsCounterDigitComplete.position = new Vector(99, 0);
		lapsCounterDigitComplete.extent = new Vector(28, 37);
		lapsCounterCtrl.addChild(lapsCounterDigitComplete);

		lapsCounterSlash = new GuiImage(ResourceLoader.getResource('data/ui/game/numbers/slash.png', ResourceLoader.getImage, this.imageResources).toTile());
		lapsCounterSlash.position = new Vector(115, 0);
		lapsCounterSlash.extent = new Vector(28, 37);
		lapsCounterCtrl.addChild(lapsCounterSlash);

		lapsCounterDigitTotal.position = new Vector(132, 0);
		lapsCounterDigitTotal.extent = new Vector(28, 37);
		lapsCounterCtrl.addChild(lapsCounterDigitTotal);

		setLapsCounterVisible(false);
	}

	public function setLapsCounterVisible(visible:Bool) {
		lapsCounterTransparency.bmp.visible = visible;
		lapsCounterLabel.bmp.visible = visible;
		lapsCounterDigitComplete.anim.visible = visible;
		lapsCounterSlash.bmp.visible = visible;
		lapsCounterDigitTotal.anim.visible = visible;
	}

	/** Ported from `PlayGui::updateLaps` (`client/scripts/playGui.cs`) - only the *ones* digit of
		each count is ever shown (`%completeOne = (%this.lapsComplete % 10)`, matching the source
		exactly, quirks included - a mission with >= 10 laps would display misleadingly, but that's
		what the original does too), tinted green once `complete >= total`. */
	public function formatLapsCounter(complete:Int, total:Int) {
		var color = complete >= total ? timerStopped : timerNormal;
		lapsCounterDigitComplete.anim.currentFrame = complete % 10;
		lapsCounterDigitComplete.anim.color = Vector.fromColor(color);
		lapsCounterDigitTotal.anim.currentFrame = total % 10;
		lapsCounterDigitTotal.anim.color = Vector.fromColor(color);
		lapsCounterSlash.bmp.color = Vector.fromColor(color);
	}

	function initCountdownThTimer() {
		countdownThCtrl = new GuiControl();
		countdownThCtrl.horizSizing = Center;
		countdownThCtrl.position = new Vector(316, 62);
		countdownThCtrl.extent = new Vector(168, 41);
		playGuiCtrl.addChild(countdownThCtrl);

		countdownThImage = new GuiImage(ResourceLoader.getResource('data/ui/game/countdown/timerTimeTravel.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		countdownThImage.position = new Vector(3, 3);
		countdownThImage.extent = new Vector(36, 36);
		countdownThCtrl.addChild(countdownThImage);

		countdownThNumbers[0].position = new Vector(35, 0); // minutes tens
		countdownThNumbers[0].extent = new Vector(28, 37);
		countdownThNumbers[1].position = new Vector(51, 0); // minutes ones
		countdownThNumbers[1].extent = new Vector(28, 37);

		var colonCols = [
			ResourceLoader.getResource('data/ui/game/numbers/colon.png', ResourceLoader.getImage, this.imageResources).toTile()
		];
		countdownThColon = new GuiAnim(colonCols);
		countdownThColon.position = new Vector(62, 0);
		countdownThColon.extent = new Vector(28, 37);

		countdownThNumbers[2].position = new Vector(73, 0); // seconds tens
		countdownThNumbers[2].extent = new Vector(28, 37);
		countdownThNumbers[3].position = new Vector(89, 0); // seconds ones
		countdownThNumbers[3].extent = new Vector(28, 37);

		var pointCols = [
			ResourceLoader.getResource('data/ui/game/numbers/point.png', ResourceLoader.getImage, this.imageResources).toTile()
		];
		countdownThPoint = new GuiAnim(pointCols);
		countdownThPoint.position = new Vector(101, 0);
		countdownThPoint.extent = new Vector(28, 37);

		countdownThNumbers[4].position = new Vector(108, 0); // hundredths tens
		countdownThNumbers[4].extent = new Vector(28, 37);
		countdownThNumbers[5].position = new Vector(124, 0); // hundredths ones
		countdownThNumbers[5].extent = new Vector(28, 37);
		countdownThNumbers[6].position = new Vector(140, 0); // thousandths
		countdownThNumbers[6].extent = new Vector(28, 37);

		countdownThCtrl.addChild(countdownThNumbers[0]);
		countdownThCtrl.addChild(countdownThNumbers[1]);
		countdownThCtrl.addChild(countdownThColon);
		countdownThCtrl.addChild(countdownThNumbers[2]);
		countdownThCtrl.addChild(countdownThNumbers[3]);
		countdownThCtrl.addChild(countdownThPoint);
		countdownThCtrl.addChild(countdownThNumbers[4]);
		countdownThCtrl.addChild(countdownThNumbers[5]);
		countdownThCtrl.addChild(countdownThNumbers[6]);

		setCountdownThVisible(false);
	}

	public function setCountdownThVisible(visible:Bool) {
		countdownThImage.bmp.visible = visible;
		for (n in countdownThNumbers)
			n.anim.visible = visible;
		countdownThColon.anim.visible = visible;
		countdownThPoint.anim.visible = visible;
	}

	/** `icon` matches `CountdownStartTrigger`'s `icon` field (a filename under
		`data/ui/game/countdown/`, default `timerTimeTravel` per the source). */
	public function setCountdownThIcon(icon:String) {
		countdownThImage.setTile(ResourceLoader.getResource('data/ui/game/countdown/${icon}.png', ResourceLoader.getImage, this.imageResources).toTile());
	}

	/** Ported from `PlayGui::updateCountdown`'s thousandths branch (`client/scripts/playGui.cs`) -
		`time` is in seconds (matching `MarbleWorld.countdownRemaining`), `0` hides the whole
		control. */
	public function formatCountdownThTimer(time:Float, color:Int = 0xFFFFFFFF) {
		if (time <= 0) {
			setCountdownThVisible(false);
			return;
		}
		setCountdownThVisible(true);

		var et = time * 1000;
		var thousandth = et % 10;
		var hundredth = Math.floor((et % 1000) / 10);
		var totalSeconds = Math.floor(et / 1000);
		var seconds = totalSeconds % 60;
		var minutes = (totalSeconds - seconds) / 60;

		var secondsOne = seconds % 10;
		var secondsTen = (seconds - secondsOne) / 10;
		var minutesOne = minutes % 10;
		var minutesTen = ((minutes - minutesOne) / 10) % 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		countdownThNumbers[0].anim.currentFrame = minutesTen;
		countdownThNumbers[1].anim.currentFrame = minutesOne;
		countdownThNumbers[2].anim.currentFrame = secondsTen;
		countdownThNumbers[3].anim.currentFrame = secondsOne;
		countdownThNumbers[4].anim.currentFrame = hundredthTen;
		countdownThNumbers[5].anim.currentFrame = hundredthOne;
		countdownThNumbers[6].anim.currentFrame = thousandth;

		for (n in countdownThNumbers)
			n.anim.color = Vector.fromColor(color);
		countdownThColon.anim.color = Vector.fromColor(color);
		countdownThPoint.anim.color = Vector.fromColor(color);
	}

	function initSpeedometer() {
		speedometerCtrl = new GuiControl();
		speedometerCtrl.horizSizing = Left;
		speedometerCtrl.vertSizing = Top;
		speedometerCtrl.position = new Vector(699, 248);
		speedometerCtrl.extent = new Vector(107, 319);
		playGuiCtrl.addChild(speedometerCtrl);

		speedometerBorder = new GuiControl();
		speedometerBorder.horizSizing = Left;
		speedometerBorder.vertSizing = Top;
		speedometerBorder.position = new Vector(0, 0);
		speedometerBorder.extent = new Vector(95, 261);
		speedometerCtrl.addChild(speedometerBorder);

		speedometerBackground1 = new GuiImage(ResourceLoader.getResource('data/ui/game/speedometer/spdbackground1.png', ResourceLoader.getImage,
			this.imageResources)
			.toTile());
		speedometerBackground1.horizSizing = Left;
		speedometerBackground1.vertSizing = Top;
		speedometerBackground1.position = new Vector(18, -759);
		speedometerBackground1.extent = new Vector(64, 1008);
		speedometerBorder.addChild(speedometerBackground1);

		speedometerBackground2 = new GuiImage(ResourceLoader.getResource('data/ui/game/speedometer/spdbackground2.png', ResourceLoader.getImage,
			this.imageResources)
			.toTile());
		speedometerBackground2.horizSizing = Left;
		speedometerBackground2.vertSizing = Top;
		speedometerBackground2.position = new Vector(18, -1767);
		speedometerBackground2.extent = new Vector(64, 1008);
		speedometerBorder.addChild(speedometerBackground2);

		speedometerBackground3 = new GuiImage(ResourceLoader.getResource('data/ui/game/speedometer/spdbackground3.png', ResourceLoader.getImage,
			this.imageResources)
			.toTile());
		speedometerBackground3.horizSizing = Left;
		speedometerBackground3.vertSizing = Top;
		speedometerBackground3.position = new Vector(18, -2775);
		speedometerBackground3.extent = new Vector(64, 1008);
		speedometerBorder.addChild(speedometerBackground3);

		speedometerArrow = new GuiImage(ResourceLoader.getResource('data/ui/game/speedometer/spdarrow.png', ResourceLoader.getImage, this.imageResources)
			.toTile());
		speedometerArrow.horizSizing = Left;
		speedometerArrow.vertSizing = Top;
		speedometerArrow.position = new Vector(29, 1);
		speedometerArrow.extent = new Vector(64, 256);
		speedometerBorder.addChild(speedometerArrow);

		speedometerConsNormalTile = ResourceLoader.getResource('data/ui/game/speedometer/cons_normal.png', ResourceLoader.getImage, this.imageResources)
			.toTile();
		speedometerConsTooSlowTile = ResourceLoader.getResource('data/ui/game/speedometer/cons_tooslow.png', ResourceLoader.getImage, this.imageResources)
			.toTile();
		speedometerConsMarker = new GuiImage(speedometerConsNormalTile);
		speedometerConsMarker.horizSizing = Left;
		speedometerConsMarker.vertSizing = Top;
		speedometerConsMarker.position = new Vector(0, 0);
		speedometerConsMarker.extent = new Vector(64, 32);
		speedometerBorder.addChild(speedometerConsMarker);

		speedometerHasteAchievedTile = ResourceLoader.getResource('data/ui/game/speedometer/haste_achieved.png', ResourceLoader.getImage, this.imageResources)
			.toTile();
		speedometerHasteNotAchievedTile = ResourceLoader.getResource('data/ui/game/speedometer/haste_notachieved.png', ResourceLoader.getImage,
			this.imageResources)
			.toTile();
		speedometerHasteMarker = new GuiImage(speedometerHasteAchievedTile);
		speedometerHasteMarker.horizSizing = Left;
		speedometerHasteMarker.vertSizing = Top;
		speedometerHasteMarker.position = new Vector(0, 0);
		speedometerHasteMarker.extent = new Vector(64, 32);
		speedometerBorder.addChild(speedometerHasteMarker);

		var speedometerDigits = new GuiControl();
		speedometerDigits.horizSizing = Left;
		speedometerDigits.vertSizing = Top;
		speedometerDigits.position = new Vector(11, 255);
		speedometerDigits.extent = new Vector(96, 64);
		speedometerCtrl.addChild(speedometerDigits);

		speedometerDigitHun.position = new Vector(0, 0);
		speedometerDigitHun.extent = new Vector(43, 55);
		speedometerDigitTen.position = new Vector(13, 0);
		speedometerDigitTen.extent = new Vector(43, 55);
		speedometerDigitOne.position = new Vector(39, 0);
		speedometerDigitOne.extent = new Vector(43, 55);
		speedometerDigits.addChild(speedometerDigitHun);
		speedometerDigits.addChild(speedometerDigitTen);
		speedometerDigits.addChild(speedometerDigitOne);

		setSpeedometerVisible(false);
	}

	/** Called once, right after the first `render()` pass lays everything out - captures the
		"rest" (velocity = 0, "not hundreds") bare-element positions that `updateSpeedometer` adds a
		`Settings.uiScale`-multiplied delta on top of every frame, rather than re-deriving the full
		parent-offset chain each time. */
	function captureSpeedometerRestPositions() {
		speedometerBackground1RestY = speedometerBackground1.bmp.y;
		speedometerMarkerRestY = speedometerConsMarker.bmp.y;
		speedometerDigitOneRestX = speedometerDigitOne.anim.x;
		speedometerDigitTenRestX = speedometerDigitTen.anim.x;
		speedometerRestCaptured = true;
	}

	function setSpeedometerElementsVisible(visible:Bool) {
		speedometerBackground1.bmp.visible = visible;
		speedometerBackground2.bmp.visible = visible;
		speedometerBackground3.bmp.visible = visible;
		speedometerArrow.bmp.visible = visible;
		speedometerDigitTen.anim.visible = visible;
		speedometerDigitOne.anim.visible = visible;
		if (!visible) {
			speedometerDigitHun.anim.visible = false;
			speedometerConsMarker.bmp.visible = false;
			speedometerHasteMarker.bmp.visible = false;
		}
	}

	/** Ported from `Mode_consistency`/`Mode_haste`'s constructors - `0` disables that mode's
		threshold/marker; both can be set simultaneously (a `"Consistency Haste"` mission shows both
		markers on the same dial). */
	public function setConsistencyThreshold(minimumSpeed:Float) {
		speedometerMinimumSpeed = minimumSpeed;
	}

	public function setHasteThreshold(speedToQualify:Float) {
		speedometerSpeedToQualify = speedToQualify;
	}

	/** Ported from PQ's `PlayGui::updateSpeedometer` (`client/scripts/speedometer.cs`) - scrolls the
		3 stacked tape backgrounds so the tick mark for `velocity` sits under the fixed arrow,
		updates the digital digit readout (color: red if below `speedometerMinimumSpeed`, green if
		above `speedometerSpeedToQualify`, else white), and repositions both threshold markers so
		they scroll in lockstep with the tape (same formula as the tape, offset by a constant baked
		from each threshold - see `ConsistencyMode`/`HasteMode`'s HUD wiring for the derivation).
		Runs once per frame from `MarbleWorld`'s update loop regardless of which/how many of
		Consistency/Haste are active, rather than each mode independently re-running this (which
		would double the work and let whichever mode's `update()` ran last stomp on the other's
		digit-coloring). */
	public function updateSpeedometer(velocity:Float) {
		if (speedometerCtrl == null)
			return;

		var active = speedometerMinimumSpeed > 0 || speedometerSpeedToQualify > 0;
		setSpeedometerElementsVisible(active);
		if (!active)
			return;

		if (!speedometerRestCaptured)
			captureSpeedometerRestPositions();

		// Ported from `speedometer.cs`'s digit-shift logic (makes room for the hundreds digit).
		var showHundreds = velocity >= 100;
		var showTens = velocity >= 10;
		var hundredsShiftUiUnits = (showHundreds ? 11 : 0) * Settings.uiScale;
		speedometerDigitOne.anim.x = speedometerDigitOneRestX + hundredsShiftUiUnits;
		speedometerDigitTen.anim.x = speedometerDigitTenRestX + hundredsShiftUiUnits;
		speedometerDigitHun.anim.visible = showHundreds;
		speedometerDigitTen.anim.visible = showTens;

		var one = Math.floor(velocity) % 10;
		var ten = Math.floor(velocity / 10) % 10;
		var hun = Math.floor(velocity / 100) % 10;

		var colorOffset = 0; // normal/white
		if (speedometerMinimumSpeed > 0 && velocity < speedometerMinimumSpeed)
			colorOffset = 20; // red - too slow for Consistency
		else if (speedometerSpeedToQualify > 0 && velocity > speedometerSpeedToQualify)
			colorOffset = 10; // green - qualified for Haste

		speedometerDigitOne.anim.currentFrame = one + colorOffset;
		speedometerDigitTen.anim.currentFrame = ten + colorOffset;
		speedometerDigitHun.anim.currentFrame = hun + colorOffset;

		// Ported from `speedometer.cs`'s scroll math, scaled by 0.8 (PQ's 800x600 reference canvas
		// vs this port's 640x480 one) - see class doc for the derivation.
		var targetY = -607.2 + 6.4 * velocity;
		if (targetY > 1710.4)
			targetY = 1710.4; // Matches the "gone to plaid" clamp (without the achievement popup)
		var deltaCanvasUnits = targetY - (-607.2);

		speedometerBackground1.bmp.y = speedometerBackground1RestY + deltaCanvasUnits * Settings.uiScale;
		speedometerBackground2.bmp.y = speedometerBackground1RestY + (deltaCanvasUnits - 806.4) * Settings.uiScale;
		speedometerBackground3.bmp.y = speedometerBackground1RestY + (deltaCanvasUnits - 1612.8) * Settings.uiScale;

		if (speedometerMinimumSpeed > 0) {
			speedometerConsMarker.bmp.visible = true;
			speedometerConsMarker.setTile(velocity < speedometerMinimumSpeed ? speedometerConsTooSlowTile : speedometerConsNormalTile);
			var markerCanvasUnits = targetY + 685.6 - 6.4 * speedometerMinimumSpeed;
			speedometerConsMarker.bmp.y = speedometerMarkerRestY + markerCanvasUnits * Settings.uiScale;
		} else {
			speedometerConsMarker.bmp.visible = false;
		}

		if (speedometerSpeedToQualify > 0) {
			speedometerHasteMarker.bmp.visible = true;
			speedometerHasteMarker.setTile(velocity >= speedometerSpeedToQualify ? speedometerHasteAchievedTile : speedometerHasteNotAchievedTile);
			var markerCanvasUnits = targetY + 685.6 - 6.4 * speedometerSpeedToQualify;
			speedometerHasteMarker.bmp.y = speedometerMarkerRestY + markerCanvasUnits * Settings.uiScale;
		} else {
			speedometerHasteMarker.bmp.visible = false;
		}
	}

	function setSpeedometerVisible(visible:Bool) {
		setSpeedometerElementsVisible(visible);
	}

	function initUnderwaterOverlay() {
		underwaterOverlay = new Bitmap(ResourceLoader.getResource('data/ui/game/underwaterol.png', ResourceLoader.getImage, this.imageResources).toTile(),
			scene2d);
		underwaterOverlay.width = scene2d.width;
		underwaterOverlay.height = scene2d.height;
		underwaterOverlay.visible = false;
	}

	/** `cameraInWater` is computed by `MarbleWorld` (it owns the actual camera position/water-
		trigger lookup) and just passed through here every frame. */
	public function setUnderwaterOverlayVisible(cameraInWater:Bool) {
		if (underwaterOverlay == null)
			return;
		underwaterOverlay.visible = cameraInWater;
		underwaterOverlay.width = scene2d.width;
		underwaterOverlay.height = scene2d.height;
	}

	/** Ported from `playGui.gui`'s `PGCannonRet`/`PGChargeGui` control tree - see
		`cannonHudCtrl`'s doc comment for scope (reticle + charge gauge only, no aim-assist rings). */
	function initCannonHud() {
		cannonHudCtrl = new GuiControl();
		cannonHudCtrl.horizSizing = Center;
		cannonHudCtrl.vertSizing = Center;
		cannonHudCtrl.position = new Vector(272, 172);
		cannonHudCtrl.extent = new Vector(256, 256);
		playGuiCtrl.addChild(cannonHudCtrl);

		cannonRetTiles = [
			"white" => ResourceLoader.getResource('data/ui/game/cannon/retwhite.png', ResourceLoader.getImage, this.imageResources).toTile(),
			"green" => ResourceLoader.getResource('data/ui/game/cannon/retgreen.png', ResourceLoader.getImage, this.imageResources).toTile(),
			"blue" => ResourceLoader.getResource('data/ui/game/cannon/retblue.png', ResourceLoader.getImage, this.imageResources).toTile(),
			"red" => ResourceLoader.getResource('data/ui/game/cannon/retred.png', ResourceLoader.getImage, this.imageResources).toTile(),
		];
		cannonRetImage = new GuiImage(cannonRetTiles.get("white"));
		cannonRetImage.horizSizing = Center;
		cannonRetImage.vertSizing = Center;
		cannonRetImage.position = new Vector(0, 0);
		cannonRetImage.extent = new Vector(256, 256);
		cannonHudCtrl.addChild(cannonRetImage);
		cannonRetImage.bmp.visible = false;

		var zeroTile = ResourceLoader.getResource('data/ui/game/cannon/cannon_0.png', ResourceLoader.getImage, this.imageResources).toTile();
		cannonChargeTiles = [];
		for (q in 1...5) {
			var row = [zeroTile];
			for (s in 1...6)
				row.push(ResourceLoader.getResource('data/ui/game/cannon/charge_${q}_${s}.png', ResourceLoader.getImage, this.imageResources).toTile());
			cannonChargeTiles.push(row);
		}

		cannonChargeCtrl = new GuiControl();
		cannonChargeCtrl.horizSizing = Right;
		cannonChargeCtrl.vertSizing = Bottom;
		cannonChargeCtrl.position = new Vector(0, 0);
		cannonChargeCtrl.extent = new Vector(256, 256);
		cannonHudCtrl.addChild(cannonChargeCtrl);

		function makeChargeImage(x:Float, y:Float) {
			var img = new GuiImage(zeroTile);
			img.horizSizing = Right;
			img.vertSizing = Bottom;
			img.position = new Vector(x, y);
			img.extent = new Vector(98, 98);
			cannonChargeCtrl.addChild(img);
			img.bmp.visible = false;
			return img;
		}
		// Positions match `playGui.gui`'s `PGChargeEx1..4` - a 2x2 grid, quadrant N drawing from
		// `charge_N_*.png`.
		cannonChargeIm1 = makeChargeImage(129, 29);
		cannonChargeIm2 = makeChargeImage(29, 29);
		cannonChargeIm3 = makeChargeImage(29, 129);
		cannonChargeIm4 = makeChargeImage(129, 129);
	}

	/** Ported from `updateCannonUI` (`client/scripts/cannon.cs`) - `showAim`/aim-assist half is
		intentionally not implemented (see `cannonHudCtrl`'s doc comment), so the charge gauge is
		shown whenever `useCharge` is true regardless of `showAim` (real source only shows it when
		`useCharge && !showAim`, since a `showAim` cannon normally gets its charge feedback from the
		rings instead - since this port has no rings yet, showing the gauge unconditionally for
		`useCharge` cannons is the only way charge feedback exists at all right now; safe to tighten
		back to the real condition once aim-assist rings are ported). `GuiControl` itself has no
		visibility concept (`gui.GuiControl` is purely a layout container) - visibility is toggled on
		each leaf `GuiImage`'s own `.bmp` directly, matching this file's established convention
		(`setLapsCounterVisible`/`setCountdownThVisible`, etc). */
	public function updateCannonHud(showReticle:Bool, skin:String, useCharge:Bool, chargeFraction:Float) {
		if (cannonHudCtrl == null)
			return;

		cannonRetImage.bmp.visible = showReticle;
		if (showReticle) {
			var tile = cannonRetTiles.get(skin);
			cannonRetImage.setTile(tile != null ? tile : cannonRetTiles.get("white"));
		}

		cannonChargeIm1.bmp.visible = useCharge;
		cannonChargeIm2.bmp.visible = useCharge;
		cannonChargeIm3.bmp.visible = useCharge;
		cannonChargeIm4.bmp.visible = useCharge;
		if (useCharge) {
			var t = Util.clamp(chargeFraction, 0, 1);
			if (t <= 0.1) {
				cannonChargeIm1.setTile(cannonChargeTiles[0][0]);
				cannonChargeIm2.setTile(cannonChargeTiles[1][0]);
				cannonChargeIm3.setTile(cannonChargeTiles[2][0]);
				cannonChargeIm4.setTile(cannonChargeTiles[3][0]);
			} else {
				var img = Std.int(Math.min(10, Math.floor(t * 10)));
				if (t < 0.6) {
					cannonChargeIm3.setTile(cannonChargeTiles[2][img]);
					cannonChargeIm4.setTile(cannonChargeTiles[3][img]);
					cannonChargeIm1.setTile(cannonChargeTiles[0][0]);
					cannonChargeIm2.setTile(cannonChargeTiles[1][0]);
				} else {
					img -= 5;
					cannonChargeIm1.setTile(cannonChargeTiles[0][img]);
					cannonChargeIm2.setTile(cannonChargeTiles[1][img]);
					cannonChargeIm3.setTile(cannonChargeTiles[2][5]);
					cannonChargeIm4.setTile(cannonChargeTiles[3][5]);
				}
			}
		}
	}

	public function hideCannonHud() {
		if (cannonHudCtrl == null)
			return;
		cannonRetImage.bmp.visible = false;
		cannonChargeIm1.bmp.visible = false;
		cannonChargeIm2.bmp.visible = false;
		cannonChargeIm3.bmp.visible = false;
		cannonChargeIm4.bmp.visible = false;
	}

	function initFireballBar() {
		fireballBarFillFlow = new h2d.Flow(scene2d);
		fireballBarFillFlow.overflow = FlowOverflow.Hidden;
		fireballBarFillFlow.multiline = true;

		var barTile = ResourceLoader.getResource('data/ui/game/specials/bar.png', ResourceLoader.getImage, this.imageResources).toTile();
		fireballBarFillBmp = new Bitmap(barTile, fireballBarFillFlow);
		fireballBarFillBmp.setScale(Settings.uiScale);
		fireballBarFillBmp.visible = false;
		fireballBarFillFlow.maxWidth = Std.int(barTile.width * Settings.uiScale);
		fireballBarFillFlow.maxHeight = Std.int(barTile.height * Settings.uiScale);

		fireballBarLitTile = ResourceLoader.getResource('data/ui/game/specials/fireballbar-lit.png', ResourceLoader.getImage, this.imageResources).toTile();
		fireballBarUnlitTile = ResourceLoader.getResource('data/ui/game/specials/fireballbar-unlit.png', ResourceLoader.getImage, this.imageResources)
			.toTile();
		fireballBarMeterBmp = new Bitmap(fireballBarUnlitTile, scene2d);
		fireballBarMeterBmp.setScale(Settings.uiScale);
		fireballBarMeterBmp.visible = false;

		var fireballFontData = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var fireballFontB = new BitmapFont(fireballFontData.entry);
		@:privateAccess fireballFontB.loader = ResourceLoader.loader;
		var fireballFont = fireballFontB.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);
		fireballBarText = new h2d.Text(fireballFont, scene2d);
		fireballBarText.textColor = 0x000000;
		fireballBarText.visible = false;
	}

	/** See `setBubbleBarPosition`'s doc comment - same convention. */
	public function setFireballBarPosition(x:Float, y:Float) {
		if (fireballBarMeterBmp == null)
			return;
		fireballBarMeterBmp.x = x;
		fireballBarMeterBmp.y = y;
		fireballBarText.x = x + 12 * Settings.uiScale;
		fireballBarText.y = y + 24 * Settings.uiScale;
		fireballBarFillFlow.setPosition(x, y);
	}

	/** Ported from PQ's `PlayGui::updateFireballBar` - same 50-133 fill range as the Bubble bar. */
	public function updateFireballBar(fireballTime:Float, fireballTotalTime:Float, canBlast:Bool) {
		if (fireballBarMeterBmp == null)
			return;
		if (fireballTime > 0) {
			fireballBarMeterBmp.visible = true;
			fireballBarMeterBmp.tile = canBlast ? fireballBarLitTile : fireballBarUnlitTile;
			fireballBarFillBmp.visible = true;
			fireballBarText.visible = true;
			var fraction = fireballTotalTime > 0 ? fireballTime / fireballTotalTime : 0;

			fireballBarFillFlow.maxWidth = Std.int((50 + 83 * fraction) * Settings.uiScale);
			var fmt = '${Math.fround(fireballTime * 10) / 10}';
			if (fmt.indexOf('.') == -1)
				fmt += ".0"; // add decimal
			fireballBarText.text = fmt;
		} else {
			fireballBarMeterBmp.visible = false;
			fireballBarFillBmp.visible = false;
			fireballBarText.visible = false;
		}
	}

	function initBubbleBar() {
		bubbleBarFillFlow = new h2d.Flow(scene2d);
		bubbleBarFillFlow.overflow = FlowOverflow.Hidden;
		bubbleBarFillFlow.multiline = true;
		var barTile = ResourceLoader.getResource('data/ui/game/specials/bar.png', ResourceLoader.getImage, this.imageResources).toTile();

		bubbleBarFillBmp = new Bitmap(barTile, bubbleBarFillFlow);
		bubbleBarFillBmp.setScale(Settings.uiScale);
		bubbleBarFillBmp.visible = false;
		bubbleBarFillFlow.maxWidth = Std.int(barTile.width * Settings.uiScale);
		bubbleBarFillFlow.maxHeight = Std.int(barTile.height * Settings.uiScale);

		bubbleBarNormalTile = ResourceLoader.getResource('data/ui/game/specials/bubblebar.png', ResourceLoader.getImage, this.imageResources).toTile();
		bubbleBarInfiniteTile = ResourceLoader.getResource('data/ui/game/specials/bubblebar-infinite.png', ResourceLoader.getImage, this.imageResources)
			.toTile();
		bubbleBarMeterBmp = new Bitmap(bubbleBarNormalTile, scene2d);
		bubbleBarMeterBmp.setScale(Settings.uiScale);
		bubbleBarMeterBmp.visible = false;

		var bubbleFontData = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var bubbleFontB = new BitmapFont(bubbleFontData.entry);
		@:privateAccess bubbleFontB.loader = ResourceLoader.loader;
		var bubbleFont = bubbleFontB.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);
		bubbleBarText = new h2d.Text(bubbleFont, scene2d);
		bubbleBarText.textColor = 0x000000;
		bubbleBarText.visible = false;
		bubbleBarText.textAlign = Center;
	}

	/** Ported from PQ's `PlayGui::updatePowerupTimerPos` (`client/scripts/playGui.cs`) - the bar
		tracks the marble's projected screen position every frame rather than sitting at a fixed HUD
		spot; `MarbleWorld` owns the actual world-to-screen projection (it has the camera/marble) and
		just passes the already-computed screen-space anchor point through here every frame. `x`/`y`
		are the *side* offset point PQ computes (`getPixelSpace(getGuiSpace(...))` of a point offset
		to the marble's side by its collision radius) plus PQ's own `+20`/`-38` pixel nudge, and
		`centerY` is the un-offset marble-center projection's Y (PQ reads `%y` from the *center*
		projection, not the side one, for its own Y before applying `-38`) - both already include
		that nudge by the time they reach here, so this method only needs to lay out the bar/text
		relative to that single anchor point. */
	public function setBubbleBarPosition(x:Float, y:Float) {
		if (bubbleBarMeterBmp == null)
			return;
		bubbleBarMeterBmp.x = x;
		bubbleBarMeterBmp.y = y;
		bubbleBarText.x = x + 24 * Settings.uiScale;
		bubbleBarText.y = y + 24 * Settings.uiScale;
		bubbleBarFillFlow.setPosition(x, y);
	}

	/** Ported from PQ's `PlayGui::updateBubbleBar` - fill width ranges from 50 (only just picked
		up/about to expire) to 133 (full). */
	public function updateBubbleBar(bubbleTime:Float, bubbleTotalTime:Float, bubbleInfinite:Bool) {
		if (bubbleBarMeterBmp == null)
			return;
		if (bubbleInfinite) {
			bubbleBarMeterBmp.visible = true;
			bubbleBarMeterBmp.tile = bubbleBarInfiniteTile;
			bubbleBarFillBmp.visible = false;
			bubbleBarText.visible = false;
		} else if (bubbleTime > 0) {
			bubbleBarMeterBmp.visible = true;
			bubbleBarMeterBmp.tile = bubbleBarNormalTile;
			bubbleBarFillBmp.visible = true;
			bubbleBarText.visible = true;
			var fraction = bubbleTotalTime > 0 ? bubbleTime / bubbleTotalTime : 0;
			bubbleBarFillFlow.maxWidth = Std.int((50 + 83 * fraction) * Settings.uiScale);
			var fmt = '${Math.fround(bubbleTime * 10) / 10}';
			if (fmt.indexOf('.') == -1)
				fmt += ".0"; // add decimal
			bubbleBarText.text = fmt;
		} else {
			bubbleBarMeterBmp.visible = false;
			bubbleBarFillBmp.visible = false;
			bubbleBarText.visible = false;
		}
	}

	function initPowerupBox() {
		powerupBox.position = new Vector(698, 6);
		powerupBox.extent = new Vector(97, 96);
		powerupBox.horizSizing = Left;

		playGuiCtrl.addChild(powerupBox);

		this.powerupImageScene = new h3d.scene.Scene();
		// var powerupImageRenderer = cast(this.powerupImageScene.renderer, h3d.scene.pbr.Renderer);
		// powerupImageRenderer.skyMode = Hide;

		powerupImageSceneTarget = new Texture(68, 67, [Target]);
		powerupImageSceneTarget.depthBuffer = new DepthBuffer(68, 67);

		powerupImageSceneTargetBitmap = new Bitmap(Tile.fromTexture(powerupImageSceneTarget), scene2d);
		powerupImageSceneTargetBitmap.x = scene2d.width - 88 * Settings.uiScale;
		powerupImageSceneTargetBitmap.y = 18 * Settings.uiScale;
		powerupImageSceneTargetBitmap.setScale(Settings.uiScale);
	}

	function initTexts() {
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var bfont = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		helpTextContainer = new GuiControl();
		helpTextContainer.position = new Vector(80, 600);
		helpTextContainer.extent = new Vector(640, 120);
		helpTextContainer.vertSizing = Top;
		helpTextContainer.horizSizing = Center;

		var borderTile = ResourceLoader.getResource('data/ui/game/help/round_border.png', ResourceLoader.getImage, this.imageResources).toTile();

		/**
			var tl = texture.sub(0, 1, 21, 23);
			var tr = texture.sub(22, 1, 20, 23);
			var top = texture.sub(43, 1, 19, 23);
			var left = texture.sub(63, 1, 21, 23);
			var right = texture.sub(0, 25, 21, 24);
			var bl = texture.sub(22, 25, 20, 24);
			var bottom = texture.sub(43, 25, 19, 24);
			var br = texture.sub(63, 25, 21, 24);
		**/

		helpTextBorder = new GuiBitmapBorderCtrl(borderTile, 0x4f3d38, {
			tl: new Vector(0, 1, 21, 23),
			tr: new Vector(22, 1, 20, 23),
			bl: new Vector(22, 25, 20, 24),
			br: new Vector(63, 25, 21, 24),
			top: new Vector(43, 1, 19, 23),
			left: new Vector(63, 1, 21, 23),
			right: new Vector(0, 25, 21, 24),
			bottom: new Vector(43, 25, 19, 24)
		});
		helpTextBorder.horizSizing = Width;
		helpTextBorder.vertSizing = Height;
		helpTextBorder.position = new Vector(20, 20);
		helpTextBorder.extent = new Vector(600, 80);
		helpTextContainer.addChild(helpTextBorder);

		var helpTextInner = new GuiControl();
		helpTextInner.position = new Vector(35, 30);
		helpTextInner.extent = new Vector(550, 60);
		helpTextInner.horizSizing = Width;
		helpTextInner.vertSizing = Height;
		helpTextContainer.addChild(helpTextInner);

		helpTextBackground = new GuiText(bfont);
		helpTextBackground.text.textColor = 0x777777;
		helpTextBackground.position = new Vector(1, 3);
		helpTextBackground.extent = new Vector(550, 26);
		helpTextBackground.vertSizing = Height;
		helpTextBackground.horizSizing = Width;
		helpTextBackground.justify = Center;

		helpTextForeground = new GuiText(bfont);
		helpTextForeground.text.textColor = 0xFFFFFF;
		helpTextForeground.position = new Vector(0, 2);
		helpTextForeground.extent = new Vector(550, 26);
		helpTextForeground.vertSizing = Height;
		helpTextForeground.horizSizing = Width;
		helpTextForeground.justify = Center;

		var chatBubbleIconTile = ResourceLoader.getResource('data/ui/game/help/help_icon.png', ResourceLoader.getImage, this.imageResources).toTile();

		var chatBubbleIcon = new GuiImage(chatBubbleIconTile);
		chatBubbleIcon.position = new Vector(-25, -20);
		chatBubbleIcon.extent = new Vector(57, 57);

		helpTextInner.addChild(helpTextBackground);
		helpTextInner.addChild(helpTextForeground);
		helpTextContainer.addChild(chatBubbleIcon);

		// Ported from PQ's `<bold:23>` prefix on `addHelpLine`'s text - same underlying bitmap font
		// as `bfont` above, just a smaller target size for the toast notifications (`addHelpLine`/
		// `ToastMessage`, see their doc comments).
		toastMessageFont = domcasual32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		toastListBox = new GuiControl();
		toastListBox.horizSizing = Right;
		toastListBox.vertSizing = Height;
		toastListBox.position = new Vector(0, 70);
		toastListBox.extent = new Vector(500, 500);

		playGuiCtrl.addChild(helpTextContainer);
		playGuiCtrl.addChild(toastListBox);
	}

	function initFPSMeter() {
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var bfont = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var fpsMeterCtrl = new GuiImage(ResourceLoader.getResource("data/ui/game/transparency-fps.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		fpsMeterCtrl.position = new Vector(704, 568);
		fpsMeterCtrl.horizSizing = Left;
		fpsMeterCtrl.vertSizing = Top;
		fpsMeterCtrl.extent = new Vector(106, 32);

		fpsMeter = new GuiText(bfont);
		fpsMeter.horizSizing = Width;
		fpsMeter.vertSizing = Height;
		fpsMeter.position = new Vector(10, 3);
		fpsMeter.text.textColor = 0;
		fpsMeter.extent = new Vector(106, 32);
		fpsMeterCtrl.addChild(fpsMeter);

		playGuiCtrl.addChild(fpsMeterCtrl);
	}

	public function initChatHud() {
		this.chatCtrl = new ChatCtrl();
		this.chatCtrl.position = new Vector(playGuiCtrl.extent.x - 201, 150);
		this.chatCtrl.extent = new Vector(200, 250);
		this.chatCtrl.horizSizing = Left;
		this.playGuiCtrl.addChild(chatCtrl);
	}

	public inline function isChatFocused() {
		return this.chatCtrl?.chatFocused;
	}

	public inline function addChatMessage(str:String) {
		this.chatCtrl.addChatMessage(str);
	}

	function initBlastBar() {
		blastBar = new GuiControl();
		blastBar.position = new Vector(6, 445);
		blastBar.extent = new Vector(120, 28);
		blastBar.vertSizing = Top;
		this.playGuiCtrl.addChild(blastBar);

		blastFill = new GuiImage(ResourceLoader.getResource("data/ui/game/blastbar_bargreen.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFill.position = new Vector(5, 5);
		blastFill.extent = new Vector(58, 17);
		blastFill.doClipping = false;
		blastBar.addChild(blastFill);

		blastFrame = new GuiImage(ResourceLoader.getResource("data/ui/game/blastbar.png", ResourceLoader.getImage, this.imageResources).toTile());
		blastFrame.position = new Vector(0, 0);
		blastFrame.extent = new Vector(120, 28);
		blastBar.addChild(blastFrame);

		blastBarTile = ResourceLoader.getResource("data/ui/game/blastbar.png", ResourceLoader.getImage, this.imageResources).toTile();
		blastBarGreenTile = ResourceLoader.getResource("data/ui/game/blastbar_bargreen.png", ResourceLoader.getImage, this.imageResources).toTile();
		blastBarGrayTile = ResourceLoader.getResource("data/ui/game/blastbar_bargray.png", ResourceLoader.getImage, this.imageResources).toTile();
		blastBarChargedTile = ResourceLoader.getResource("data/ui/game/blastbar_charged.png", ResourceLoader.getImage, this.imageResources).toTile();
	}

	public function setBlastValue(value:Float) {
		if (Net.clientSpectate || Net.hostSpectate) {
			MarbleGame.instance.touchInput.blastbutton.setEnabled(true);
			return; // Is not changed
		}
		if (value <= 1) {
			if (blastFill.extent.y == 16) { // Was previously charged
				blastFrame.bmp.tile = blastBarTile;
			}
			var oldVal = blastFill.extent.x;
			blastFill.extent = new Vector(Util.lerp(0, 110, value), 17);
			if (oldVal < 22 && blastFill.extent.x >= 22) {
				blastFill.bmp.tile = blastBarGreenTile;
				MarbleGame.instance.touchInput.blastbutton.setEnabled(true);
			}
			if (oldVal >= 22 && blastFill.extent.x < 22) {
				blastFill.bmp.tile = blastBarGrayTile;
				MarbleGame.instance.touchInput.blastbutton.setEnabled(false);
			}
		} else {
			blastFill.extent = new Vector(0, 16); // WE will just use this extra number to store whether it was previously charged or not
			blastFrame.bmp.tile = blastBarChargedTile;
			MarbleGame.instance.touchInput.blastbutton.setEnabled(true);
		}
		this.blastBar.render(scene2d);
	}

	function initPlayerList() {
		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var bfont = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		playerListContainer = new GuiControl();
		playerListContainer.horizSizing = Right;
		playerListContainer.vertSizing = Height;
		playerListContainer.position = new Vector(20, 100);
		playerListContainer.extent = new Vector(380, 380);
		this.playGuiCtrl.addChild(playerListContainer);

		var imgLoader = (s:String) -> {
			var t = switch (s) {
				case "high":
					ResourceLoader.getResource("data/ui/mp/play/connection-high.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "medium":
					ResourceLoader.getResource("data/ui/mp/play/connection-medium.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "low":
					ResourceLoader.getResource("data/ui/mp/play/connection-low.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "matanny":
					ResourceLoader.getResource("data/ui/mp/play/connection-matanny.png", ResourceLoader.getImage, this.imageResources).toTile();
				case "unknown":
					ResourceLoader.getResource("data/ui/mp/play/connection-unknown.png", ResourceLoader.getImage, this.imageResources).toTile();
				default:
					null;
			};
			if (t != null)
				t.scaleToSize(t.width * (Settings.uiScale), t.height * (Settings.uiScale));
			return t;
		}

		playerListCtrl = new GuiMLTextListCtrl(bfont, [], imgLoader, {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			color: 0,
			alpha: 1
		});

		playerListCtrl.position = new Vector(33, 3);
		playerListCtrl.extent = new Vector(210, 271);
		playerListCtrl.scrollable = true;
		playerListCtrl.onSelectedFunc = (sel) -> {}
		playerListContainer.addChild(playerListCtrl);

		playerListScoresCtrl = new GuiMLTextListCtrl(bfont, [], imgLoader, {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			color: 0,
			alpha: 1
		});

		playerListScoresCtrl.position = new Vector(233, 3);
		playerListScoresCtrl.extent = new Vector(280, 271);
		playerListScoresCtrl.scrollable = true;
		playerListScoresCtrl.onSelectedFunc = (sel) -> {}
		playerListContainer.addChild(playerListScoresCtrl);
	}

	public function redrawPlayerList() {
		var pl = [];
		var plScores = [];
		var col0 = "#CFB52B";
		var col1 = "#CDCDCD";
		var col2 = "#D19275";
		var col3 = "#FFEE99";
		var prevLead = playerList[0].us;
		playerList.sort((a, b) -> a.score > b.score ? -1 : (a.score < b.score ? 1 : 0));
		for (i in 0...playerList.length) {
			var item = playerList[i];
			var color = switch (i) {
				case 0:
					col0;
				case 1:
					col1;
				case 2:
					col2;
				default:
					col3;
			};
			var isSpectating = false;
			if (item.us) {
				if (Net.isHost)
					isSpectating = Net.hostSpectate;
				if (Net.isClient)
					isSpectating = Net.clientSpectate;
			} else {
				isSpectating = Net.clientIdMap[item.id].spectator;
			}
			pl.push('<font color="${color}">${i + 1}. ${isSpectating ? "[S] " : ""}${Util.rightPad(StringTools.htmlEscape(item.name), 25, 3)}</font>');
			var connPing = item.us ? (Net.isHost ? 0 : Net.clientConnection.pingTicks) : (item.id == 0 ? 0 : Net.clientIdMap[item.id].pingTicks);
			var pingStatus = "unknown";
			if (connPing <= 5)
				pingStatus = "high";
			else if (connPing <= 8)
				pingStatus = "medium";
			else if (connPing <= 16)
				pingStatus = "low";
			else if (connPing < 32)
				pingStatus = "matanny";
			plScores.push('<font color="${color}">${item.score}</font><offset value="${50 * Settings.uiScale}"><img src="${pingStatus}"></img></offset>');
		}
		playerListCtrl.setTexts(pl);
		playerListScoresCtrl.setTexts(plScores);

		if ((playerList[0].us && !prevLead)) {
			gemCountNumbers[0].anim.currentFrame += 10;
			gemCountNumbers[1].anim.currentFrame += 10;
			gemCountNumbers[2].anim.currentFrame += 10;
		}
		if (prevLead && !playerList[0].us) {
			gemCountNumbers[0].anim.currentFrame -= 10;
			gemCountNumbers[1].anim.currentFrame -= 10;
			gemCountNumbers[2].anim.currentFrame -= 10;
		}
	}

	public function addPlayer(id:Int, name:String, us:Bool) {
		if (playerListCtrl != null) {
			playerList.push({
				id: id,
				name: name,
				us: us,
				score: 0,
				r: 0,
				y: 0,
				b: 0,
				p: 0
			});
			redrawPlayerList();
		}
	}

	public function removePlayer(id:Int) {
		if (playerListCtrl != null) {
			var f = playerList.filter(x -> x.id == id);
			if (f.length != 0)
				playerList.remove(f[0]);
			redrawPlayerList();
		}
	}

	public function incrementPlayerScore(id:Int, score:Int) {
		var f = playerList.filter(x -> x.id == id);
		if (f.length != 0) {
			f[0].score += score;
			if (score == 1) {
				f[0].r += 1;
			}
			if (score == 2) {
				f[0].y += 1;
			}
			if (score == 5) {
				f[0].b += 1;
			}
			if (score == 10) {
				f[0].p += 1;
			}
			if (f[0].us && Net.isClient) {
				@:privateAccess formatGemHuntCounter(f[0].score);
			}
		}

		if (id == Net.clientId) {
			if (Net.isClient)
				AudioManager.playPitchedSound("gotDiamond", this.soundResources);
		} else if (Net.isClient)
			AudioManager.playSound(ResourceLoader.getResource('data/sound/opponentdiamond.wav', ResourceLoader.getAudio, this.soundResources));

		redrawPlayerList();
	}

	public function updatePlayerScores(scoreboardPacket:ScoreboardPacket) {
		for (player in playerList) {
			player.score = scoreboardPacket.scoreBoard.exists(player.id) ? scoreboardPacket.scoreBoard.get(player.id) : 0;
			player.r = scoreboardPacket.rBoard.exists(player.id) ? scoreboardPacket.rBoard.get(player.id) : 0;
			player.y = scoreboardPacket.yBoard.exists(player.id) ? scoreboardPacket.yBoard.get(player.id) : 0;
			player.b = scoreboardPacket.bBoard.exists(player.id) ? scoreboardPacket.bBoard.get(player.id) : 0;
			player.p = scoreboardPacket.pBoard.exists(player.id) ? scoreboardPacket.pBoard.get(player.id) : 0;
		}
		redrawPlayerList();
	}

	public function resetPlayerScores() {
		for (player in playerList) {
			player.score = 0;
			player.r = 0;
			player.y = 0;
			player.b = 0;
			player.p = 0;
		}

		redrawPlayerList();
	}

	public function initSpectatorMenu() {
		spectatorCtrl = new GuiControl();
		spectatorCtrl.vertSizing = Top;
		spectatorCtrl.position = new Vector(0, 330);
		spectatorCtrl.extent = new Vector(302, 150);

		var specWnd = new GuiImage(ResourceLoader.getResource("data/ui/mp/play/spectator.png", ResourceLoader.getImage, this.imageResources).toTile());
		specWnd.horizSizing = Width;
		specWnd.vertSizing = Top;
		specWnd.position = new Vector(0, 0);
		specWnd.extent = new Vector(302, 150);

		spectatorCtrl.addChild(specWnd);

		var domcasual24fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual24b = new BitmapFont(domcasual24fontdata.entry);
		@:privateAccess domcasual24b.loader = ResourceLoader.loader;
		var domcasual24 = domcasual24b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		var domcasual32 = domcasual24b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var arialb14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arialb14b = new BitmapFont(arialb14fontdata.entry);
		@:privateAccess arialb14b.loader = ResourceLoader.loader;
		var arialBold14 = arialb14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);
		var markerFelt20 = markerFelt32b.toSdfFont(cast 18.5 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 17 * Settings.uiScale, MultiChannel);
		var markerFelt26 = markerFelt32b.toSdfFont(cast 22 * Settings.uiScale, MultiChannel);

		function mlFontLoader(text:String) {
			switch (text) {
				case "DomCasual24":
					return domcasual24;
				case "Arial14":
					return arial14;
				case "ArialBold14":
					return arialBold14;
				case "MarkerFelt32":
					return markerFelt32;
				case "MarkerFelt24":
					return markerFelt24;
				case "MarkerFelt18":
					return markerFelt18;
				case "MarkerFelt20":
					return markerFelt20;
				case "MarkerFelt26":
					return markerFelt26;
				default:
					return null;
			}
		}

		spectatorTxt = new GuiMLText(markerFelt24, mlFontLoader);
		spectatorTxt.position = new Vector(6, 9);
		spectatorTxt.extent = new Vector(282, 14);
		spectatorTxt.text.textColor = 0x000000;

		specWnd.addChild(spectatorTxt);
		playGuiCtrl.addChild(spectatorCtrl);
	}

	public function setSpectateMenu(enabled:Bool) {
		if (enabled && spectatorCtrl == null) {
			initSpectatorMenu();
			spectatorCtrl.render(MarbleGame.canvas.scene2d);
			blastFill.bmp.visible = false;
			blastFrame.bmp.visible = false;
			return true;
		}
		if (!enabled && spectatorCtrl != null) {
			spectatorCtrl.dispose();
			spectatorCtrl = null;
			blastFill.bmp.visible = true;
			blastFrame.bmp.visible = true;
			spectatorTxtMode = -1;
			return true;
		}
		return false;
	}

	public function setSpectateMenuText(mode:Int) {
		if (spectatorTxtMode != mode) {
			if (mode == 0) {
				spectatorTxt.text.text = '<p align="center"><font face="MarkerFelt32">Spectator Info</font></p>
					<font face="MarkerFelt24">Toggle Fly / Orbit: ${Util.getKeyForButton2(Settings.controlsSettings.blast)}</font>';
			}
			if (mode == 1) {
				spectatorTxt.text.text = '<p align="center"><font face="MarkerFelt32">Spectator Info</font></p>
					<font face="MarkerFelt24">Toggle Fly / Orbit: ${Util.getKeyForButton2(Settings.controlsSettings.blast)}
					<br/>Prev Player: ${Util.getKeyForButton2(Settings.controlsSettings.left)}
					<br/>Next Player: ${Util.getKeyForButton2(Settings.controlsSettings.right)}</font>';
			}

			spectatorTxtMode = mode;
		}
	}

	public function setHelpText(currentTime:Float, text:String, duration:Float) {
		if (this.helpTextStartTime + this.helpTextDuration < currentTime) {
			this.helpTextStartTime = currentTime;
			this.helpTextDuration = duration;
		} else if (this.helpTextStartTime < currentTime && this.helpTextStartTime + this.helpTextDuration > currentTime) {
			// extend the duration
			var diff = currentTime - this.helpTextStartTime;
			this.helpTextDuration = diff + duration;
		} else {
			this.helpTextStartTime = currentTime;
			this.helpTextDuration = duration;
		}

		this.helpTextForeground.text.text = text;
		this.helpTextBackground.text.text = text;
		// helpTextBackground.render(scene2d);
		// helpTextForeground.x = scene2d.width / 2 - helpTextForeground.textWidth / 2;
		// helpTextForeground.y = scene2d.height * 0.45;
		// helpTextBackground.x = scene2d.width / 2 - helpTextBackground.textWidth / 2 + 1;
		// helpTextBackground.y = scene2d.height * 0.45 + 1;
	}

	/** Ported from PQ's `PlayGui::lockPowerup` (`client/scripts/playGui.cs`) - swaps the powerup
		HUD frame to a "locked" graphic whenever the held powerup can't currently be used (e.g.
		frozen by an ice shard - see `Marble.freeze`). */
	public function lockPowerup(locked:Bool) {
		this.powerupBox.setTile(locked ? this.powerupLockedTile : this.powerupUnlockedTile);
	}

	public function setPowerupImage(?dtsPath:String) {
		this.powerupImageScene.removeChildren();
		if (dtsPath != null && dtsPath != "") {
			powerupImageObject = new DtsObject();
			powerupImageObject.dtsPath = dtsPath;
		} else {
			this.powerupImageObject = null;
		}

		if (powerupImageObject != null) {
			powerupImageObject.ambientRotate = true;
			powerupImageObject.ambientSpinFactor /= 2;
			powerupImageObject.showSequences = false;
			powerupImageObject.init(null, () -> {
				for (mat in powerupImageObject.materials) {
					mat.mainPass.enableLights = false;
					if (mat.blendMode != Alpha && mat.blendMode != Add)
						mat.mainPass.addShader(new h3d.shader.AlphaChannel());
				}
				powerupImageScene.addChild(powerupImageObject);
				var powerupImageCenter = powerupImageObject.getBounds().getCenter();

				powerupImageScene.camera.pos = new Vector(0, 4, powerupImageCenter.z);
				powerupImageScene.camera.target = new Vector(powerupImageCenter.x, powerupImageCenter.y, powerupImageCenter.z);
			});
		}
	}

	public function formatGemCounter(collected:Int, total:Int) {
		if (MarbleGame.instance.world.isMultiplayer)
			return;
		if (total == 0) {
			for (number in gemCountNumbers) {
				number.anim.visible = false;
			}
			gemCountSlash.bmp.visible = false;
			gemImageSceneTargetBitmap.visible = false;
		} else {
			for (number in gemCountNumbers) {
				number.anim.visible = true;
			}
			gemCountSlash.bmp.visible = true;
			gemImageSceneTargetBitmap.visible = true;
		}

		var totalHundredths = Math.floor(total / 100);
		var totalTenths = Math.floor(total / 10) % 10;
		var totalOnes = total % 10;

		var collectedHundredths = Math.floor(collected / 100);
		var collectedTenths = Math.floor(collected / 10) % 10;
		var collectedOnes = collected % 10;

		gemCountNumbers[0].anim.currentFrame = collectedHundredths;
		gemCountNumbers[1].anim.currentFrame = collectedTenths;
		gemCountNumbers[2].anim.currentFrame = collectedOnes;
		gemCountNumbers[3].anim.currentFrame = totalHundredths;
		gemCountNumbers[4].anim.currentFrame = totalTenths;
		gemCountNumbers[5].anim.currentFrame = totalOnes;

		if (collected >= total) {
			gemCountNumbers[0].anim.color = Vector.fromColor(timerStopped);
			gemCountNumbers[1].anim.color = Vector.fromColor(timerStopped);
			gemCountNumbers[2].anim.color = Vector.fromColor(timerStopped);
			gemCountNumbers[3].anim.color = Vector.fromColor(timerStopped);
			gemCountNumbers[4].anim.color = Vector.fromColor(timerStopped);
			gemCountNumbers[5].anim.color = Vector.fromColor(timerStopped);
			gemCountSlash.bmp.color = Vector.fromColor(timerStopped);
		} else {
			gemCountNumbers[0].anim.color = Vector.fromColor(timerNormal);
			gemCountNumbers[1].anim.color = Vector.fromColor(timerNormal);
			gemCountNumbers[2].anim.color = Vector.fromColor(timerNormal);
			gemCountNumbers[3].anim.color = Vector.fromColor(timerNormal);
			gemCountNumbers[4].anim.color = Vector.fromColor(timerNormal);
			gemCountNumbers[5].anim.color = Vector.fromColor(timerNormal);
			gemCountSlash.bmp.color = Vector.fromColor(timerNormal);
		}
	}

	public function formatGemHuntCounter(collected:Int) {
		var collectedHundredths = Math.floor(collected / 100);
		var collectedTenths = Math.floor(collected / 10) % 10;
		var collectedOnes = collected % 10;

		if (collected >= 100)
			gemCountNumbers[0].anim.visible = true;
		else
			gemCountNumbers[0].anim.visible = false;
		if (collected >= 10)
			gemCountNumbers[1].anim.visible = true;
		else
			gemCountNumbers[1].anim.visible = false;
		gemCountNumbers[2].anim.visible = true;
		gemCountNumbers[3].anim.visible = false;
		gemCountNumbers[4].anim.visible = false;
		gemCountNumbers[5].anim.visible = false;

		gemCountNumbers[0].anim.currentFrame = collectedHundredths;
		gemCountNumbers[1].anim.currentFrame = collectedTenths;
		gemCountNumbers[2].anim.currentFrame = collectedOnes;
		gemCountSlash.bmp.visible = false;
		gemImageSceneTargetBitmap.visible = true;
		gemCountNumbers[0].anim.color = Vector.fromColor(timerNormal);
		gemCountNumbers[1].anim.color = Vector.fromColor(timerNormal);
		gemCountNumbers[2].anim.color = Vector.fromColor(timerNormal);
	}

	public function formatTimer(time:Float, color:Int = 0xFFFFFFFF) {
		var et = time * 1000;
		var thousandth = et % 10;
		var hundredth = Math.floor((et % 1000) / 10);
		var totalSeconds = Math.floor(et / 1000);
		var seconds = totalSeconds % 60;
		var minutes = (totalSeconds - seconds) / 60;

		var secondsOne = seconds % 10;
		var secondsTen = (seconds - secondsOne) / 10;
		var minutesOne = minutes % 10;
		var minutesTen = ((minutes - minutesOne) / 10) % 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		timerNumbers[0].anim.color = Vector.fromColor(color);
		timerNumbers[1].anim.color = Vector.fromColor(color);
		timerNumbers[2].anim.color = Vector.fromColor(color);
		timerNumbers[3].anim.color = Vector.fromColor(color);
		timerNumbers[4].anim.color = Vector.fromColor(color);
		timerNumbers[5].anim.color = Vector.fromColor(color);
		timerNumbers[6].anim.color = Vector.fromColor(color);
		timerNumbers[0].anim.currentFrame = minutesTen;
		timerNumbers[1].anim.currentFrame = minutesOne;
		timerNumbers[2].anim.currentFrame = secondsTen;
		timerNumbers[3].anim.currentFrame = secondsOne;
		timerNumbers[4].anim.currentFrame = hundredthTen;
		timerNumbers[5].anim.currentFrame = hundredthOne;
		timerNumbers[6].anim.currentFrame = thousandth;

		timerColon.anim.color = Vector.fromColor(color);
		timerPoint.anim.color = Vector.fromColor(color);
	}

	public function formatCountdownTimer(time:Float, color:Int = 0xFFFFFFFF) {
		if (time == 0) {
			countdownNumbers[0].anim.visible = false;
			countdownNumbers[1].anim.visible = false;
			countdownNumbers[2].anim.visible = false;
			countdownPoint.anim.visible = false;
			countdownIcon.bmp.visible = false;
		} else {
			countdownNumbers[0].anim.visible = true;
			countdownNumbers[1].anim.visible = true;
			countdownNumbers[2].anim.visible = true;
			countdownPoint.anim.visible = true;
			countdownIcon.bmp.visible = true;
		}

		var et = time * 1000;
		var hundredth = Math.floor((et % 1000) / 10);
		var totalSeconds = Math.floor(et / 1000);
		var seconds = totalSeconds % 60;

		var secondsOne = seconds % 10;
		var secondsTen = (seconds - secondsOne) / 10;
		var hundredthOne = hundredth % 10;
		var hundredthTen = (hundredth - hundredthOne) / 10;

		if (secondsTen > 0) {
			countdownNumbers[0].anim.visible = true;
			countdownNumbers[0].anim.currentFrame = secondsTen;
		} else {
			countdownNumbers[0].anim.visible = false;
		}

		countdownNumbers[1].anim.currentFrame = secondsOne;
		countdownNumbers[2].anim.currentFrame = hundredthTen;

		countdownNumbers[0].anim.color = Vector.fromColor(color);
		countdownNumbers[1].anim.color = Vector.fromColor(color);
		countdownNumbers[2].anim.color = Vector.fromColor(color);

		countdownPoint.anim.currentFrame = color;
	}

	public function render(engine:h3d.Engine) {
		engine.pushTarget(this.gemImageSceneTarget);

		engine.clear(0, 1);
		this.gemImageScene.render(engine);

		engine.popTarget();
		engine.pushTarget(this.powerupImageSceneTarget);

		engine.clear(0, 1);
		this.powerupImageScene.render(engine);

		engine.popTarget();
	}

	public function update(timeState:TimeState) {
		this.gemImageObject.update(timeState);
		this.gemImageScene.setElapsedTime(timeState.dt);
		if (this.powerupImageObject != null)
			this.powerupImageObject.update(timeState);
		this.powerupImageScene.setElapsedTime(timeState.dt);

		if (this.fpsMeter != null) {
			this.fpsMeter.text.text = '${Math.floor(ProfilerUI.instance.fps)} FPS';
		}
		this.updateMiddleMessages(timeState.dt);
		if (Net.isMP) {
			this.chatCtrl.updateChat(timeState.dt);
		}
		this.updateHelpMessage(timeState);
		this.updateToastMessages(timeState.dt);
	}

	function updateHelpMessage(timeState:TimeState) {
		if (timeState.timeSinceLoad < this.helpTextStartTime + this.helpTextDuration) {
			var pct = 1.0;
			if (this.helpTextStartTime + 0.48 > timeState.timeSinceLoad)
				pct = 1 - (this.helpTextStartTime + 0.48 - timeState.timeSinceLoad) / 0.48;
			else if (timeState.timeSinceLoad > this.helpTextStartTime + this.helpTextDuration - 0.48) {
				pct = 1 - (timeState.timeSinceLoad - (this.helpTextStartTime + this.helpTextDuration - 0.48)) / 0.48;
			}

			this.helpTextContainer.position = new Vector(120, 620 - pct * (95 + 20));
			this.helpTextContainer.render(scene2d, @:privateAccess playGuiCtrl._flow);
			@:privateAccess helpTextContainer._flow.overflow = Expand;
		}
	}

	function updateMiddleMessages(dt:Float) {
		var itermessages = this.middleMessages.copy();
		if (itermessages.length > 0) {
			var thismsg = itermessages.shift();
			thismsg.age += dt;
			if (thismsg.age > 0.6) {
				this.middleMessages.remove(thismsg);
				thismsg.ctrl.parent.removeChild(thismsg.ctrl); // Delete it
			} else {
				if (thismsg.age >= 0.3) {
					thismsg.ctrl.text.alpha = 1 - (thismsg.age - 0.3) / 0.3;
				}
				thismsg.ctrl.text.y -= (0.1 / playGuiCtrl.extent.y) * scene2d.height;
			}
		}
	}

	public function addMiddleMessage(text:String, color:Int) {
		if (this.middleMessages.length > 10)
			return;
		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var middleMsg = new GuiText(markerFelt32);
		middleMsg.position = new Vector(200, 50);
		middleMsg.extent = new Vector(400, 100);
		middleMsg.horizSizing = Center;
		middleMsg.vertSizing = Center;
		middleMsg.text.text = text;
		middleMsg.justify = Center;
		middleMsg.text.textColor = color;
		middleMsg.text.dropShadow = {
			dx: 1 * Settings.uiScale,
			dy: 1 * Settings.uiScale,
			alpha: 0.5,
			color: 0
		}; // new h2d.filter.DropShadow(1.414, 0.785, 0x000000F, 1, 0, 0.4, 1, true);
		this.playGuiCtrl.addChild(middleMsg);
		middleMsg.render(scene2d);
		middleMsg.text.y -= (25 / playGuiCtrl.extent.y) * scene2d.height;

		this.middleMessages.push({ctrl: middleMsg, age: 0});
	}

	/** Ported from `chathud.cs`'s `createHelpMessage`/`addHelpLine` (`$ChatHudMessageId`'s per-
		message box) - a toast slides in from off the right edge of the screen, waits `timeout`
		seconds, then slides back out and is removed, and each new arrival pushes every
		already-active toast further up the stack (`shiftMessages`). Built from the exact same
		`GuiControl`/`GuiBitmapBorderCtrl`/`GuiMLText` structure and field values (position/extent/
		horizSizing/vertSizing) as `createHelpMessage` itself - see `ToastMessage`'s doc comment for
		why (this sidesteps re-deriving Torque's anchor-sizing math by hand, since `GuiControl`
		already implements it correctly). The one real behavioral difference: this animates by
		mutating `box.position` and calling `render()` again every frame (see
		`PlayGui.updateToastMessages`) instead of Torque's native `setPosition`/scheduled callbacks -
		same visual result, different mechanism, since this engine's `GuiControl` has no animation
		system of its own to hook into.

		Faithfully reproduces one real quirk rather than "fixing" it: when the *oldest* (topmost)
		toast finishes retreating and is removed, the remaining toasts do NOT shift back down to
		fill the gap - `shiftMessages` in real source only ever runs when a NEW message arrives,
		never on removal, so a permanent gap is a real, reproducible artifact of this system. */
	public function addHelpLine(message:String, timeout:Float = 4.0) {
		if (message == null || message.length == 0)
			return;
		if (this.toastListBox == null)
			return;

		var width = ToastMessage.WIDTH;

		var box = new GuiControl();
		box.horizSizing = Right;
		box.vertSizing = Top;
		box.position = new Vector(-width, this.toastListBox.extent.y);
		box.extent = new Vector(width, ToastMessage.DEFAULT_HEIGHT);

		var borderTile = ResourceLoader.getResource('data/ui/game/help/round_border_thin.png', ResourceLoader.getImage, this.imageResources).toTile();
		var border = new GuiBitmapBorderCtrl(borderTile, 0x4f3d38, {
			tl: new Vector(0, 1, 21, 23),
			tr: new Vector(22, 1, 21, 23),
			bl: new Vector(22, 25, 21, 23),
			br: new Vector(64, 25, 21, 23),
			top: new Vector(44, 1, 19, 23),
			left: new Vector(64, 1, 21, 23),
			right: new Vector(0, 25, 21, 23),
			bottom: new Vector(44, 25, 19, 23)
		});
		border.horizSizing = Width;
		border.vertSizing = Height;
		border.position = new Vector(0, 0);
		border.extent = new Vector(width, ToastMessage.DEFAULT_HEIGHT);
		box.addChild(border);

		var inner = new GuiControl();
		inner.horizSizing = Width;
		inner.vertSizing = Height;
		inner.position = new Vector(6, 12);
		inner.extent = new Vector(width - 6, 46);
		box.addChild(inner);

		var bg = new GuiMLText(this.toastMessageFont, s -> null);
		bg.horizSizing = Right;
		bg.vertSizing = Bottom;
		bg.position = new Vector(1, 1);
		bg.extent = new Vector(width - 24, 46);
		bg.text.textColor = 0x777777;
		bg.text.text = message;
		inner.addChild(bg);

		var fg = new GuiMLText(this.toastMessageFont, s -> null);
		fg.horizSizing = Right;
		fg.vertSizing = Bottom;
		fg.position = new Vector(0, 0);
		fg.extent = new Vector(width - 24, 46);
		fg.text.textColor = 0xFFFFFF;
		fg.text.text = message;
		inner.addChild(fg);

		this.toastListBox.addChild(box);
		// Initial render lays out the actual (possibly wrapped) text so its real height can be
		// measured - matches `if (%foregroundName.isAwake()) %foregroundName.forceReflow();`.
		box.render(scene2d, @:privateAccess this.toastListBox._flow);

		// Update the size of the box (`%boxName.setExtent(VectorAdd(%foregroundName.getExtent(),
		// "24 24"))`) - `fg.text.textHeight` is in scaled screen pixels, convert back to
		// reference-canvas units first. Only the BOX's own extent is touched here, exactly like
		// real source - `border`/`inner`/`bg`/`fg` all keep their original `horizSizing="width"`/
		// `vertSizing="height"` declared extents (70/46) and are expected to track the resized
		// parent automatically through that sizing mode, the same as real source relies on without
		// ever touching their extents again either.
		var textHeight = fg.text.textHeight / Settings.uiScale;
		// box.extent.y = textHeight + 24;

		var msg = new ToastMessage();
		msg.box = box;
		msg.border = border;
		msg.fg = fg;
		msg.direction = 1;
		msg.x = -width;
		msg.height = box.extent.y + ToastMessage.SPACING;
		msg.y = this.toastListBox.extent.y;
		// Matches real source's own `shiftMessages` call running over EVERY box including the one
		// just added - rather than adding this message to the list first and then looping over
		// everything (itself included), its own post-shift resting position is computed directly
		// here, and the loop below only needs to handle the *other*, already-existing messages.
		msg.targetY = msg.y - msg.height;
		msg.targetX = 0;
		msg.timeout = timeout;

		for (existing in this.toastMessages)
			existing.targetY -= msg.height;

		this.toastMessages.push(msg);
		this.repositionToast(msg);
	}

	function repositionToast(msg:ToastMessage) {
		msg.box.position.x = msg.x;
		msg.box.position.y = msg.y;
		msg.box.render(scene2d, @:privateAccess this.toastListBox._flow);
	}

	/** Ported from `updateMessages` - per-frame position/lifetime update for every active toast
		(see `addHelpLine`'s doc comment). */
	function updateToastMessages(dt:Float) {
		var i = 0;
		while (i < this.toastMessages.length) {
			var msg = this.toastMessages[i];
			msg.age += dt;
			if (!msg.retreating && msg.age >= msg.timeout) {
				msg.retreating = true;
				msg.direction = -1;
				msg.targetX = -ToastMessage.WIDTH;
			}

			var moved = false;
			if (msg.x != msg.targetX) {
				var speed = msg.direction > 0 ? ToastMessage.X_SPEED_IN : ToastMessage.X_SPEED_OUT;
				msg.x += speed * dt * msg.direction;
				if ((msg.x - msg.targetX) * msg.direction > 0)
					msg.x = msg.targetX;
				moved = true;
			} else if (msg.direction < 0) {
				// Fully retreated - remove (matches `onNextFrame(delete)`, just immediate since
				// there's no other work happening this same frame that removing it early could
				// interfere with).
				msg.box.dispose();
				this.toastMessages.splice(i, 1);
				continue;
			}

			if (msg.y != msg.targetY) {
				msg.y -= ToastMessage.Y_SPEED * dt;
				if (msg.y < msg.targetY)
					msg.y = msg.targetY;
				moved = true;
			}

			if (moved)
				this.repositionToast(msg);
			i++;
		}
	}
}
