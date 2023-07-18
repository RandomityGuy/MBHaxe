class RandomLCG {
	var seed:Int;

	static var msSeed:Int = 1376312589;

	static var quotient = 127773;
	static var remainder = 2836;

	public function new(seed = -1) {
		this.seed = (seed == -1) ? generateSeed() : seed;
	}

	inline function generateSeed() {
		// A very, VERY crude LCG but good enough to generate
		// a nice range of seed values
		msSeed = (msSeed * 0x015a4e35) + 1;
		msSeed = (msSeed >> 16) & 0x7fff;
		return (msSeed);
	}

	public function setSeed(seed:Int) {
		this.seed = seed;
	}

	public function randInt() {
		if (seed <= quotient)
			seed = (seed * 16807) % 2147483647;
		else {
			var high_part:Int = Std.int(seed / quotient);
			var low_part = seed % quotient;

			var test:Int = (16807 * low_part) - (remainder * high_part);

			if (test > 0)
				seed = test;
			else
				seed = test + 2147483647;
		}
		return seed;
	}

	public function randFloat() {
		return randInt() / 2147483647.0;
	}

	public function randRange(i:Int, n:Int) {
		return (i + (randInt() % (n - i + 1)));
	}

	public function randRangeF(i:Float, n:Int) {
		return (i + (n - i) * randFloat());
	}
}
