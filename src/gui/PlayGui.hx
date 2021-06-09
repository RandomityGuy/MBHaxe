package gui;

import h2d.Anim;
import h2d.Bitmap;
import src.ResourceLoader;

class PlayGui {
	var scene2d:h2d.Scene;

	public function new() {}

	var numbers:Array<Anim> = [];
	var timerPoint:Bitmap;
	var timerColon:Bitmap;

	public function init(scene2d:h2d.Scene) {
		this.scene2d = scene2d;

		var numberTiles = [];
		for (i in 0...10) {
			var tile = ResourceLoader.getImage('data/ui/game/numbers/${i}.png').toTile();
			numberTiles.push(tile);
		}

		for (i in 0...7) {
			numbers.push(new Anim(numberTiles, 0, scene2d));
		}

		timerPoint = new Bitmap(ResourceLoader.getImage('data/ui/game/numbers/point.png').toTile(), scene2d);
		timerColon = new Bitmap(ResourceLoader.getImage('data/ui/game/numbers/colon.png').toTile(), scene2d);
		initTimer();
	}

	public function initTimer() {
		var screenWidth = scene2d.width;
		var screenHeight = scene2d.height;

		function toScreenSpaceX(x:Float) {
			return screenWidth / 2 - (234 / 2) + x;
		}
		function toScreenSpaceY(y:Float) {
			return (y / 480) * screenHeight;
		}

		numbers[0].x = toScreenSpaceX(23);
		numbers[1].x = toScreenSpaceX(47);
		timerColon.x = toScreenSpaceX(67);
		numbers[2].x = toScreenSpaceX(83);
		numbers[3].x = toScreenSpaceX(107);
		timerPoint.x = toScreenSpaceX(127);
		numbers[4].x = toScreenSpaceX(143);
		numbers[5].x = toScreenSpaceX(167);
		numbers[6].x = toScreenSpaceX(191);
	}
}
