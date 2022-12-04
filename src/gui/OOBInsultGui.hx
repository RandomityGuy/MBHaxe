package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.Settings;
import src.MarbleGame;

class OOBInsultGui extends GuiImage {
	public function new(title:String, text:String) {
		var img = ResourceLoader.getImage("data/ui/marbleSelect/marbleSelect.png");
		super(img.resource.toTile());

		MarbleGame.instance.world.setCursorLock(false);
		MarbleGame.instance.paused = true;

		this.horizSizing = Center;
		this.vertSizing = Center;
		this.position = new Vector(98, 69);
		this.extent = new Vector(444, 341);

		var domcasual32fontdata = ResourceLoader.getFileEntry("data/font/DomCasualD.fnt");
		var domcasual32b = new BitmapFont(domcasual32fontdata.entry);
		@:privateAccess domcasual32b.loader = ResourceLoader.loader;
		var domcasual32 = domcasual32b.toSdfFont(cast 26 * Settings.uiScale, MultiChannel);
		var domcasual64 = domcasual32b.toSdfFont(cast 58 * Settings.uiScale, MultiChannel);
		var domcasual24 = domcasual32b.toSdfFont(cast 20 * Settings.uiScale, MultiChannel);

		var arial14fontdata = ResourceLoader.getFileEntry("data/font/arial.fnt");
		var arial14b = new BitmapFont(arial14fontdata.entry);
		@:privateAccess arial14b.loader = ResourceLoader.loader;
		var arial14 = arial14b.toSdfFont(cast 12 * Settings.uiScale, MultiChannel);

		function loadButtonImages(path:String) {
			var normal = ResourceLoader.getResource('${path}_n.png', ResourceLoader.getImage, this.imageResources).toTile();
			var hover = ResourceLoader.getResource('${path}_h.png', ResourceLoader.getImage, this.imageResources).toTile();
			var pressed = ResourceLoader.getResource('${path}_d.png', ResourceLoader.getImage, this.imageResources).toTile();
			var disabled = ResourceLoader.getResource('${path}_i.png', ResourceLoader.getImage, this.imageResources).toTile();
			return [normal, hover, pressed, disabled];
		}

		var titleText = new GuiMLText(domcasual24, null);
		titleText.horizSizing = Center;
		titleText.position = new Vector(35, 39);
		titleText.extent = new Vector(374, 25);
		titleText.text.textColor = 0;
		titleText.text.text = '<p align="center">${title}</p>';
		this.addChild(titleText);

		var contentText = new GuiMLText(arial14, null);
		contentText.horizSizing = Center;
		contentText.position = new Vector(33, 66);
		contentText.extent = new Vector(377, 350);
		contentText.text.textColor = 0;
		contentText.text.text = text;
		this.addChild(contentText);

		var okBtn = new GuiButton(loadButtonImages("data/ui/motd/ok"));
		okBtn.position = new Vector(179, 254);
		okBtn.extent = new Vector(88, 41);
		okBtn.vertSizing = Top;
		okBtn.pressedAction = (e) -> {
			MarbleGame.instance.paused = false;
			MarbleGame.canvas.popDialog(this);
			MarbleGame.instance.world.setCursorLock(true);
		}
		this.addChild(okBtn);
	}

