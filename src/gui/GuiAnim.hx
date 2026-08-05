package gui;

import h2d.Anim;
import h2d.Scene;
import h2d.Tile;
import h2d.Bitmap;
import src.MarbleGame;

@:publicFields
class GuiAnim extends GuiControl {
	var anim:Anim;

	public function new(textures:Array<Tile>) {
		super();
		this.anim = new Anim(textures, 0);
	}

	public override function render(scene2d:Scene, ?parent:h2d.Flow) {
		if (parent != null) {
			if (parent.contains(this.anim)) {
				parent.removeChild(this.anim);
			}
			parent.addChild(this.anim);
			var off = this.getOffsetFromParent();
			var props = parent.getProperties(this.anim);
			props.isAbsolute = true;
			this.anim.setPosition(off.x, off.y);
		}

		var renderRect = this.getRenderRectangle();
		// anim.setPosition(Math.floor(renderRect.position.x), Math.floor(renderRect.position.y));
		anim.scaleX = renderRect.extent.x / anim.getFrame().width;
		anim.scaleY = renderRect.extent.y / anim.getFrame().height;
		// if (scene2d.contains(anim)) {
		// 	scene2d.removeChild(anim); // Refresh "layer"
		// }
		// scene2d.addChild(anim);
		super.render(scene2d, parent);
	}

	public override function dispose() {
		super.dispose();
		this.anim.remove();
	}

	public override function onRemove() {
		super.onRemove();
		if (MarbleGame.canvas.scene2d.contains(anim)) {
			MarbleGame.canvas.scene2d.removeChild(anim); // Refresh "layer"
		}
		this.anim.remove();
	}
}
