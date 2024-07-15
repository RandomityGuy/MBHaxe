package gui;

import h2d.filter.DropShadow;
import h2d.Text;
import gui.GuiControl.MouseState;
import src.AudioManager;
import hxd.Key;
import src.Settings;
import src.Marble;
import h2d.Tile;
import hxd.res.BitmapFont;
import src.MarbleGame;
import h3d.Vector;
import src.ResourceLoader;
import src.Util;
import src.Settings;

class OptionsDlg extends GuiImage {
	var musicSliderFunc:(dt:Float, mouseState:MouseState) -> Void;

	public function new() {
		function chooseBg() {
			var rand = Math.random();
			if (rand >= 0 && rand <= 0.244)
				return ResourceLoader.getImage('data/ui/backgrounds/gold/${cast (Math.floor(Util.lerp(1, 12, Math.random())), Int)}.jpg');
			if (rand > 0.244 && rand <= 0.816)
				return ResourceLoader.getImage('data/ui/backgrounds/platinum/${cast (Math.floor(Util.lerp(1, 28, Math.random())), Int)}.jpg');
			return ResourceLoader.getImage('data/ui/backgrounds/ultra/${cast (Math.floor(Util.lerp(1, 9, Math.random())), Int)}.jpg');
		}
		var img = chooseBg();
		super(img.resource.toTile());
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(640, 480);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed];
		}

		function loadButtonImages2(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var touch = Util.isTouchDevice();

		var window = new GuiImage(ResourceLoader.getResource("data/ui/options/window.png", ResourceLoader.getImage, this.imageResources).toTile());
		window.horizSizing = Center;
		window.vertSizing = Center;
		window.position = new Vector(-72, -47);
		window.extent = new Vector(784, 573);
		this.addChild(window);

		var generalBtn = new GuiButton(loadButtonImages('data/ui/options/general'));
		generalBtn.position = new Vector(102, 19);
		generalBtn.extent = new Vector(134, 65);
		window.addChild(generalBtn);

		var hotkeysBtn = new GuiButton(loadButtonImages2('data/ui/options/hotkeys')); // touch settings
		hotkeysBtn.position = new Vector(325, 19);
		hotkeysBtn.extent = new Vector(134, 65);
		window.addChild(hotkeysBtn);

		var onlineBtn = new GuiImage(ResourceLoader.getResource("data/ui/options/online_i.png", ResourceLoader.getImage, this.imageResources).toTile());
		onlineBtn.position = new Vector(548, 19);
		onlineBtn.extent = new Vector(134, 65);
		window.addChild(onlineBtn);

		var applyFunc:Void->Void = () -> {
			Settings.applySettings();
		};

		var homeBtn = new GuiButton(loadButtonImages('data/ui/options/home'));
		homeBtn.position = new Vector(292, 482);
		homeBtn.extent = new Vector(94, 46);
		homeBtn.pressedAction = (sender) -> {
			applyFunc();
			MarbleGame.canvas.setContent(new MainMenuGui());
		}
		window.addChild(homeBtn);

		var applyBtn = new GuiButton(loadButtonImages('data/ui/options/apply'));
		applyBtn.position = new Vector(398, 482);
		applyBtn.extent = new Vector(94, 46);
		applyBtn.pressedAction = (sender) -> {
			applyFunc();
		}
		window.addChild(applyBtn);

		var generalPanel = new GuiControl();
		generalPanel.position = new Vector(30, 88);
		generalPanel.extent = new Vector(726, 394);
		window.addChild(generalPanel);

		var currentTab = "general";

		var hotkeysPanel = new GuiControl();
		hotkeysPanel.position = new Vector(30, 88);
		hotkeysPanel.extent = new Vector(726, 394);

		var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
		var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
		@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
		var markerFelt32 = markerFelt32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var markerFelt24 = markerFelt32b.toSdfFont(cast 18 * Settings.uiScale, MultiChannel);
		var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);

		var optBtns = [];
		var optSliders = [];

		var transparentbmp = new hxd.BitmapData(1, 1);
		transparentbmp.setPixel(0, 0, 0);
		var transparentTile = Tile.fromBitmap(transparentbmp);

		var currentDropDown:GuiImage = null;

		function setAllBtnState(enabled:Bool) {
			for (b in optBtns) {
				b.disabled = !enabled;
			}
			for (s in optSliders) {
				s.enabled = enabled;
			}
		}

		window.pressedAction = (sender) -> {
			if (currentDropDown != null) {
				var dropdownparent = currentDropDown.parent;
				currentDropDown.parent.removeChild(currentDropDown);
				currentDropDown = null;
				haxe.Timer.delay(() -> setAllBtnState(true), 5); // delay this a bit to avoid update();
			}
		}

		function makeOption(text:String, valueFunc:Void->String, yPos:Float, parent:GuiControl, size:String, options:Array<String>, onSelect:Int->Void,
				right:Bool = false, smallfont:Bool = false) {
			var textObj = new GuiText(smallfont ? markerFelt24 : markerFelt32);
			textObj.position = new Vector(right ? 388 : 7, yPos);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = text;
			textObj.text.textColor = 0xFFFFFF;
			textObj.text.dropShadow = {
				dx: 1 * Settings.uiScale,
				dy: 1 * Settings.uiScale,
				alpha: 0.5,
				color: 0
			};
			parent.addChild(textObj);

			var optDropdownImg = new GuiImage(ResourceLoader.getResource('data/ui/options/dropdown-${size}.png', ResourceLoader.getImage, this.imageResources)
				.toTile());

			optDropdownImg.position = new Vector(right ? 552 : 222, yPos + 39);
			optDropdownImg.extent = new Vector(163, 79 + switch (size) {
				case 'small': 0;
				case 'medium': 20;
				case 'large': 42;
				case 'xlarge': 97;
				default: 0;
			});

			var optDropdown = new GuiButtonText(loadButtonImages('data/ui/options/dropdown'), markerFelt24);
			optDropdown.position = new Vector(right ? 552 : 222, yPos - 12);
			optDropdown.setExtent(new Vector(163, 56));
			optDropdown.txtCtrl.text.text = valueFunc();
			optDropdown.txtCtrl.text.textColor = 0;
			optDropdown.pressedAction = (sender) -> {
				if (currentDropDown == null) {
					parent.addChild(optDropdownImg);
					optDropdownImg.render(MarbleGame.canvas.scene2d);
					currentDropDown = optDropdownImg;
					setAllBtnState(false);
					return;
				}
				if (currentDropDown == optDropdownImg) {
					parent.removeChild(optDropdownImg);
					currentDropDown = null;
					haxe.Timer.delay(() -> setAllBtnState(true), 5); // delay this a bit to avoid update();
					return;
				}
			}
			parent.addChild(optDropdown);

			var optDropdownList = new GuiTextListCtrl(markerFelt24, options);
			optDropdownList.position = new Vector(11, 15);
			optDropdownList.extent = new Vector(135, 47 + switch (size) {
				case 'small': 0;
				case 'medium': 20;
				case 'large': 42;
				case 'xlarge': 97;
				default: 0;
			});
			optDropdownList.textYOffset = -5;
			optDropdownList.onSelectedFunc = (idx) -> {
				onSelect(idx);
				optDropdown.txtCtrl.text.text = valueFunc();
			};
			optDropdownImg.addChild(optDropdownList);

			optBtns.push(optDropdown);
		}

		function makeSlider(text:String, value:Float, yPos:Float, parent:GuiControl, onChange:Float->Void, right:Bool = false, smallfont:Bool = false) {
			var textObj = new GuiText(smallfont ? markerFelt24 : markerFelt32);
			textObj.position = new Vector(right ? 388 : 7, yPos);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = text;
			textObj.text.textColor = 0xFFFFFF;
			textObj.text.dropShadow = {
				dx: 1 * Settings.uiScale,
				dy: 1 * Settings.uiScale,
				alpha: 0.5,
				color: 0
			};
			parent.addChild(textObj);

			var sliderBar = new GuiImage(ResourceLoader.getResource("data/ui/options/bar.png", ResourceLoader.getImage, this.imageResources).toTile());
			sliderBar.position = new Vector(right ? 552 : 226, yPos + 3 + 5);
			sliderBar.extent = new Vector(154, 19);
			parent.addChild(sliderBar);

			var optSlider = new GuiSlider(ResourceLoader.getResource("data/ui/options/slider.png", ResourceLoader.getImage, this.imageResources).toTile());
			optSlider.position = new Vector(right ? 550 : 220, yPos - 8 + 5);
			optSlider.extent = new Vector(150, 41);
			optSlider.sliderValue = value;
			optSlider.pressedAction = (sender) -> {
				onChange(optSlider.sliderValue);
			}
			parent.addChild(optSlider);

			optSliders.push(optSlider);
		}

		var begin = 18;
		var current = begin;
		if (!touch) {
			makeOption("Screen Resolution:", () -> '${Settings.optionsSettings.screenWidth} x ${Settings.optionsSettings.screenHeight}', current,
				generalPanel, "xlarge", [
					"1024 x 800",
					"1280 x 720",
					"1366 x 768",
					"1440 x 900",
					"1600 x 900",
					"1920 x 1080"
				], (idx) -> {
					switch (idx) {
						case 0:
							Settings.optionsSettings.screenWidth = 1024;
							Settings.optionsSettings.screenHeight = 800;
						case 1:
							Settings.optionsSettings.screenWidth = 1280;
							Settings.optionsSettings.screenHeight = 720;
						case 2:
							Settings.optionsSettings.screenWidth = 1366;
							Settings.optionsSettings.screenHeight = 768;
						case 3:
							Settings.optionsSettings.screenWidth = 1440;
							Settings.optionsSettings.screenHeight = 900;
						case 4:
							Settings.optionsSettings.screenWidth = 1600;
							Settings.optionsSettings.screenHeight = 900;
						case 5:
							Settings.optionsSettings.screenWidth = 1920;
							Settings.optionsSettings.screenHeight = 1080;
					}
				});
			makeOption("Screen Style:", () -> '${Settings.optionsSettings.isFullScreen ? "Full Screen" : "Windowed"}', current, generalPanel, "small",
				["Windowed", "Full Screen"], (idx) -> {
					Settings.optionsSettings.isFullScreen = idx == 1;
				}, true);

			current += 56;
		}

		makeOption("Frame Rate:", () -> '${Settings.optionsSettings.frameRateVis ? "Visible" : "Hidden"}', current, generalPanel, "small",
			["Visible", "Hidden"], (idx) -> {
				Settings.optionsSettings.frameRateVis = idx == 0;
			});
		makeOption("OoB Insults:", () -> '${Settings.optionsSettings.oobInsults ? "Enabled" : "Disabled"}', current, generalPanel, "small",
			["Disabled", "Enabled"], (idx) -> {
				Settings.optionsSettings.oobInsults = idx == 1;
			}, true);

		current += 56;

		makeOption("Free-Look:", () -> '${Settings.controlsSettings.alwaysFreeLook ? "Enabled" : "Disabled"}', current, generalPanel, "small",
			["Disabled", "Enabled"], (idx) -> {
				Settings.controlsSettings.alwaysFreeLook = idx == 1;
			});
		makeOption("Invert Y:", () -> '${Settings.controlsSettings.invertYAxis ? "Yes" : "No"}', current, generalPanel, "small", ["No", "Yes"], (idx) -> {
			Settings.controlsSettings.invertYAxis = idx == 1;
		}, true);

		current += 56;

		makeOption("Reflective Marble:", () -> '${Settings.optionsSettings.reflectiveMarble ? "Enabled" : "Disabled"}', current, generalPanel, "small",
			["Disabled", "Enabled"], (idx) -> {
				Settings.optionsSettings.reflectiveMarble = idx == 1;
			});
		makeOption("Vertical Sync:", () -> '${Settings.optionsSettings.vsync ? "Enabled" : "Disabled"}', current, generalPanel, "small",
			["Disabled", "Enabled"], (idx) -> {
				Settings.optionsSettings.vsync = idx == 1;
			}, true);

		current += 56;

		makeOption("Rewind:", () -> '${Settings.optionsSettings.rewindEnabled ? "Enabled" : "Disabled"}', current, generalPanel, "small",
			["Disabled", "Enabled"], (idx) -> {
				Settings.optionsSettings.rewindEnabled = idx == 1;
			}, false);

		makeSlider("Rewind Speed:", (Settings.optionsSettings.rewindTimescale - 0.1) / (1 - 0.1), current, generalPanel, (val) -> {
			Settings.optionsSettings.rewindTimescale = cast(0.1 + val * (1 - 0.1));
		}, true);

		current += 56;

		makeSlider("Music Volume:", Settings.optionsSettings.musicVolume, current, generalPanel, (val) -> {
			Settings.optionsSettings.musicVolume = val;
			AudioManager.updateVolumes();
		});
		makeSlider("Sound Volume:", Settings.optionsSettings.soundVolume, current, generalPanel, (val) -> {
			Settings.optionsSettings.soundVolume = val;
			AudioManager.updateVolumes();
		}, true);

		current += 56;

		makeSlider("Field of View:", (Settings.optionsSettings.fovX - 60) / (140 - 60), current, generalPanel, (val) -> {
			Settings.optionsSettings.fovX = cast(60 + val * (140 - 60));
		});
		makeSlider(touch ? "Camera Speed" : "Mouse Speed:", (Settings.controlsSettings.cameraSensitivity - 0.12) / (1.2 - 0.12), current, generalPanel,
			(val) -> {
				Settings.controlsSettings.cameraSensitivity = cast(0.12 + val * (1.2 - 0.12));
			}, true);

		if (touch) {
			current += 56;
			makeSlider("Camera Distance:", (Settings.optionsSettings.cameraDistance - 1.01) / (3 - 1.01), current, generalPanel, (val) -> {
				Settings.optionsSettings.cameraDistance = cast(1.01 + val * (3 - 1.01));
			});

			var textObj = new GuiText(markerFelt32);
			textObj.position = new Vector(388, current - 6);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = "Touch Controls";
			textObj.text.textColor = 0xFFFFFF;
			textObj.text.filter = new DropShadow(1.414, 0.785, 0x0000000F, 1, 0, 0.4, 1, true);
			generalPanel.addChild(textObj);

			var remapBtn = new GuiButtonText(loadButtonImages("data/ui/options/bind"), markerFelt24);
			remapBtn.position = new Vector(552, current - 6);
			remapBtn.txtCtrl.text.text = "Edit";
			remapBtn.setExtent(new Vector(152, 49));
			remapBtn.pressedAction = (sender) -> {
				MarbleGame.canvas.setContent(new TouchCtrlsEditGui());
			}
			generalPanel.addChild(remapBtn);
		}

		function getConflictingBinding(bindingName:String, key:Int) {
			if (Settings.controlsSettings.forward == key && bindingName != "Move Forward")
				return "Move Forward";
			if (Settings.controlsSettings.backward == key && bindingName != "Move Backward")
				return "Move Backward";
			if (Settings.controlsSettings.left == key && bindingName != "Move Left")
				return "Move Left";
			if (Settings.controlsSettings.right == key && bindingName != "Move Right")
				return "Move Right";
			if (Settings.controlsSettings.camForward == key && bindingName != "Rotate Camera Up")
				return "Rotate Camera Up";
			if (Settings.controlsSettings.camBackward == key && bindingName != "Rotate Camera Down")
				return "Rotate Camera Down";
			if (Settings.controlsSettings.camLeft == key && bindingName != "Rotate Camera Left")
				return "Rotate Camera Left";
			if (Settings.controlsSettings.camRight == key && bindingName != "Rotate Camera Right")
				return "Rotate Camera Right";
			if (Settings.controlsSettings.jump == key && bindingName != "Jump")
				return "Jump";
			if (Settings.controlsSettings.powerup == key && bindingName != "Use PowerUp")
				return "Use PowerUp";
			if (Settings.controlsSettings.freelook == key && bindingName != "Free Look")
				return "Free Look";

			return null;
		}

		function remapFunc(bindingName:String, bindingFunc:Int->Void, ctrl:GuiButtonText) {
			var remapDlg = new RemapDlg(bindingName);
			MarbleGame.canvas.pushDialog(remapDlg);
			remapDlg.remapCallback = (key) -> {
				MarbleGame.canvas.popDialog(remapDlg);

				if (key == Key.ESCAPE)
					return;

				var conflicting = getConflictingBinding(bindingName, key);
				if (conflicting == null) {
					ctrl.txtCtrl.text.text = Util.getKeyForButton2(key);
					bindingFunc(key);
				} else {
					var yesNoDlg = new MessageBoxYesNoDlg('<p align="center">"${Util.getKeyForButton2(key)}" is already bound to "${conflicting}"!<br/>Do you want to undo this mapping?</p>',
						() -> {
							ctrl.txtCtrl.text.text = Util.getKeyForButton2(key);
							bindingFunc(key);
						}, () -> {});
					MarbleGame.canvas.pushDialog(yesNoDlg);
				}
			}
		}

		function makeRemapOption(text:String, yPos:Int, defaultVal:String, bindingFunc:Int->Void, parent:GuiControl, right:Bool = false) {
			var textObj = new GuiText(markerFelt32);
			textObj.position = new Vector(right ? 368 : 5, yPos);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = text;
			textObj.text.textColor = 0xFFFFFF;
			textObj.text.dropShadow = {
				dx: 1 * Settings.uiScale,
				dy: 1 * Settings.uiScale,
				alpha: 0.5,
				color: 0
			};
			parent.addChild(textObj);

			var remapBtn = new GuiButtonText(loadButtonImages("data/ui/options/bind"), markerFelt24);
			remapBtn.position = new Vector(right ? 363 + 203 : 203, yPos - 3);
			remapBtn.txtCtrl.text.text = defaultVal;
			remapBtn.setExtent(new Vector(152, 49));
			remapBtn.pressedAction = (sender) -> {
				remapFunc(text, bindingFunc, remapBtn);
			}

			parent.addChild(remapBtn);
		}

		if (Util.isTouchDevice()) {
			var textObj = new GuiText(markerFelt32);
			textObj.position = new Vector(5, 38);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = "Touch Controls";
			textObj.text.textColor = 0xFFFFFF;
			textObj.text.dropShadow = {
				dx: 1 * Settings.uiScale,
				dy: 1 * Settings.uiScale,
				alpha: 0.5,
				color: 0
			};
			hotkeysPanel.addChild(textObj);

			var remapBtn = new GuiButtonText(loadButtonImages("data/ui/options/bind"), markerFelt24);
			remapBtn.position = new Vector(5 + 203, 35);
			remapBtn.txtCtrl.text.text = "Edit";
			remapBtn.setExtent(new Vector(152, 49));
			remapBtn.pressedAction = (sender) -> {
				MarbleGame.canvas.setContent(new TouchCtrlsEditGui());
			}
			hotkeysPanel.addChild(remapBtn);

			makeOption("Hide Controls:", () -> '${Settings.touchSettings.hideControls ? "Yes" : "No"}', 38, hotkeysPanel, "small", ["No", "Yes"], (idx) -> {
				Settings.touchSettings.hideControls = idx == 1;
			}, true);

			makeSlider("Button-Camera Factor:", (Settings.touchSettings.buttonJoystickMultiplier) / 3, 86, hotkeysPanel, (val) -> {
				Settings.touchSettings.buttonJoystickMultiplier = val * 3;
			}, false, true);

			makeSlider("Camera Swipe Extent:", (Settings.touchSettings.cameraSwipeExtent - 5) / (35 - 5), 86, hotkeysPanel, (val) -> {
				Settings.touchSettings.cameraSwipeExtent = 5 + (35 - 5) * val;
			}, true, true);

			makeOption("Dynamic Joystick:", () -> '${Settings.touchSettings.dynamicJoystick ? "Yes" : "No"}', 134, hotkeysPanel, "small", ["No", "Yes"],
				(idx) -> {
					Settings.touchSettings.dynamicJoystick = idx == 1;
				}, false, true);
		} else {
			makeRemapOption("Move Forward:", 38, Util.getKeyForButton2(Settings.controlsSettings.forward), (key) -> Settings.controlsSettings.forward = key,
				hotkeysPanel);
			makeRemapOption("Move Left:", 38, Util.getKeyForButton2(Settings.controlsSettings.left), (key) -> Settings.controlsSettings.left = key,
				hotkeysPanel, true);
			makeRemapOption("Move Backward:", 86, Util.getKeyForButton2(Settings.controlsSettings.backward),
				(key) -> Settings.controlsSettings.backward = key, hotkeysPanel);
			makeRemapOption("Move Right:", 86, Util.getKeyForButton2(Settings.controlsSettings.right), (key) -> Settings.controlsSettings.right = key,
				hotkeysPanel, true);
			makeRemapOption("Look Up:", 134, Util.getKeyForButton2(Settings.controlsSettings.camForward), (key) -> Settings.controlsSettings.camForward = key,
				hotkeysPanel);
			makeRemapOption("Look Left:", 134, Util.getKeyForButton2(Settings.controlsSettings.camLeft), (key) -> Settings.controlsSettings.camLeft = key,
				hotkeysPanel, true);
			makeRemapOption("Look Down:", 182, Util.getKeyForButton2(Settings.controlsSettings.camBackward),
				(key) -> Settings.controlsSettings.camBackward = key, hotkeysPanel);
			makeRemapOption("Look Right:", 182, Util.getKeyForButton2(Settings.controlsSettings.camRight), (key) -> Settings.controlsSettings.camRight = key,
				hotkeysPanel, true);
			makeRemapOption("Jump:", 230, Util.getKeyForButton2(Settings.controlsSettings.jump), (key) -> Settings.controlsSettings.jump = key, hotkeysPanel);
			makeRemapOption("Use Powerup:", 230, Util.getKeyForButton2(Settings.controlsSettings.powerup), (key) -> Settings.controlsSettings.powerup = key,
				hotkeysPanel, true);
			makeRemapOption("Free Look:", 278, Util.getKeyForButton2(Settings.controlsSettings.freelook), (key) -> Settings.controlsSettings.freelook = key,
				hotkeysPanel);
			makeRemapOption("Respawn:", 278, Util.getKeyForButton2(Settings.controlsSettings.respawn), (key) -> Settings.controlsSettings.respawn = key,
				hotkeysPanel, true);
			makeRemapOption("Blast:", 326, Util.getKeyForButton2(Settings.controlsSettings.blast), (key) -> Settings.controlsSettings.blast = key,
				hotkeysPanel);
			makeRemapOption("Rewind:", 326, Util.getKeyForButton2(Settings.controlsSettings.rewind), (key) -> Settings.controlsSettings.rewind = key,
				hotkeysPanel, true);
		}

		generalBtn.pressedAction = (e) -> {
			if (currentTab != "general") {
				currentTab = "general";
				hotkeysPanel.parent.removeChild(hotkeysPanel);
				window.addChild(generalPanel);
				MarbleGame.canvas.render(MarbleGame.canvas.scene2d); // Force refresh
			}
		};

		hotkeysBtn.pressedAction = (e) -> {
			if (currentTab != "hotkeys") {
				currentTab = "hotkeys";
				generalPanel.parent.removeChild(generalPanel);
				window.addChild(hotkeysPanel);
				MarbleGame.canvas.render(MarbleGame.canvas.scene2d); // Force refresh
			}
		};

		// // Touch Controls buttons???
		// if (Util.isTouchDevice()) {
		// 	var touchControlsTxt = new GuiText(domcasual24);
		// 	touchControlsTxt.text.text = "Touch Controls:";
		// 	touchControlsTxt.text.color = new Vector(0, 0, 0);
		// 	touchControlsTxt.position = new Vector(200, 465);
		// 	touchControlsTxt.extent = new Vector(200, 40);
		// 	var touchControlsEdit = new GuiButtonText(loadButtonImages("data/ui/options/cntr_cam_dwn"), domcasual24);

		// 	touchControlsEdit.position = new Vector(300, 455);
		// 	touchControlsEdit.txtCtrl.text.text = "Edit";
		// 	touchControlsEdit.setExtent(new Vector(109, 39));
		// 	touchControlsEdit.pressedAction = (sender) -> {
		// 		MarbleGame.canvas.setContent(new TouchCtrlsEditGui());
		// 	}
		// 	mainPane.addChild(touchControlsTxt);
		// 	mainPane.addChild(touchControlsEdit);
		// }
		// setTab = function(tab:String) {
		// 	tabs.removeChild(audioTab);
		// 	tabs.removeChild(controlsTab);
		// 	tabs.removeChild(boxFrame);
		// 	tabs.removeChild(graphicsTab);
		// 	mainPane.removeChild(graphicsPane);
		// 	mainPane.removeChild(audioPane);
		// 	mainPane.removeChild(controlsPane);
		// 	if (tab == "Graphics") {
		// 		tabs.addChild(audioTab);
		// 		tabs.addChild(controlsTab);
		// 		tabs.addChild(boxFrame);
		// 		tabs.addChild(graphicsTab);
		// 		mainPane.addChild(graphicsPane);
		// 	}
		// 	if (tab == "Audio") {
		// 		tabs.addChild(graphicsTab);
		// 		tabs.addChild(controlsTab);
		// 		tabs.addChild(boxFrame);
		// 		tabs.addChild(audioTab);
		// 		mainPane.addChild(audioPane);
		// 	}
		// 	if (tab == "Controls") {
		// 		tabs.addChild(audioTab);
		// 		tabs.addChild(graphicsTab);
		// 		tabs.addChild(boxFrame);
		// 		tabs.addChild(controlsTab);
		// 		mainPane.addChild(controlsPane);
		// 	}
		// 	this.render(MarbleGame.canvas.scene2d);
		// }
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		if (musicSliderFunc != null)
			musicSliderFunc(dt, mouseState);
	}
}
