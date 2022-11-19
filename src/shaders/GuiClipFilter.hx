package shaders;

import h3d.Vector;
import h2d.Mask;
import h2d.filter.Shader;
import h2d.Object;
import h2d.col.Bounds;
import h2d.col.Point;
import gui.Rect;
import h2d.RenderContext;
import h2d.filter.Filter;

class GuiClipFilter extends Filter {
	public var renderRect:Rect;

	public function new(rect:Rect) {
		super();
		this.renderRect = rect;
	}

	override function draw(ctx:RenderContext, t:h2d.Tile) {
		var tout = ctx.textures.allocTileTarget("guiClip", t);
		ctx.pushTarget(tout);
		ctx.flush();
		ctx.clipRenderZone(renderRect.position.x, renderRect.position.y, renderRect.extent.x, renderRect.extent.y);
		h3d.pass.Copy.run(t.getTexture(), tout);
		ctx.flush();
		ctx.popRenderZone();
		ctx.popTarget();
		return h2d.Tile.fromTexture(tout);
	}
}
