package gui;

import gui.GuiControl.MouseState;
import src.Settings;
import hxd.res.BitmapFont;
import hxd.Key;
import h3d.Vector;
import src.ResourceLoader;
import net.NetCommands;
import net.Net;
import src.MarbleGame;

@:publicFields
@:structInit
class ChatMessage {
	var text:String;
	var age:Float;
}

class ChatCtrl extends GuiControl {
	var chatHud:GuiMLText;
	var chatHudBg:GuiMLText;
	var chatHudInput:GuiTextInput;
	var chatInputBg:GuiImage;
	var chatInputBgText:GuiText;
	var chats:Array<ChatMessage>;
	var chatFocused:Bool = false;

	public function new() {
		super();

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 15 * Settings.uiScale, MultiChannel);

		this.chats = [];

		this.chatHudBg = new GuiMLText(arial14, (s) -> arial14);
		this.chatHudBg.position = new Vector(1, 21);
		this.chatHudBg.extent = new Vector(200, 250);
		this.chatHudBg.text.textColor = 0;
		this.addChild(chatHudBg);

		this.chatHud = new GuiMLText(arial14, (s) -> arial14);
		this.chatHud.position = new Vector(0, 20);
		this.chatHud.extent = new Vector(200, 250);
		this.addChild(chatHud);

		this.chatInputBg = new GuiImage(ResourceLoader.getResource('data/ui/exit/black.png', ResourceLoader.getImage, this.imageResources).toTile());
		this.chatInputBg.position = new Vector(0, 0);
		this.chatInputBg.extent = new Vector(200, 20);
		this.addChild(chatInputBg);

		this.chatInputBgText = new GuiText(arial14);
		this.chatInputBgText.position = new Vector(0, 0);
		this.chatInputBgText.extent = new Vector(200, 20);
		this.chatInputBg.addChild(chatInputBgText);
		this.chatInputBgText.text.textColor = 0xF29515;
		this.chatInputBgText.text.text = "Chat:";

		this.chatHudInput = new GuiTextInput(arial14);
		this.chatHudInput.position = new Vector(40, 0);
		this.chatHudInput.extent = new Vector(160, 20);
		@:privateAccess this.chatHudInput.text.interactive.forceAnywherefocus = true;
		this.addChild(chatHudInput);

		this.chatInputBgText.text.visible = false;
		this.chatInputBg.bmp.visible = false;

		var sendText = "";

		this.chatHudInput.text.onFocus = (e) -> {
			this.chatInputBgText.text.visible = true;
			this.chatInputBg.bmp.visible = true;
			chatFocused = true;
		}

		this.chatHudInput.text.onFocusLost = (e) -> {
			this.chatInputBgText.text.visible = false;
			this.chatInputBg.bmp.visible = false;
			this.chatHudInput.text.text = "";
			sendText = "";
			chatFocused = false;
		}

		this.chatHudInput.text.onKeyDown = (e) -> {
			if (e.keyCode == Key.ENTER) {
				if (StringTools.trim(this.chatHudInput.text.text) != "") {
					sendText = '<font color="#F29515">${StringTools.htmlEscape(Settings.highscoreName.substr(0, 20))}:</font> ${StringTools.htmlEscape(this.chatHudInput.text.text.substr(0, 50))}';
					if (Net.isClient) {
						NetCommands.sendChatMessage(StringTools.htmlEscape(sendText));
					}
					if (Net.isHost) {
						NetCommands.sendServerChatMessage(StringTools.htmlEscape(sendText));
					}
				}
				this.chatHudInput.text.text = "";
				this.chatInputBgText.text.visible = false;
				this.chatInputBg.bmp.visible = false;
				chatFocused = false;
			}
			if (e.keyCode == Key.ESCAPE) {
				this.chatHudInput.text.text = "";
				this.chatInputBgText.text.visible = false;
				this.chatInputBg.bmp.visible = false;
				chatFocused = false;
				@:privateAccess Key.keyPressed[Key.ESCAPE] = 0; // consume escape
			}
			@:privateAccess Key.keyPressed[e.keyCode] = 0; // consume keys
		}

		this.chatHud.text.text = "";
	}

	public inline function isChatFocused() {
		return chatFocused;
	}

	public function addChatMessage(text:String) {
		var realText = StringTools.htmlUnescape(text);
		this.chats.push({
			text: realText,
			age: 10.0
		});
		if (this.chats.length > 10) {
			this.chats = this.chats.slice(this.chats.length - 10);
		}
		redrawChatMessages();
	}

	function redrawChatMessages() {
		var joined = this.chats.map(x -> x.text).join("<br/>");
		this.chatHud.text.text = joined;
		this.chatHudBg.text.text = StringTools.replace(joined, '#F29515', '#000000');
	}

	function tickChats(dt:Float) {
		var needsRedraw = false;
		var chatsToRemove = [];
		for (chat in this.chats) {
			chat.age -= dt;
			if (chat.age < 0) {
				chatsToRemove.push(chat);
			}
		}
		while (chatsToRemove.length > 0) {
			this.chats.remove(chatsToRemove[0]);
			needsRedraw = true;
			chatsToRemove.shift();
		}
		if (needsRedraw) {
			redrawChatMessages();
		}
	}

	public function updateChat(dt:Float) {
		if (!chatFocused) {
			if (Key.isPressed(Key.T /*Settings.controlsSettings.chat*/)) {
				this.chatHudInput.text.focus();
			}
		}

		tickChats(dt);
	}
}
