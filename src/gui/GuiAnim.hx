package gui;

import h2d.Anim;
import h2d.Scene;
import h2d.Tile;
import h2d.Bitmap;

@:publicFields
class GuiAnim extends GuiControl {
	var anim:Anim;

	public function new(textures:Array<Tile>) {
		super();
		this.anim = new Anim(textures, 0);
	}

	public override function render(scene2d:Scene) {
		var renderRect = this.getRenderRectangle();
		anim.setPosition(renderRect.position.x, renderRect.position.y);
		anim.scaleX = renderRect.extent.x / anim.getFrame().width;
		anim.scaleY = renderRect.extent.y / anim.getFrame().height;
		if (!scene2d.contains(anim))
			scene2d.addChild(anim);
		super.render(scene2d);
	}

	public override function dispose() {
		super.dispose();
		this.anim.remove();
	}
}
