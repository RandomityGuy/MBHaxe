package gui;

import src.Gamepad;
import hxd.Key;
import h3d.Matrix;
import hxd.res.BitmapFont;
import gui.GuiControl.MouseState;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.AudioManager;

class GuiXboxOptionsList extends GuiControl {
	var bgFill:GuiAnim;
	var optIcon:GuiAnim;
	var leftButton:GuiAnim;
	var rightButton:GuiAnim;
	var labelText:GuiText;
	var optionText:GuiText;
	var options:Array<String>;
	var currentOption:Int = 0;
	var alwaysActive:Bool = false;

	var onChangeFunc:Int->Bool = null;

	var _prevMousePos:Vector;

	public var selected:Bool = false;

	public var list:GuiXboxOptionsListCollection;

	public function new(icon:Int, name:String, values:Array<String>, midcolumn:Float = 0.3, textOff = 155.5) {
		super();

		this.options = values;

		var baseImage = ResourceLoader.getResource("data/ui/xbox/optionsCursorArray.png", ResourceLoader.getImage, this.imageResources).toTile();
		var inactiveImage = baseImage.sub(0, 2, 815, 94);
		var activeImage = baseImage.sub(0, 98, 815, 94);
		var leftArrow = baseImage.sub(0, 193, 22, 22);
		var leftArrowSelected = baseImage.sub(23, 193, 22, 22);
		var rightArrow = baseImage.sub(48, 193, 22, 22);
		var rightArrowSelected = baseImage.sub(72, 193, 22, 22);
		var arrowButtonImage = baseImage.sub(0, 256, 114, 94);
		var arrowButtonImagePressed = baseImage.sub(0, 352, 114, 94);
		var iconImage = baseImage.sub(74 * icon, 453, 36, 36);
		var iconImagePressed = baseImage.sub(74 * icon + 37, 453, 36, 36);

		bgFill = new GuiAnim([inactiveImage, activeImage]);
		bgFill.position = new Vector(0, 0);
		bgFill.extent = new Vector(815, 94);
		this.addChild(bgFill);

		optIcon = new GuiAnim([iconImage, iconImagePressed]);
		optIcon.position = new Vector(30, 30);
		optIcon.extent = new Vector(36, 36);
		this.addChild(optIcon);

		var cmat = Matrix.I();
		cmat.colorGain(0x7F7F7F, 1);
		// cmat._44 = 1;
		var leftShadeFilter = new h2d.filter.ColorMatrix(cmat);
		leftShadeFilter.enable = false;
		var rightShadeFilter = new h2d.filter.ColorMatrix(cmat);
		rightShadeFilter.enable = false;

		leftButton = new GuiAnim([arrowButtonImage, arrowButtonImagePressed]);
		leftButton.position = new Vector(815 * midcolumn, 0);
		leftButton.extent = new Vector(114, 94);
		leftButton.anim.filter = leftShadeFilter;
		this.addChild(leftButton);

		var leftButtonIcon = new GuiAnim([leftArrow, leftArrowSelected]);
		leftButtonIcon.position = new Vector(39, 36);
		leftButtonIcon.extent = new Vector(22, 22);
		leftButton.addChild(leftButtonIcon);

		rightButton = new GuiAnim([arrowButtonImage, arrowButtonImagePressed]);
		rightButton.position = new Vector(815 * 0.8, 0);
		rightButton.extent = new Vector(114, 94);
		rightButton.anim.filter = rightShadeFilter;
		this.addChild(rightButton);

		var rightButtonIcon = new GuiAnim([rightArrow, rightArrowSelected]);
		rightButtonIcon.position = new Vector(52, 36);
		rightButtonIcon.extent = new Vector(22, 22);
		rightButton.addChild(rightButtonIcon);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 25 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		labelText = new GuiText(arial14);
		labelText.position = new Vector(815 * midcolumn - 125, 36);
		labelText.extent = new Vector(100, 35);
		labelText.vertSizing = Top;
		labelText.justify = Right;
		labelText.text.text = name;
		labelText.text.textColor = 0x787878;
		this.addChild(labelText);

		optionText = new GuiText(arial14);
		optionText.position = new Vector(815 * midcolumn + textOff, 36);
		optionText.extent = new Vector(815 * (0.8 - midcolumn) / 2, 35);
		optionText.vertSizing = Top;
		optionText.text.text = values[0];
		optionText.text.textColor = 0x787878;
		optionText.justify = Center;
		this.addChild(optionText);
	}

