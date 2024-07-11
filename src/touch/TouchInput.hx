package touch;

import gui.GuiControl;
import src.MarbleWorld;
import h3d.Vector;
import src.Settings;
import src.MarbleGame;
import src.ResourceLoader;

enum TouchState {
	Pressed;
	Move;
	Release;
}

class Touch {
	public var state:TouchState;
	public var position:Vector;
	public var deltaPosition:Vector;
	public var identifier:Int;

	public function new(state:TouchState, position:Vector, deltaPos:Vector, id:Int) {
		this.state = state;
		this.position = position;
		this.deltaPosition = deltaPos;
		this.identifier = id;
	}
}

class TouchEventState {
	public var changedTouches:Array<Touch>;

	public function new() {
		this.changedTouches = [];
	}
}

class TouchInput {
	var cameraInput:CameraInput;

	public var movementInput:MovementInput;

	public var jumpButton:JumpButton;
	public var powerupButton:PowerupButton;
	public var blastbutton:BlastButton;
	public var pauseButton:PauseButton;
	public var rewindButton:RewindButton;
	public var restartButton:RestartButton;
	public var leftButton:SpectatorChangeTargetButton;
	public var rightButton:SpectatorChangeTargetButton;

	public var currentTouchState:TouchEventState;

	public var previousTouchState:TouchEventState;

	var touches:Map<Int, Touch> = [];

	public function new() {
		this.cameraInput = new CameraInput();
		this.movementInput = new MovementInput();
		this.jumpButton = new JumpButton();
		this.powerupButton = new PowerupButton();
		this.blastbutton = new BlastButton();
		this.pauseButton = new PauseButton();
		this.rewindButton = new RewindButton();
		this.restartButton = new RestartButton();
		this.currentTouchState = new TouchEventState();
		this.previousTouchState = new TouchEventState();
	}

