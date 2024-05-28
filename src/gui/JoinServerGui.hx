package gui;

import net.Net;
import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Util;

class JoinServerGui extends GuiImage {
	var innerCtrl:GuiControl;

	public function new() {
		var res = ResourceLoader.getImage("data/ui/xbox/BG_fadeOutSoftEdge.png").resource.toTile();
		super(res);
		this.position = new Vector();
		this.extent = new Vector(640, 480);
		this.horizSizing = Width;
		this.vertSizing = Height;

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 21 * Settings.uiScale, h2d.Font.SDFChannel.MultiChannel);

		#if hl
		var scene2d = hxd.Window.getInstance();
		#end
		#if js
		var scene2d = MarbleGame.instance.scene2d;
		#end

		var offsetX = (scene2d.width - 1280) / 2;
		var offsetY = (scene2d.height - 720) / 2;

		var subX = 640 - (scene2d.width - offsetX) * 640 / scene2d.width;
		var subY = 480 - (scene2d.height - offsetY) * 480 / scene2d.height;

		innerCtrl = new GuiControl();
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);
		innerCtrl.horizSizing = Width;
		innerCtrl.vertSizing = Height;
		this.addChild(innerCtrl);

		var coliseumfontdata = ResourceLoader.getFileEntry("data/font/ColiseumRR.fnt");
		var coliseumb = new BitmapFont(coliseumfontdata.entry);
		@:privateAccess coliseumb.loader = ResourceLoader.loader;
		var coliseum = coliseumb.toSdfFont(cast 44 * Settings.uiScale, MultiChannel);

		var rootTitle = new GuiText(coliseum);

		rootTitle.position = new Vector(100, 30);
		rootTitle.extent = new Vector(1120, 80);
		rootTitle.text.textColor = 0xFFFFFF;
		rootTitle.text.text = "JOIN GAME";
		rootTitle.text.alpha = 0.5;
		innerCtrl.addChild(rootTitle);

		var inviteCodeBg = new GuiXboxOptionsList(1, "Invite Code: ", [""], 0.3, 155.5, false);
		inviteCodeBg.position = new Vector(360, 111);
		inviteCodeBg.horizSizing = Right;
		inviteCodeBg.vertSizing = Bottom;
		inviteCodeBg.extent = new Vector(835, 400);
		inviteCodeBg.selected = true;
		innerCtrl.addChild(inviteCodeBg);

		var inviteCodeInput = new GuiText(arial14);
		inviteCodeInput.position = new Vector(640, 36);
		inviteCodeInput.extent = new Vector(235, 18);
		inviteCodeInput.vertSizing = Top;
		inviteCodeInput.text.text = "";
		inviteCodeInput.text.textColor = 0;
		inviteCodeBg.addChild(inviteCodeInput);

		// Numpad
		var numpadCtrl = new GuiControl();
		numpadCtrl.position = new Vector(0, 60);
		numpadCtrl.extent = new Vector(800, 300);
		numpadCtrl.vertSizing = Top;
		inviteCodeBg.addChild(numpadCtrl);

		var addNum = (str:String) -> {
			if (inviteCodeInput.text.text.length < 6) {
				inviteCodeInput.text.text += str;
			}
		}
		var delNum = () -> {
			if (inviteCodeInput.text.text.length > 0) {
				inviteCodeInput.text.text = inviteCodeInput.text.text.substring(0, inviteCodeInput.text.text.length - 1);
			}
		}

		var one = new GuiXboxButton("1", 110);
		one.position = new Vector(240, 150);
		one.accelerators = [hxd.Key.NUMBER_1, hxd.Key.NUMPAD_1];
		one.pressedAction = (e) -> addNum("1");
		numpadCtrl.addChild(one);

		var two = new GuiXboxButton("2", 110);
		two.position = new Vector(320, 150);
		two.accelerators = [hxd.Key.NUMBER_2, hxd.Key.NUMPAD_2];
		two.pressedAction = (e) -> addNum("2");
		numpadCtrl.addChild(two);

		var three = new GuiXboxButton("3", 110);
		three.position = new Vector(400, 150);
		three.accelerators = [hxd.Key.NUMBER_3, hxd.Key.NUMPAD_3];
		three.pressedAction = (e) -> addNum("3");
		numpadCtrl.addChild(three);

		var four = new GuiXboxButton("4", 110);
		four.position = new Vector(240, 80);
		four.accelerators = [hxd.Key.NUMBER_4, hxd.Key.NUMPAD_4];
		four.pressedAction = (e) -> addNum("4");
		numpadCtrl.addChild(four);

		var five = new GuiXboxButton("5", 110);
		five.position = new Vector(320, 80);
		five.accelerators = [hxd.Key.NUMBER_5, hxd.Key.NUMPAD_5];
		five.pressedAction = (e) -> addNum("5");
		numpadCtrl.addChild(five);

		var six = new GuiXboxButton("6", 110);
		six.position = new Vector(400, 80);
		six.accelerators = [hxd.Key.NUMBER_6, hxd.Key.NUMPAD_6];
		six.pressedAction = (e) -> addNum("6");
		numpadCtrl.addChild(six);

		var seven = new GuiXboxButton("7", 110);
		seven.position = new Vector(240, 10);
		seven.accelerators = [hxd.Key.NUMBER_7, hxd.Key.NUMPAD_7];
		seven.pressedAction = (e) -> addNum("7");
		numpadCtrl.addChild(seven);

		var eight = new GuiXboxButton("8", 110);
		eight.position = new Vector(320, 10);
		eight.accelerators = [hxd.Key.NUMBER_8, hxd.Key.NUMPAD_8];
		eight.pressedAction = (e) -> addNum("8");
		numpadCtrl.addChild(eight);

		var nine = new GuiXboxButton("9", 110);
		nine.position = new Vector(400, 10);
		nine.accelerators = [hxd.Key.NUMBER_9, hxd.Key.NUMPAD_9];
		nine.pressedAction = (e) -> addNum("9");
		numpadCtrl.addChild(nine);

		var zero = new GuiXboxButton("0", 110);
		zero.position = new Vector(240, 220);
		zero.accelerators = [hxd.Key.NUMBER_0, hxd.Key.NUMPAD_0];
		zero.pressedAction = (e) -> addNum("0");
		numpadCtrl.addChild(zero);

		var del = new GuiXboxButton("Del", 110);
		del.position = new Vector(400, 220);
		del.accelerators = [hxd.Key.DELETE, hxd.Key.BACKSPACE];
		del.pressedAction = (e) -> delNum();
		numpadCtrl.addChild(del);

		var joinFunc = () -> {
			MarbleGame.canvas.setContent(new MultiplayerLoadingGui("Connecting"));
			var failed = true;
			haxe.Timer.delay(() -> {
				if (failed) {
					var loadGui:MultiplayerLoadingGui = cast MarbleGame.canvas.content;
					if (loadGui != null) {
						loadGui.setErrorStatus("Failed to connect to server");
						Net.disconnect();
					}
				}
			}, 15000);
			Net.joinServer(inviteCodeInput.text.text, true, () -> {
				failed = false;
				// Net.remoteServerInfo = ourServerList[curSelection];
			});
		}

		var ok = new GuiXboxButton("OK", 110);
		ok.position = new Vector(320, 220);
		ok.accelerators = [hxd.Key.ENTER];
		ok.pressedAction = (e) -> joinFunc();
		numpadCtrl.addChild(ok);

		// Bottom bar
		var bottomBar = new GuiControl();
		bottomBar.position = new Vector(0, 590);
		bottomBar.extent = new Vector(640, 200);
		bottomBar.horizSizing = Width;
		bottomBar.vertSizing = Bottom;
		innerCtrl.addChild(bottomBar);

		var backButton = new GuiXboxButton("Back", 160);
		backButton.position = new Vector(400, 0);
		backButton.vertSizing = Bottom;
		backButton.horizSizing = Right;
		backButton.gamepadAccelerator = ["B"];
		backButton.accelerators = [hxd.Key.ESCAPE, hxd.Key.BACKSPACE];
		backButton.pressedAction = (e) -> {
			MarbleGame.canvas.setContent(new MultiplayerGui());
		}
		bottomBar.addChild(backButton);

		var goButton = new GuiXboxButton("Go", 160);
		goButton.position = new Vector(960, 0);
		goButton.vertSizing = Bottom;
		goButton.horizSizing = Right;
		goButton.gamepadAccelerator = ["A"];
		goButton.accelerators = [hxd.Key.ENTER];
		goButton.pressedAction = (e) -> joinFunc();
		bottomBar.addChild(goButton);
	}

	override function onResize(width:Int, height:Int) {
		var offsetX = (width - 1280) / 2;
		var offsetY = (height - 720) / 2;

		var subX = 640 - (width - offsetX) * 640 / width;
		var subY = 480 - (height - offsetY) * 480 / height;
		innerCtrl.position = new Vector(offsetX, offsetY);
		innerCtrl.extent = new Vector(640 - subX, 480 - subY);

		super.onResize(width, height);
	}
}
