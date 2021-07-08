// MIT License
// Copyright (c) 2018 Pavel Alexandrov
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
package fs;

import h2d.Graphics;
import h2d.Text;
import hxd.Math;
import fs.ManifestLoader;

class ManifestProgress extends h2d.Object {
	var g:h2d.Graphics;
	var text:h2d.Text;

	var loader:ManifestLoader;
	var color:Int;
	var onLoaded:Void->Void;

	var totalBarHeight:Float;
	var subBarHeight:Float;
	var barWidth:Float;

	public var removeSelf:Bool = true;

	public function new(loader:ManifestLoader, color:Int = 0xffffff, onLoaded:Void->Void, ?parent:h2d.Object) {
		super(parent);
		this.loader = loader;
		this.color = color;
		this.onLoaded = onLoaded;

		g = new Graphics(this);
		text = new Text(hxd.res.DefaultFont.get(), this);
		text.y = 50;
		text.textAlign = Center;
		text.textColor = 0xff000000 | color;
	}

	public function start():Void {
		var s2d = getScene();
		var x = s2d.width * .1;
		barWidth = s2d.width * .8;
		totalBarHeight = Math.max(s2d.height * .02, 4);
		subBarHeight = Math.max(s2d.height * .01, 2);
		var barH = totalBarHeight + (subBarHeight + 2) * ManifestLoader.concurrentFiles;
		g.y = (s2d.height - (barH + 4 + (text.font.lineHeight + text.lineSpacing) * 2)) / 2;
		g.x = x;
		text.y = g.y + barH + 4;
		text.x = x;
		text.maxWidth = barWidth;

		loader.onLoaded = finish;
		loader.onFileLoadStarted = showFileName;
		loader.onFileLoadStarted = fileLoaded;
		loader.onFileProgress = fileProgress;
		loader.loadManifestFiles();
	}

	function repaint() {
		g.clear();

		g.beginFill(color);
		g.drawRect(0, 0, barWidth * (loader.loadedFiles / loader.totalFiles), totalBarHeight);

		var txt = "Files: " + loader.loadedFiles + "/" + loader.totalFiles + "\n";
		if (loader.tasks != null)
			for (t in loader.tasks) {
				if (t.busy) {
					var ratio = t.loaded / t.total;
					g.drawRect(0, totalBarHeight + 2 + t.slot * (2 + subBarHeight), barWidth * ratio, subBarHeight);
					txt += t.entry.name + " " + Math.ceil(ratio * 100) + "% ";
				} else {
					g.drawRect(0, totalBarHeight + 2 + t.slot * (2 + subBarHeight), barWidth, subBarHeight);
				}
			}

		text.text = txt;
	}

	function setProgress(b:Int, t:Int):Void {
		g.clear();
		var s = getScene();
		var size = s != null ? s.width * .5 : 400;
		g.beginFill(color);
		g.drawRect(0, 0, loader.loadedFiles / loader.totalFiles * size, 20);
		if (b != 0 && t != 0)
			g.drawRect(0, 25, b / t * size, 20);
	}

	function finish():Void {
		// setProgress(1, 1);
		repaint();
		text.text = "All done!";
		if (removeSelf)
			remove();
		onLoaded();
	}

	function showFileName(task:LoaderTask) {
		repaint();
		// text.text = "Loading: " + task.entry.path;
	}

	function fileLoaded(task:LoaderTask) {
		repaint();
		// setProgress(1, 1);
		// text.text = "Loaded : " + task.entry.path;
	}

	function fileProgress(task:LoaderTask) {
		repaint();
		// setProgress(task.loaded, task.total);
	}
}