	// Registers the callbacks to the native stuff
	public function registerTouchInput() {
		#if js
		var pointercontainer = js.Browser.document.querySelector("#webgl");
		pointercontainer.addEventListener('touchstart', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var t = new Touch(Pressed, new Vector(touch.clientX, touch.clientY), new Vector(0, 0), touch.identifier);
				currentTouchState.changedTouches.push(t);
				touches.set(touch.identifier, t);
				// trace("Touch Start");
			}
		});
		pointercontainer.addEventListener('touchmove', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var prevt = touches.get(touch.identifier); // previousTouchState.changedTouches.filter(x -> x.identifier == touch.identifier);
				var prevDelta = new Vector(0, 0);
				if (prevt != null) {
					prevDelta = new Vector(touch.clientX, touch.clientY).sub(prevt.position);
				}
				var t = new Touch(Move, new Vector(touch.clientX, touch.clientY), prevDelta, touch.identifier);
				currentTouchState.changedTouches.push(t);
				touches.set(touch.identifier, t);
				// trace("Touch Move");
			}
		});
		pointercontainer.addEventListener('touchend', (e:js.html.TouchEvent) -> {
			for (touch in e.changedTouches) {
				var t = new Touch(Release, new Vector(touch.clientX, touch.clientY), new Vector(0, 0), touch.identifier);
				currentTouchState.changedTouches.push(t);
				touches.remove(touch.identifier);
				// trace("Touch End");
			}
		});
		#end
	}

	public function update() {
		previousTouchState = currentTouchState;
		currentTouchState = new TouchEventState();
	}

	public function showControls(parentGui:GuiControl, ultra:Bool) {
		jumpButton.dispose();
		powerupButton.dispose();
		if (ultra)
			blastbutton.dispose();
		movementInput.dispose();
		pauseButton.dispose();
		restartButton.dispose();
		cameraInput.dispose();
		this.cameraInput = new CameraInput();
		this.movementInput = new MovementInput();
		this.jumpButton = new JumpButton();
		this.powerupButton = new PowerupButton();
		if (Settings.optionsSettings.rewindEnabled && !MarbleGame.instance.world.isMultiplayer)
			this.rewindButton = new RewindButton();
		if (ultra)
			this.blastbutton = new BlastButton();
		this.pauseButton = new PauseButton();
		if (!MarbleGame.instance.world.isMultiplayer)
			this.restartButton = new RestartButton();
		pauseButton.add(parentGui);
		if (!MarbleGame.instance.world.isMultiplayer)
			restartButton.add(parentGui);
		jumpButton.add(parentGui);
		powerupButton.add(parentGui);
		if (Settings.optionsSettings.rewindEnabled && !MarbleGame.instance.world.isMultiplayer)
			rewindButton.add(parentGui);
		if (ultra)
			blastbutton.add(parentGui);
		movementInput.add(parentGui);
		cameraInput.add(parentGui);
		cameraInput.enabled = true;

		if (Settings.touchSettings.hideControls) {
			this.jumpButton.setVisible(false);
			this.powerupButton.setVisible(false);
			if (this.blastbutton != null)
				this.blastbutton.setVisible(false);
			this.movementInput.setVisible(false);
			this.pauseButton.setVisible(false);
			if (this.restartButton != null)
				this.restartButton.setVisible(false);
			if (this.rewindButton != null)
				this.rewindButton.setVisible(false);
			if (this.leftButton != null)
				this.leftButton.setVisible(false);
			if (this.rightButton != null)
				this.rightButton.setVisible(false);
		}
	}

	public function setControlsEnabled(enabled:Bool) {
		this.jumpButton.setVisible(enabled);
		this.powerupButton.setVisible(enabled);
		if (this.blastbutton != null)
			this.blastbutton.setVisible(enabled);
		this.movementInput.setVisible(enabled);
		this.pauseButton.setVisible(enabled);
		if (this.restartButton != null)
			this.restartButton.setVisible(enabled);
		if (this.rewindButton != null)
			this.rewindButton.setVisible(enabled);
		this.cameraInput.enabled = enabled;
		if (this.leftButton != null)
			this.leftButton.setVisible(enabled);
		if (this.rightButton != null)
			this.rightButton.setVisible(enabled);

		if (Settings.touchSettings.hideControls) {
			this.jumpButton.setVisible(false);
			this.powerupButton.setVisible(false);
			if (this.blastbutton != null)
				this.blastbutton.setVisible(false);
			this.movementInput.setVisible(false);
			if (this.rewindButton != null)
				this.rewindButton.setVisible(false);
			if (this.leftButton != null)
				this.leftButton.setVisible(false);
			if (this.rightButton != null)
				this.rightButton.setVisible(false);
		}
	}

	public function hideControls(parentGui:GuiControl) {
		jumpButton.remove(parentGui);
		powerupButton.remove(parentGui);
		if (this.blastbutton != null)
			blastbutton.remove(parentGui);
		movementInput.remove(parentGui);
		pauseButton.remove(parentGui);
		if (this.restartButton != null)
			restartButton.remove(parentGui);
		cameraInput.remove(parentGui);
		if (this.rewindButton != null)
			rewindButton.remove(parentGui);
		if (this.leftButton != null) {
			leftButton.remove(parentGui);
			leftButton.dispose();
		}
		if (this.rightButton != null) {
			rightButton.remove(parentGui);
			rightButton.dispose();
		}
		jumpButton.dispose();
		powerupButton.dispose();
		movementInput.dispose();
		pauseButton.dispose();
		restartButton.dispose();
		cameraInput.dispose();
		if (this.rewindButton != null)
			rewindButton.dispose();
	}

	public function setSpectatorControls(enabled:Bool) {
		var tile = ResourceLoader.getImage(enabled ? "data/ui/touch/video-camera.png" : "data/ui/touch/explosion.png").resource;
		@:privateAccess this.blastbutton.guiElement.graphics.content.state.tail.texture = tile.toTexture();
		if (enabled) {
			jumpButton.setVisible(false);
			if (this.leftButton == null) { // both are added at same time so it doesnt matter
				var par = jumpButton.guiElement.parent;
				this.leftButton = new SpectatorChangeTargetButton(false);
				this.rightButton = new SpectatorChangeTargetButton(true);
				this.leftButton.add(par);
				this.rightButton.add(par);
				this.leftButton.guiElement.render(MarbleGame.canvas.scene2d, @:privateAccess par._flow);
				this.rightButton.guiElement.render(MarbleGame.canvas.scene2d, @:privateAccess par._flow);
			}
		} else {
			jumpButton.setVisible(true);
			if (this.leftButton != null) {
				this.leftButton.remove(this.leftButton.guiElement.parent);
				this.leftButton.dispose();
				this.leftButton = null;
			}
			if (this.rightButton != null) {
				this.rightButton.remove(this.rightButton.guiElement.parent);
				this.rightButton.dispose();
				this.rightButton = null;
			}
		}
	}

	public function setSpectatorControlsVisibility(enabled:Bool) {
		if (this.leftButton != null) {
			this.leftButton.setVisible(enabled);
			this.rightButton.setVisible(enabled);
			this.movementInput.setVisible(!enabled);
		}
	}
}