	public static function OOBCheck() {
		var oobMsgs = [
			"Let\'s be clear of the blatant truth: You suck!",
			"Honestly, do you have any control over the marble? It seems to have a life on its own...",
			"Are you sure you know how to play Marble Blast?",
			"I really hope you\'re seeing this message on Manic Bounce right now. If you\'re not, man do YOU have some practicing to do.",
			"Look at the bright side, it\'s part of the learning experience, but it doesn\'t change the fact that you still suck.",
			"If we ever had a \'You suck\' achievement, you\'d be having the honour to wear it today.",
			"200 more times to go Out of Bounds before you see this message again. For your sake, try and do better.",
			"\"I didn\'t play on the computer! It...it was.. my auntie!\" Yeah, right. Admit it, you suck.",
			"Are you having fun going Out of Bounds all the time? It seriously looks like it.",
			"Don\'t you just hate all these messages that make a mockery of your suckiness? It\'s a joke of course, but it\'s a nice easter egg.\nIf you don\'t want to see them anymore, then stop going Out of Bounds so many times!",
			"My grandmother is better than you!",
			"We\'ll see what happens first: You finishing the level, or the clock hitting the 100 minute mark.",
			"Can we put this on the video show? I mean, that was absolutely stupid of you to go Out of Bounds like that!",
			"While we\'re on the subject of you going Out of Bounds, you should try and find out all the possible ways to go Out of Bounds, including the stupid ways which you seem to excel in.",
			"This level isn\'t made out completely out of tiny thin tightropes! You have no excuse whatsoever on failing this badly. If you see this message on Tightropes, Under Construction, Catwalks, or Slopwropes, ignore it. Instead, change it to \"HAHAHA!\"",
			"Excuse of the Day: \"I was pushed Out of Bounds by an invisible Mega Marble!\"",
			"Congratulations, you win--- wait, no, no you don\'t. You went Out of Bounds. Sorry, you lose. Again.",
			"I found a way for you not to go Out of Bounds. We\'ll change the shape of the marble to a cube. Wait, never mind, you\'ll still find a way, because you can.",
			"You sure you played the beginner levels? You did? Doesn\'t look like it.",
			"You know what would be hilarious? This message popping up on \'Training Wheels\'. I hope you aren\'t playing that level right now... are you?",
			"Mind if we\'ll change your name to \'Mr. McFail?\'",
			"Excuse of the Day: \"But I was distracted by ________ and he/she/it wouldn\'t stop and forced me to go Out of Bounds.\"",
			"Which one are you: a bad player or a bad player? We willl go with option C: a really bad player.",
			"Excuse of the Day: WHO PUT THAT GRAVITY MODIFIER IN THERE??!?!",
			"Excuse of the Day: That In Bounds Trigger WAS NOT in the level last time I played it! Somebody hacked the level and put one in there!",
			"Excuse of the Day: My awesome marble was abducted by aliens and was replaced by a really crap one!",
			"Excuse of the Day: That Out of Bounds trigger was NOT there before! I swear!",
			"Excuse of the Day: I\'m not Xelna :(",
			"Excuse of the Day: I don\'t suck, I fell off because I wanted to get to the next 200 Out of Bounds multiplier so I can see the awesome messages that are written down.",
			"You know, you won\'t beat the level if you keep falling off. You will, however, see more of these messages. Try and stay on the level next time. Our guess is that you can\'t, because you\'re bad.",
			"Look at the statistics page! I bet you fell more times than the amount of levels you beat!",
			"Excuse of the Day: I\'m learning to play... the hard way.",
			"Apparently your marble isn\'t supermarble. It is suckmarble.",
			"Foo-Foo Marble laughs at how bad you are.",
			"A Rock Can Do Better!",
			"Please, Quit Embarrassing Yourself.",
			"Keep this up and you\'ll win the \'Award of LOL\', courtesy of Marble Blast Fubar creators!",
			"Marble Blast Fubar creators would like to give you the title of \'Official NOOB of the Year\'. Congratulations!",
			"Did you hear that \'Practice Makes Perfect\'? Apparently not.",
			"You should create a new level and title it \'Learn the In Bounds and Out of Bounds Triggers\' because you\'re so experienced with them.",
			"We\'ve seen the ways you fell while playing this game and we gotta admit, some of their are epic fails. We still can\'t stop laughing!",
			"SING WITH ME:\n\nOne hundred and ninety nine times Out of Bounds, one hundred and ninety nine times Out of Bounds, throw the marble off the level, two hundred times Out of Bounds!",
			"*sigh*, you just can\'t stop yourself from going Out of Bounds, can you?",
			"Excuse of the Day: I\'m playing one of those special levels from Technostick where you must fall off in order to beat them.",
			"Excuse of the Day: I\'m under bad karma today.",
			"Excuse of the Day: So THAT\'S what my astrologist referred to when he said I\'ll keep falling off today.",
			"What do you have against the marble that you keep making it fall off the level?!",
			"I bet having a Blast powerup would have really helped you there, no? Well, too bad! \nOh, and if you\'re playing an Ultra level, pretend this message says \"HAHAHA!\" instead.",
			"And how is it OUR fault that you\'re playing so badly?",
			"Do you ever think about the marble\'s safety when you\'re playing? Apparently not because you\'re really careless with it."
		];

		var oobSpecial = [
			"You went Out of Bounds for 1,250 times. This program will now sit in the corner and cry about how bad you are and hope that when you open it again you won\'t repeat it. False hopes are still hopes.",
			"You went Out of Bounds for 2,500 times. If you aren\'t tired of going Out of Bounds all the time, we sure did. Stop it already!",
			"Another 1,250 marbles had fallen to the great sea below, and you\'ve reached the 3,750 Out of Bounds mark. You definitely suck. Ah yes, greenpeace would like to see you in court for your \"contribution\" to rising sea levels.",
			"If I had a nickel for every marble that fell Out of Bounds I\'d be rich right now and all thanks to you. However, I\'m not going to give you any money. Instead, I\'ll stick my tongue out at you and then laugh at you. Ah yes, congratulations on hitting the 5,000 Out of Bounds mark.",
			"6,750 times Out of Bounds. Let\'s assume, hypothetically, that you won\'t go Out of Bounds ever again. Actually, never mind that, you will still suck even if you don\'t go Out of Bounds again.",
			"I have an awesome gut feeling that you are going 7,500 times Out of Bounds on purpose if only to see these messages and to hear about how bad you are.\nWell then, I won\'t keep it away from you.\nYou suck!",
			"8,750 times Out of Bounds. For reaching this landmark, I\'m giving you a nice Australian Slang sentence to answer the question: Will you ever stop sucking in this game and go Out of Bounds? Answer:\nTill it rains in Marble Bar\n\n\nIn your language it means:\nNever.",
			"Wow, you truly are bad, probably one of the worst Marble Blast players to ever live on this planet. Or you just keep failing to good runs. Are you sure you aren\'t playing an easy level while this message pops up? Whatever, those messages will now repeat themselves (with a few exceptions), but for now, please remember this:\n\n\nYOU suck!",
			"SING WITH ME:\n\nForty nine thousand nine hundred and ninety nine times Out of Bounds, forty nine thousand nine hundred and ninety nine times Out of Bounds, knock a marble off the level, fifty thousand times Out of Bounds!",
			"What\'s that in the sky? Is it a plane? Is it a bird? No! It\'s the marble! And it\'s way off the level!!! Congratulations on hitting 300,000 Out of Bounds mark. You may now suck more.",
			"1,000,000 times Out of Bounds?!?! You seriously love this game, don\'t you? Well then, thanks for playing Marble Blast Platinum! Please keep this bad playing up and continue to go Out of Bounds. We\'ll just laugh at how bad you are. Also, this is the final message as from now on they\'re all repeats. Thank you for sucking at Marble Blast Platinum!",
			"You have no life. This is official."
		];

		var oobMsg = "";
		var oobTitle = "Out of Bounds";

		switch (Settings.playStatistics.oobs) {
			case 1250:
				oobMsg = oobSpecial[0];
			case 2500:
				oobMsg = oobSpecial[1];
			case 3750:
				oobMsg = oobSpecial[2];
			case 5000:
				oobMsg = oobSpecial[3];
			case 6250:
				oobMsg = oobSpecial[4];
			case 7500:
				oobMsg = oobSpecial[5];
			case 8750:
				oobMsg = oobSpecial[6];
			case 10000:
				oobMsg = oobSpecial[7];
			case 50000:
				oobMsg = oobSpecial[8];
			case 300000:
				oobMsg = oobSpecial[9];
			case 1000000:
				oobMsg = oobSpecial[10];
			case 30000000:
				oobMsg = oobSpecial[11];
		}

		if (oobMsg == "") {
			if (Settings.playStatistics.oobs != 0 && Settings.playStatistics.oobs % 200 == 0) {
				oobTitle = 'Out of Bounds ${Settings.playStatistics.oobs} times';
				oobMsg = oobMsgs[Math.floor(Math.random() * oobMsgs.length)];
			}
		}

		if (oobMsg != "") {
			MarbleGame.canvas.pushDialog(new OOBInsultGui(oobTitle, oobMsg));
		}
	}
}