	override function update(dt:Float, mouseState:MouseState) {
		if (alwaysActive) {
			bgFill.anim.currentFrame = 1;
			optIcon.anim.currentFrame = 1;
			labelText.text.textColor = 0x101010;
			optionText.text.textColor = 0x101010;
		} else {
			var htr = this.getHitTestRect();
			htr.position = htr.position.add(new Vector(24, 20));
			htr.extent.set(776, 53);

			if (_prevMousePos == null || !_prevMousePos.equals(mouseState.position)) {
				if (htr.inRect(mouseState.position) && !selected) {
					this.selected = true;
					if (list != null) {
						list.options[list.selected].selected = false;
						list.selected = list.options.indexOf(this);
					}
				}
				// if (!htr.inRect(mouseState.position) && selected) {
				// 	this.selected = false;
				// }
				_prevMousePos = mouseState.position.clone();
			}

			if (selected) {
				bgFill.anim.currentFrame = 1;
				optIcon.anim.currentFrame = 1;
				labelText.text.textColor = 0x101010;
				optionText.text.textColor = 0x101010;
			} else {
				bgFill.anim.currentFrame = 0;
				optIcon.anim.currentFrame = 0;
				labelText.text.textColor = 0x787878;
				optionText.text.textColor = 0x787878;
			}
		}
		var leftBtnRect = leftButton.getHitTestRect();
		leftBtnRect.position = leftBtnRect.position.add(new Vector(15, 21));
		leftBtnRect.extent.set(83, 53);
		var rightBtnRect = rightButton.getHitTestRect();
		rightBtnRect.position = rightBtnRect.position.add(new Vector(15, 21));
		rightBtnRect.extent.set(83, 53);
		if (leftBtnRect.inRect(mouseState.position) || rightBtnRect.inRect(mouseState.position)) {
			if (Key.isPressed(Key.MOUSE_LEFT)) {
				AudioManager.playSound(ResourceLoader.getResource("data/sound/buttonpress.wav", ResourceLoader.getAudio, this.soundResources));
			}
		}
		// Left Button
		if (leftBtnRect.inRect(mouseState.position)) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				leftButton.anim.currentFrame = 1;
				leftButton.anim.filter.enable = true;
			} else {
				leftButton.anim.currentFrame = 1;
				leftButton.anim.filter.enable = false;
			}
			if (Key.isReleased(Key.MOUSE_LEFT)) {
				var newOption = currentOption - 1;
				if (newOption < 0)
					newOption = options.length - 1;

				var doChange = true;
				if (onChangeFunc != null)
					doChange = onChangeFunc(newOption);
				if (doChange) {
					currentOption = newOption;
					optionText.text.text = options[currentOption];
				}
			}
		} else {
			leftButton.anim.currentFrame = 0;
			leftButton.anim.filter.enable = false;
		}
		// Right Button
		if (rightBtnRect.inRect(mouseState.position)) {
			if (Key.isDown(Key.MOUSE_LEFT)) {
				rightButton.anim.currentFrame = 1;
				rightButton.anim.filter.enable = true;
			} else {
				rightButton.anim.currentFrame = 1;
				rightButton.anim.filter.enable = false;
			}
			if (Key.isReleased(Key.MOUSE_LEFT)) {
				var newOption = currentOption + 1;
				if (newOption >= options.length)
					newOption = 0;

				var doChange = true;
				if (onChangeFunc != null)
					doChange = onChangeFunc(newOption);
				if (doChange) {
					currentOption = newOption;
					optionText.text.text = options[currentOption];
				}
			}
		} else {
			rightButton.anim.currentFrame = 0;
			rightButton.anim.filter.enable = false;
		}
		if (selected || alwaysActive) {
			if (Key.isPressed(Key.LEFT) || Gamepad.isPressed(['dpadLeft'])) {
				var newOption = currentOption - 1;
				if (newOption < 0)
					newOption = options.length - 1;

				var doChange = true;
				if (onChangeFunc != null)
					doChange = onChangeFunc(newOption);
				if (doChange) {
					currentOption = newOption;
					optionText.text.text = options[currentOption];
				}
			}
			if (Key.isPressed(Key.RIGHT) || Gamepad.isPressed(['dpadRight'])) {
				var newOption = currentOption + 1;
				if (newOption >= options.length)
					newOption = 0;

				var doChange = true;
				if (onChangeFunc != null)
					doChange = onChangeFunc(newOption);
				if (doChange) {
					currentOption = newOption;
					optionText.text.text = options[currentOption];
				}
			}
		}
		super.update(dt, mouseState);
	}

	public function setCurrentOption(opt:Int) {
		currentOption = opt;
		optionText.text.text = options[currentOption];
	}
}
