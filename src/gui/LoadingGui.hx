package gui;

import hxd.res.BitmapFont;
import h3d.Vector;
import src.ResourceLoader;
import src.MarbleGame;
import src.Settings;
import src.Util;
import src.Mission;

class LoadingGui extends GuiControl {
	public var setProgress:Float->Void;

	public function new(mission:Mission, isMultiplayer:Bool = false) {
		super();
		this.horizSizing = Width;
		this.vertSizing = Height;
		this.extent = new Vector(800, 600);
		this.position = new Vector();

		var levelPreview = new GuiImage(ResourceLoader.getResource("data/ui/play/missingicon.png", ResourceLoader.getImage, this.imageResources).toTile());
		levelPreview.horizSizing = Width;
		levelPreview.vertSizing = Height;
		levelPreview.position = new Vector(0, 0);
		levelPreview.extent = new Vector(800, 600);
		this.addChild(levelPreview);

		mission.getBigPreviewImage(prev -> {
			levelPreview.bmp.tile = prev;
		});

		var loadingBody = new GuiControl();
		loadingBody.horizSizing = Center;
		loadingBody.vertSizing = Center;
		loadingBody.position = new Vector(-119, 87);
		loadingBody.extent = new Vector(1038, 425);
		this.addChild(loadingBody);

		var loadingMainText = new GuiImage(ResourceLoader.getResource("data/ui/loading/loading_main_text.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		loadingMainText.horizSizing = Center;
		loadingMainText.vertSizing = Height;
		loadingMainText.position = new Vector(100, 170);
		loadingMainText.extent = new Vector(838, 256);
		loadingBody.addChild(loadingMainText);

		var loadingTitle = new GuiImage(ResourceLoader.getResource("data/ui/loading/loading_title.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		loadingTitle.horizSizing = Center;
		loadingTitle.vertSizing = Bottom;
		loadingTitle.position = new Vector(208, 0);
		loadingTitle.extent = new Vector(622, 93);
		loadingBody.addChild(loadingTitle);

		var squishneyfontdata = ResourceLoader.getFileEntry("data/font/squishney.fnt");
		var squishneyb = new BitmapFont(squishneyfontdata.entry);
		@:privateAccess squishneyb.loader = ResourceLoader.loader;
		var squishney56 = squishneyb.toSdfFont(cast 50 * Settings.uiScale, MultiChannel);
		var squishney28 = squishneyb.toSdfFont(cast 25 * Settings.uiScale, MultiChannel, 0.5, 0.5);

		var loadingTitleText = new GuiText(squishney56);
		loadingTitleText.justify = Center;
		loadingTitleText.position = new Vector(305, 5);
		loadingTitleText.extent = new Vector(456, 65);
		loadingTitleText.text.textColor = 0x000000;
		loadingTitleText.text.text = "Loading...";
		loadingBody.addChild(loadingTitleText);

		var loadingLevel = new GuiText(squishney28);
		loadingLevel.justify = Center;
		loadingLevel.position = new Vector(305, 65);
		loadingLevel.extent = new Vector(456, 65);
		loadingLevel.text.textColor = 0x000000;
		loadingLevel.text.text = mission.title;
		loadingBody.addChild(loadingLevel);

		var loadingMessage = new GuiText(squishney28);
		loadingMessage.horizSizing = Center;
		loadingMessage.position = new Vector(169, 180);
		loadingMessage.extent = new Vector(700, 96);
		loadingMessage.text.textColor = 0x000000;
		loadingMessage.text.text = "Message.";
		loadingMessage.text.lineSpacing = 4;
		loadingMessage.text.maxWidth = 700 * Settings.uiScale;
		loadingBody.addChild(loadingMessage);

		var rng = Std.random(101);
		if (rng < 80)
			loadingMessage.text.text = TIPS[Std.random(TIPS.length)];
		else if (rng < 97)
			loadingMessage.text.text = TRIVIA[Std.random(TRIVIA.length)];
		else
			loadingMessage.text.text = JOKES[Std.random(JOKES.length)];

		var loadingBubble = new GuiImage(ResourceLoader.getResource("data/ui/loading/loading_helpbubble.png", ResourceLoader.getImage, this.imageResources)
			.toTile());
		loadingBubble.horizSizing = Right;
		loadingBubble.vertSizing = Bottom;
		loadingBubble.position = new Vector(51, 109);
		loadingBubble.extent = new Vector(118, 118);
		loadingBody.addChild(loadingBubble);

		var progressMessageLeft = new GuiText(squishney28);
		progressMessageLeft.position = new Vector(169, 396);
		progressMessageLeft.extent = new Vector(700, 32);
		progressMessageLeft.text.text = "Loading Level...";
		progressMessageLeft.text.textColor = 0;
		progressMessageLeft.horizSizing = Center;

		var progressMessageRight = new GuiText(squishney28);
		progressMessageRight.position = new Vector(509, 396);
		progressMessageRight.extent = new Vector(700, 32);
		progressMessageRight.text.text = "Loading..";
		progressMessageRight.text.textColor = 0;
		progressMessageRight.horizSizing = Center;
		progressMessageRight.justify = Right;

		var progress = new GuiProgress();
		progress.vertSizing = Top;
		progress.position = new Vector(100, 392);
		progress.extent = new Vector(838, 34);
		progress.progress = 0.5;
		progress.blendMode = Screen;
		progress.progressColor = 0x02020202;

		setProgress = (progressPz) -> {
			progress.progress = progressPz;
			progressMessageRight.text.text = '${Std.int(progressPz * 100)}%';
		}

		// var cancelButton = new GuiButton(loadButtonImages("data/ui/loading/cancel"));
		// cancelButton.position = new Vector(333, 243);
		// cancelButton.extent = new Vector(112, 59);
		// cancelButton.pressedAction = (sender) -> {
		// 	MarbleGame.instance.quitMission();
		// }

		loadingBody.addChild(progress);
		loadingBody.addChild(progressMessageLeft);
		loadingBody.addChild(progressMessageRight);
		// if (!isMultiplayer)
		// 	loadingGui.addChild(cancelButton);
		// loadingGui.addChild(overlay);
	}

	final TIPS = [
		"Tip: Practice using diagonal movement! You'll need to use it at times in the Advanced and Expert levels.",
		"Tip: Watch out for white flames shooting from the ground. They signal PhysMod triggers, which affect how your marble controls!",
		"Tip: If you're stuck on a difficult level, try practising on some of the easier ones until you're able to complete it.",
		"Tip: Use the Hints button at the bottom of the screen on the level select to check out tips and trivia about the current level. Beating challenge times will unlock further hints!",
		"Tip: Your spin in the air affects how the marble will bounce when it lands. Don't bounce off of the platform you're trying to land on!",
		"Tip: The longer you wait to Super Jump after jumping first, the lower you'll fly.",
		"Tip: Restarting until you have several high-point value Gem spawns in Gem Hunt mode can go a long way towards the Ultimate Score.",
		"Tip: The Gyrocopter is a versatile Powerup. Combine it with different powerups to achieve a low-gravity version of them.",
		"Tip: The Mega Marble Powerup can wreck havoc against your opponents, while the Blast Powerup will throw them away from you. Your Blast becomes more powerful when you're Mega!",
		"Tip: Use the Fireball to destroy ice shards by rolling into them, or use its blast power to get height while destroying some ice shards in the process.",
		"Tip: Nest Eggs in PlatinumQuest are generally much more difficult to find and collect over their Easter Egg counterparts in the other games.",
		"Tip: You can use a Super Speed to slow down, too. Just activate it while facing away from where you're going!",
		"Tip: In PlatinumQuest, unlike other games, respawning on a Checkpoint will cancel a currently-active Time Travel's effects.",
		"Tip: Watching others play may give you tips on how to solve certain challenges.",
		"Tip: All but Orange-banded cannons allow you to aim them and fire at will, at varying power levels. Orange-banded cannons fire the marble instantly in the direction it's facing.",
		"Tip: The Fireball Powerup fizzles out when you touch water or collect a Bubble Powerup. Likewise, the Bubble Powerup pops away when you pick up a Fireball Powerup.",
		"Tip: The Bubble Powerup stays with you at all times until it is used up or you pick up a Fireball Powerup.",
		"Tip: The Sundial Item acts the same way as the Time Travel, it's just a bit fancier.",
		"Tip: PlatinumQuest's Time Travel Items have identifiable bands, gold bands freeze the clock and red bands add time.",
		"Tip: Marble Blast Gold and Platinum's Time Travel Items can be identified by their sand color, yellow sands freeze the clock and red sands add time.",
		"Tip: If you collide with an Ice Shard while in an active Mega Marble, your marble will shrink back to its regular size, but remain unfrozen.",
		"Tip: By activating a Mega Marble Powerup right before hitting a high-friction floor, you can get a crazy speed boost.",
		"Tip: If you collect all the gems in a Gem Madness level before the time limit runs out, you will be scored based on how much time remains on the clock.",
		"Tip: Buttons do useful things, such as activate moving platforms. It's possible to use them in elaborate puzzles...",
		"Tip: You can start the level at near full speed by rolling and jumping during the Ready-Set-Go sequence. Time a jump so you hit the start pad on 'Go!' for the best result.",
		"Tip: Moving diagonally is faster than moving straight forward. Jumping repeatedly while moving will further increase the marble's speed.",
		"Tip: The Marble Blast Forums have an 'Advanced Techniques' thread which lists out every technique known in this game, and how it works.",
		"Tip: Head over to the MarbleBlast.com Website to download more mods for Marble Blast!",
		"Tip: Help Bubbles contain useful messages that appear on the bottom of the screen. These messages often give hints on how to beat an upcoming challenge.",
		"Tip: Hints are available in PlatinumQuest and many Custom levels.",
		"Tip: Standard gem point values for Hunt and Gem Madness:\nRed = 1 Point\nYellow = 2 Points\nBlue = 5 Points\nPlatinum = 10 Points",
		"Tip: Make sure to play all Tutorial and Beginner levels, as they teach you all the basics you need to know for PlatinumQuest.",
		"Tip: Ice Shards can be used to instantly stop you if you're going too fast.",
		"Tip: Jumping on low-friction surfaces can give you more control.",
		"Tip: Grass, Sand and Water friction floors reduce the marble's bounce height, making for a perfect landing place.",
		"Tip: When creating a recording, it will automatically restart itself until you beat the level or exit it. You can always replay the level and a new recording will be made.",
		"Tip: If you get a World Record, the game will automatically upload a recording to the server.",
		"Tip: If you fall Out of Bounds, press the powerup key to respawn faster! In Hunt levels, if you're carrying a powerup, it will not be consumed.",
		"Tip: Besides filling the Blast Meter to its maximum power, the Ultra Blast PowerUp gives you a small 3% boost!",
		"Tip: Mega Marbles are very useful for collecting loads of tightly-packed Gems.",
		"Tip: The Fireball powerup takes priority over the standard Blast. If you immediately activate Blast after using Fire Blast, then your boost will be much bigger.",
		"Tip: If you enter a Cannon as a Mega Marble, it will shrink your marble back down to size. We can't have you clogging the cannons!",
		"Tip: Join our official Discord server to interact directly with the community, get links to live streams, and access new user-created content faster than ever! You can find a link to it at marbleblast.com/webchat or from the community tab only if you're logged in.",
		"Tip: Check out 'Marble It Up! Ultra' on PC and console! The Steam version even has its own Workshop.",
		"Tip: Check out 'Great Marble Adventure' on Steam!",
		"Tip: Check out 'Lost Marbles' on Steam!",
		"Tip: Check out 'Custom Levels' in the Community section of the Main Menu! You'll be able to download and play custom levels all from ingame!",
		"Tip: Want to upload your custom levels for people to play? Head to marbleland.vaniverse.io!",
		"Tip: You'll gain more height from a Super Jump, Blast, or wall hit by using them immediately after jumping, rather than at the peak of your jump.",
		"Tip: The Shock Absorber overrides the Super Bounce. Every time.",
		"Tip: Blast will always send you straight upwards. This makes it useful for turning around on sloped surfaces where jumps would push you sideways.",
		"Tip: Never forget where you left your Teleporter PowerUp's destination!",
		"Tip: Be careful! Falling Out of Bounds will remove your Teleporter PowerUp's destination, even if you've reached a Checkpoint!"
	];

	final JOKES = [
		"Tip: Always stay up until 5am writing silly tips.",
		"Tip: Never assume that Batman eats nachos.",
		"Tip: Don't forget to brush your teeth.",
		"Tip: Don't forget to floss!",
		"Tip: Never Eat Shredded Wheat.",
		"Tip: Pablo Vasquez is an anagram of Bosque Lav Zap.",
		"Tip: After eight years of development on PlatinumQuest, we can in fact confirm that yes, marbles do roll.",
		"Tip: This is not a tip.",
		"Tip: Threefolder didn't create Three-Fold Maze.",
		"Tip: Eat a banana every day.",
		"Tip: Sometimes, light speed is too slow.",
		"Tip: About 20% if you're American.",
		"Tip: Say Challenge one more time, I dare you!",
		"Tip: A crash is imminent. Prepare to send your console.log file.",
		"Tip: This tip is as dank as the memes about PlatinumQuest",
		"Tip? Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed ullamcorper blandit justo, id ornare mi venenatis consectetur. Aliquam eget quam ante. In maximus condimentum odio.",
		"Tip: Matan needs to stop watching How It's Made food videos and work on this game.",
		"Tip: IT'S TIME TO D-D-D-D-D-DUEL!!",
		"Tip: MEGA MARBLE KIDS!!",
		"Tip: Playing against Threefolder in Multiplayer may result in the spamming of the 'Blue Steal' taunt.",
		"Tip: STOOL PARTY YEEEAAAHHH!!",
		"Tip: It's 2:50am. Do you know where your programmer is?",
		"Tip: JOHN CENA!!",
		"Tip: Hi, Mom!",
		"Tip: Puns make everything punstatic!",
		"Tip: Fetch, Stash, Pull with Rebase, Pop, Resolve Conflicts",
		"Tip: Type 'party' on the main menu to have a party.",
		"Tip: Writing these tips crashed the game.",
		"Tip: IT WAS COLD, BRO!",
		"Tip: up, up, down, down, left, right, left, right, B, A",
		"Tip: We gave up on the changelog. Stuff got added, stuff got fixed, stuff was deleted, and we probably crashed the game a thousand times, give or take.",
		"Tip: HIGUY BUG CRASH",
		"Tip: GO MARBLE DUDE!!",
		"Tip: This still isn't cannon.cs",
		"Tip: Just Monika.",
		"Tip: Refer to this game as 'Marble Blast Platinum Quest' instead of just 'PlatinumQuest' to bother Matan.",
		"Tip: After eight years in development, hopefully PQ will have been worth the weight.",
		"Tip: I bet that doesn't sound good from downstairs.",
		"u",
		"Tip: free jojo",
		"Tip: Marble Blast Instant Marble Gaming Promotion! Type marble to order a free marble courtesy of Matan's Marbles!",
		"I don't think you need any hints today.",
		"Tip: OOB Is Defeat. Finish Without Gem Is Win. Marble Eat Gem. Marble Is You.",
		"Tip: Struggling to set a new best time? Try going faster!",
		"Tip: @everyone welcome UNDERTALE",
		"Trivia: Every loading tip has an 80% chance to be a tip, a 17% chance to be trivia, or a 3% chance to be a joke. You just wasted one of your rare 3% chances on this fact.",
		"Tip: lol lol lol jij jaj jej joj jvj jcj jqj joj jkj",
		"Tip: On a platinum quest to do my platinum best.",
		"/tableflip PQ crashed! ...Whoops, sorry, force of habit.",
		"Tip: She platinum on my marble 'til I blast.",
		"Tip: Chess Battle Advanced",
		"Tip: There's a super secret setting outside of the options menu! On the main menu, if you hit the 'Quit' button one time, it toggles the game.",
		"Tip: SUPER. HOT.",
		"Tip: Press Space Bar to open volume view! This will let you see the level in 3 dimensions at a time.",
		"Tip: Upon taking damage, marbles will give you a 10% chance to swallow your currently held trinket and gain its effects permanently.",
		"Tip: It's rude to talk about someone who's listening.",
		"Tip: mew!",
		"Tip: Don't try using any hidden cheat codes. It's not going to work."
	];

	final TRIVIA = [
		"Trivia: Scrapped Powerups in development include the Wings, which would have granted some form of flight, and Marbledude, which increased the effects of other Powerups and negated hazards.",
		"Trivia: Most levels were originally going to be locked, and the goal was to make your own way through the levels. This was scrapped.",
		"Trivia: One of the original ideas was to create an overworld with a map consisting of the level images, and lines that drew paths between these levels. Beat levels that lead to others, and thus unlock the later ones.",
		"Trivia: The Mega Marble was originally going to appear in PlatinumQuest levels as a standard powerup.",
		"Trivia: PlatinumQuest levels don't feature rug, carpet, tarmac, random force, or magnets.",
		"Trivia: PlatinumQuest started as an update to Marble Blast Platinum, then turned into a standalone mod, and then returned to being an update to Platinum.",
		"Trivia: It's easier to make broken new features than to fix bugs. We learned this the hard way.",
		"Trivia: In older versions of the game, a buffer overflow caused missions with long help texts to eat up your entire hard drive with an insanely huge mission file.",
		"Trivia: PlatinumQuest was designed to be easier than Marble Blast Platinum, but there are still a few levels that will cause you to scratch your head.",
		"Trivia: Alex Swanson, the creator of most of Marble Blast Gold's levels, donated two never-before-seen levels to PlatinumQuest -- Gravity Tower, and an old version of Skate Battle Royale, known in-game as Skate Park Square.",
		"Trivia: PlatinumQuest was designed to not use edge-hitting or trap-launching in any way in the level design, save for one level. Can you guess which one?",
		"Trivia: Almost every one of Matan's levels uses level-specific code. A huge headache to HiGuy, to say the least.",
		"Trivia: PlatinumQuest had a development hiatus between 2012 and 2015. Matan was the only developer that stuck with the project from its inception in 2009 to its completion in 2017.",
		"Trivia: Tilo was originally in Marble Blast Advanced and was re-created by Kwill on request for Multiplayer. It's epic fun!",
		"Trivia: If you say 'Marble Blast PlatinumQuest', Matan will be thrown into a raging fit. PlatinumQuest does not have 'Marble Blast' in front of it.",
		"Trivia: Checkpoints were coded and added to Marble Blast Platinum two weeks before its first full release to the public.",
		"Trivia: The original error message noise was in fact Matan screaming 'Spy', referring to Spy47 who originally coded the Online section.",
		"Trivia: Due to a programming oversight, Marble Blast Platinum used to be able to delete any file or folder from a user's computer, including system files and folders.",
		"Trivia: The Sundial item was originally created as a replacement to the Time Travel item, but after MadMarioSkills created the new Time Travel model, it was simply used for variety instead.",
		"Trivia: Negative Time Travels are actually called Time Penalty Items.",
		"Trivia: PlatinumQuest has three main themes to its levels: regular, garden and construction, all with textures, scenery items and more to go along with them.",
		"Trivia: Levels can be created using multiple simultaneous modes. The most complex level you can make is a 2D, Quota, Laps, Haste and Consistency level. Why not give it a shot?",
		"Trivia: A Pinball gamemode was in the works along with levels to go with it, but was dropped. Multi-ball, Extra Ball and other Powerups were actually possible.",
		"Trivia: Some of the standard features in PlatinumQuest started as one-time custom codes for Matan.",
		"Trivia: Thanks to Torque's terrible time storage, if a server had an uptime of 24 days, the time would become negative.",
		"Trivia: One of the dropped gamemodes was called 'Distance', where you had to travel a certain distance before being allowed to finish the level. No end pad required.",
		"Trivia: Most of PlatinumQuest's code was rewritten starting in 2015 to support Multiplayer.",
		"Trivia: In rare cases, Moving Objects may magically disappear.",
		"Trivia: The current version of Multiplayer is actually the 8th version of a protocol that started in Marble Blast Emerald, a mod headed by Jeff and HiGuy.",
		"Trivia: The shader model in PlatinumQuest uses Flat Shading with Blinn-Phong specular highlights.",
		"Trivia: The joystick remapping tip is hard-coded to show up when you first plug in a joystick.",
		"Trivia: PlatinumQuest's scripts contain over 115,000 lines of code. The extender adds another 50,000 lines. That is almost 4 times as many lines of code as in Marble Blast Gold!",
		"Trivia: It's been over 15 years and we still don't have a better version of map2dif. However, we do have csx2dif, which is like map2dif but for .csx files (and it's also better).",
		"Trivia: PlatinumQuest was coded almost entirely in Sublime Text.",
		"Trivia: Over the course of development, PlatinumQuest has used two different gits and one subversion repository.",
		"Trivia: Most of Matan's levels have a lot of shapes and triggers data in the interior, as he didn't want to use the Level Editor for alignment purposes. That worked somewhat, but not as well as he wanted.",
		"Trivia: Marble Blast Platinum originally started as a mini-mod that was supposed to include only 30 levels and be based within Marble Blast Gold. Matan caused it to become bigger, much to Phil's displeasure.",
		"Trivia: Alex Swanson helped create the original code for the Ultimate Time.",
		"Trivia: The Help Bubble was originally created as a replacement for the Help Trigger, but later on in development, the Bubble's features were added to the Help Trigger. Both are used in stock PlatinumQuest levels, but unmarked Help Triggers are rare.",
		"Trivia: Two friction floors that were never added to Platinum or PlatinumQuest are the frictionless floor from Oaky (0 in friction) and a super-bouncy one, with 500 units put into force.",
		"Trivia: Throughout the years, the fonts that were mainly used in the game had changed from Arial to DomCasualD to Marker Felt to Whitney. Next stop: Wingdings.",
		"Trivia: Challenges and Super Challenges appeared in Marble Blast Platinum 1.50, but were removed with PlatinumQuest's release. They were very buggy and crashed really badly.",
		"Trivia: Before the physics-based Challenges currently in the game, Challenges used to involve racing 1-3 opponents through a series of up to 10 levels in real time. A similar singleplayer feature can be seen when playing through an entire pack on Marbleland.",
		"Trivia: The Out of Bounds taunt messages used to purposely crash your game whenever you reached a certain multiple of OOBs.",
		"Trivia: The community, historically, views the unseen Marblaxia as the Marble's arch-enemy. The planet where the Marble 'lives' is Marblius.",
		"Trivia: A feature that was cut was a Random Initial Position for Moving Platforms, so that they started in different spots on their path when the level was loaded (and restarted). Unsurprisingly it was requested by Matan for a laps level of his that never materialised.",
		"Trivia: Additional collectibles that were cut are Coins and Stars. Coins helped you unlock marble skins and levels, while collecting all Stars would unlock special levels that use a new Powerup, called Wings. Both had shapes and were collectible before their removal in 2015.",
		"Trivia: Cannon.cs caused more issues than we'd like to admit in just about every stage of development.",
		"Trivia: Due to how the Online rating system works, Arctic Inferno can technically award the player 31,883,030 points for destroying all Ice Shards. Due to the time limit, it's not possible to achieve such a score.",
		"Trivia: There are more than 100 ghost sounds! Talk about spooky entertainment!",
		"Trivia: Winterfest was developed in 3 days! It drained our energy very quickly, as bugs were patched only days after released.",
		"Trivia: Frightfest was developed a week before its first launch. We learned nothing from the Winterfest event.",
		"Trivia: PlatinumQuest's Ice friction is 0.07331 in value, which is Matan's way of putting leet speek in backwards. MEMES!",
		"Trivia: PlatinumQuest has seen three seperate development teams throughout its existence. One from 2007 to 2012, one from 2015 to 2021, and one from 2021 to now.",
	];
}
