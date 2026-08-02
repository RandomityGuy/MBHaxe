package gui;

import h3d.Matrix;
import haxe.DynamicAccess;
import hxd.BitmapData;
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

class OptionsDlg extends GuiControl {
	var musicSliderFunc:(dt:Float, mouseState:MouseState) -> Void;
	var importing:Bool = false;

	public function new(pause:Bool = false) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.position = new Vector();
		this.extent = new Vector(800, 600);
		if (!ResourceLoader.exists(Settings.optionsSettings.previewPath))
			Settings.optionsSettings.previewPath = "data/previews_pq/tutorial/trainingwheels.prev.dds";
		var levelPreview = new GuiImage(ResourceLoader.getResource(Settings.optionsSettings.previewPath, ResourceLoader.getImage, this.imageResources)
			.toTile());
		levelPreview.horizSizing = Width;
		levelPreview.vertSizing = Height;
		levelPreview.position = new Vector(0, 0);
		levelPreview.extent = new Vector(800, 600);
		this.addChild(levelPreview);

		var whatneyFontData = ResourceLoader.getFileEntry("data/font/whatney.fnt");
		var whatneyFontB = new BitmapFont(whatneyFontData.entry);
		@:privateAccess whatneyFontB.loader = ResourceLoader.loader;
		var whatneyFont = whatneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel, 0.5, 0.5);
		var whatneyFont14 = whatneyFontB.toSdfFont(cast 14 * Settings.uiScale, MultiChannel, 0.5, 0.5);
		var whatneyFont20 = whatneyFontB.toSdfFont(cast 17 * Settings.uiScale, MultiChannel, 0.5, 0.5);

		var squishneyFontData = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyFontB = new BitmapFont(squishneyFontData.entry);
		@:privateAccess squishneyFontB.loader = ResourceLoader.loader;
		var squishneyFont = squishneyFontB.toSdfFont(cast 28 * Settings.uiScale, MultiChannel, 0.5, 0.5);
		var squishneyFont24 = squishneyFontB.toSdfFont(cast 21 * Settings.uiScale, MultiChannel, 0.5, 0.5);
		var squishneyFont28 = squishneyFontB.toSdfFont(cast 25 * Settings.uiScale, MultiChannel, 0.5, 0.5);

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
		window.position = new Vector(8, 13);
		window.extent = new Vector(784, 573);
		this.addChild(window);

		var generalBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		generalBtn.position = new Vector(102, 19);
		generalBtn.ratio = 0.37;
		generalBtn.setExtent(new Vector(134, 65));
		generalBtn.txtCtrl.text.text = "General";
		window.addChild(generalBtn);

		var hotkeysBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		hotkeysBtn.position = new Vector(325, 19);
		hotkeysBtn.ratio = 0.37;
		hotkeysBtn.setExtent(new Vector(134, 65));
		hotkeysBtn.txtCtrl.text.text = "Input";
		window.addChild(hotkeysBtn);

		var miscBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		miscBtn.position = new Vector(548, 19);
		miscBtn.ratio = 0.37;
		miscBtn.setExtent(new Vector(134, 65));
		miscBtn.txtCtrl.text.text = "Misc";
		window.addChild(miscBtn);

		var generalPanel:GuiControl = null;

		var applyFunc:Void->Void = () -> {
			Settings.applySettings();
		};

		var homeBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		homeBtn.position = new Vector(304, 500);
		homeBtn.setExtent(new Vector(94, 46));
		homeBtn.txtCtrl.text.text = "Home";
		homeBtn.pressedAction = (sender) -> {
			applyFunc();
			if (!pause)
				MarbleGame.canvas.setContent(new MainMenuGui());
			else
				MarbleGame.canvas.popDialog(this);
		}
		window.addChild(homeBtn);

		var applyBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
			.toTile(), whatneyFont);
		applyBtn.position = new Vector(398, 500);
		applyBtn.setExtent(new Vector(94, 46));
		applyBtn.txtCtrl.text.text = "Apply";
		applyBtn.pressedAction = (sender) -> {
			applyFunc();
		}
		window.addChild(applyBtn);

		generalPanel = new GuiControl();
		generalPanel.position = new Vector(30, 88);
		generalPanel.extent = new Vector(726, 394);
		window.addChild(generalPanel);

		var currentTab = "general";

		var hotkeysPanel = new GuiControl();
		hotkeysPanel.position = new Vector(30, 88);
		hotkeysPanel.extent = new Vector(726, 394);

		var miscPanel = new GuiControl();
		miscPanel.position = new Vector(30, 88);
		miscPanel.extent = new Vector(726, 394);

		var optBtns = [];
		var optSliders = [];

		function makeOption(text:String, valueFunc:Void->String, yPos:Float, parent:GuiControl, size:String, options:Array<String>, onSelect:Int->Void,
				right:Bool = false, smallfont:Bool = false) {
			var textObj = new GuiText(smallfont ? squishneyFont24 : squishneyFont28);
			textObj.position = new Vector(right ? 388 : 5, yPos + 7);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = text;
			textObj.text.textColor = 0x0;
			parent.addChild(textObj);

			var optionText = new GuiText(squishneyFont24);
			optionText.position = new Vector(right ? 522 : 180, yPos + 9);
			optionText.extent = new Vector(212, 14);
			optionText.justify = Center;
			optionText.text.text = valueFunc();
			optionText.text.textColor = 0x0;
			parent.addChild(optionText);

			var colorMat = new Matrix();
			colorMat.colorSet(0x0);

			var nextBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
				.toTile());
			nextBtn.position = new Vector(right ? 689 : 337, yPos - 4);
			nextBtn.extent = new Vector(45, 45);
			nextBtn.pressedAction = (e) -> {
				// setMarbleSelection(curSelection + 1, curCategorySelection);
			}
			parent.addChild(nextBtn);

			var nextBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources).toTile());
			nextBtnIcon.position = new Vector(22.5 + 13.0 / 2, 22.5 + 19.0 / 2);
			nextBtnIcon.extent = new Vector(13, 19);
			nextBtnIcon.bmp.colorMatrix = colorMat;
			nextBtnIcon.bmp.rotation = Math.PI;
			nextBtn.addChild(nextBtnIcon);

			var prevBtn = new GuiBorderButtonCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
				.toTile());
			prevBtn.position = new Vector(right ? 522 : 190, yPos - 4);
			prevBtn.extent = new Vector(45, 45);
			prevBtn.pressedAction = (e) -> {
				// setMarbleSelection(curSelection - 1, curCategorySelection);
			}
			parent.addChild(prevBtn);

			var prevBtnIcon = new GuiImage(ResourceLoader.getResource("data/ui/play/leftright.png", ResourceLoader.getImage, this.imageResources).toTile());
			prevBtnIcon.horizSizing = Center;
			prevBtnIcon.vertSizing = Center;
			prevBtnIcon.position = new Vector(0, 0);
			prevBtnIcon.extent = new Vector(13, 19);
			prevBtnIcon.bmp.colorMatrix = colorMat;
			prevBtn.addChild(prevBtnIcon);

			var curOptionIndex = options.indexOf(valueFunc());
			if (curOptionIndex == -1) {
				curOptionIndex = 0;
			}

			nextBtn.pressedAction = (e) -> {
				curOptionIndex = Util.adjustediMod(curOptionIndex + 1, options.length);
				onSelect(curOptionIndex);
				optionText.text.text = valueFunc();
			}

			prevBtn.pressedAction = (e) -> {
				curOptionIndex = Util.adjustediMod(curOptionIndex - 1, options.length);
				onSelect(curOptionIndex);
				optionText.text.text = valueFunc();
			}
		}

		function makeSlider(text:String, value:Float, yPos:Float, parent:GuiControl, onChange:Float->Void, right:Bool = false, smallfont:Bool = false) {
			var textObj = new GuiText(smallfont ? squishneyFont24 : squishneyFont28);
			textObj.position = new Vector(right ? 388 : 5, yPos + 7);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = text;
			textObj.text.textColor = 0x0;
			parent.addChild(textObj);

			var sliderBar = new GuiImage(ResourceLoader.getResource("data/ui/options/slider_bar.png", ResourceLoader.getImage, this.imageResources).toTile());
			sliderBar.position = new Vector(right ? 552 : 226, yPos + 3 + 14);
			sliderBar.extent = new Vector(154, 10);
			sliderBar.bmp.tile = sliderBar.bmp.tile.sub(0, 0, 154, sliderBar.bmp.tile.height);
			parent.addChild(sliderBar);

			var optSlider = new GuiSlider(ResourceLoader.getResource("data/ui/options/slider.png", ResourceLoader.getImage, this.imageResources).toTile());
			optSlider.position = new Vector(right ? 550 : 220, yPos - 8 + 12);
			optSlider.extent = new Vector(150, 35);
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
			if (!pause)
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

		function remapFunc(bindingName:String, bindingFunc:Int->Void, ctrl:GuiBorderButtonTextCtrl) {
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
			var textObj = new GuiText(squishneyFont28);
			textObj.position = new Vector(right ? 368 : 5, yPos);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = text;
			textObj.text.textColor = 0x0;
			parent.addChild(textObj);

			var remapBtn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
				.toTile(), whatneyFont20);
			remapBtn.position = new Vector(right ? 363 + 203 : 203, yPos - 12);
			remapBtn.setExtent(new Vector(163, 45));
			remapBtn.txtCtrl.text.text = defaultVal;
			remapBtn.pressedAction = (sender) -> {
				remapFunc(text, bindingFunc, remapBtn);
			}

			parent.addChild(remapBtn);
		}

		function makeButton(text:String, yPos:Int, buttonText:String, pressedAction:() -> Void, parent:GuiControl, right:Bool = false) {
			var textObj = new GuiText(squishneyFont28);
			textObj.position = new Vector(right ? 368 : 5, yPos);
			textObj.extent = new Vector(212, 14);
			textObj.text.text = text;
			textObj.text.textColor = 0x0;
			parent.addChild(textObj);

			var btn = new GuiBorderButtonTextCtrl(ResourceLoader.getResource('data/ui/common/button.png', ResourceLoader.getImage, this.imageResources)
				.toTile(), whatneyFont20);
			btn.position = new Vector(right ? 363 + 203 : 203, yPos - 12);
			btn.setExtent(new Vector(163, 45));
			btn.txtCtrl.text.text = buttonText;
			btn.pressedAction = (sender) -> {
				pressedAction();
			}

			parent.addChild(btn);
		}

		if (Util.isTouchDevice()) {
			makeButton("Touch Controls:", 44, "Edit", () -> {
				MarbleGame.canvas.setContent(new TouchCtrlsEditGui());
			}, hotkeysPanel);

			makeOption("Hide Controls:", () -> '${Settings.touchSettings.hideControls ? "Yes" : "No"}', 86, hotkeysPanel, "small", ["No", "Yes"], (idx) -> {
				Settings.touchSettings.hideControls = idx == 1;
			}, false);

			makeSlider("Button-Camera Factor:", (Settings.touchSettings.buttonJoystickMultiplier) / 3, 134, hotkeysPanel, (val) -> {
				Settings.touchSettings.buttonJoystickMultiplier = val * 3;
			}, false, true);

			makeOption("Dynamic Joystick:", () -> '${Settings.touchSettings.dynamicJoystick ? "Yes" : "No"}', 182, hotkeysPanel, "small", ["No", "Yes"],
				(idx) -> {
					Settings.touchSettings.dynamicJoystick = idx == 1;
				}, false, true);

			makeSlider("Camera Swipe Extent:", (Settings.touchSettings.cameraSwipeExtent - 5) / (35 - 5), 230, hotkeysPanel, (val) -> {
				Settings.touchSettings.cameraSwipeExtent = 5 + (35 - 5) * val;
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

		// MISC PANEL
		makeButton("Import Progress:", 38, "Import", () -> {
			trace("Start prefs import");
			importing = true;
			Settings.start_import_prefs((data) -> {
				try {
					// convert to string
					var jsonStr = @:privateAccess String.fromUTF8(data);
					// parse JSON
					var json = haxe.Json.parse(jsonStr);

					var highScoreData:DynamicAccess<Array<Score>> = json.highScores;
					for (key => value in highScoreData) {
						Settings.highScores.set(key, value);
					}
					var easterEggData:DynamicAccess<Float> = json.easterEggs;
					if (easterEggData != null) {
						for (key => value in easterEggData) {
							Settings.easterEggs.set(key, value);
						}
					}
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Progress data imported successfully!"));
					Settings.save();
				} catch (e) {
					MarbleGame.canvas.pushDialog(new MessageBoxOkDlg("Failed to import progress data: " + e.message));
				}
				importing = false; // reset this flag after import is done
			});
		}, miscPanel);
		makeButton("Export Progress:", 38, "Export", () -> {
			Settings.export_prefs();
		}, miscPanel, true);

		generalBtn.pressedAction = (e) -> {
			if (currentTab != "general") {
				currentTab = "general";
				hotkeysPanel.parent?.removeChild(hotkeysPanel);
				miscPanel.parent?.removeChild(miscPanel);
				window.addChild(generalPanel);
				MarbleGame.canvas.render(MarbleGame.canvas.scene2d); // Force refresh
			}
		};

		hotkeysBtn.pressedAction = (e) -> {
			if (currentTab != "hotkeys") {
				currentTab = "hotkeys";
				generalPanel.parent?.removeChild(generalPanel);
				miscPanel.parent?.removeChild(miscPanel);
				window.addChild(hotkeysPanel);
				MarbleGame.canvas.render(MarbleGame.canvas.scene2d); // Force refresh
			}
		};

		miscBtn.pressedAction = (e) -> {
			if (currentTab != "misc") {
				currentTab = "misc";
				generalPanel.parent?.removeChild(generalPanel);
				hotkeysPanel.parent?.removeChild(hotkeysPanel);
				window.addChild(miscPanel);
				MarbleGame.canvas.render(MarbleGame.canvas.scene2d); // Force refresh
			}
		};
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		if (musicSliderFunc != null)
			musicSliderFunc(dt, mouseState);
		if (importing) {
			Settings.call_import_cb();
		}
	}
}
