package gui;

import src.TimeState;
import gui.GuiControl.MouseState;
import h3d.Vector;
import h2d.Tile;
import h3d.mat.DepthBuffer;
import h2d.Scene;
import h2d.Bitmap;
import h3d.mat.Texture;
import src.ResourceLoader;
import src.DtsObject;

class GuiObjectShow extends GuiControl {
	var scene:h3d.scene.Scene;
	var sceneTarget:Texture;

	public var sceneObject:DtsObject;
	public var renderDistance:Float = 3;
	public var renderPitch:Float = 0;
	public var visible:Bool;

	var sceneBitmap:Bitmap;
	var _initialized:Bool = false;

	var timeState = new TimeState();

	public function new() {
		super();
		scene = new h3d.scene.Scene();
		timeState.currentAttemptTime = 0;
		timeState.dt = 0;
		timeState.gameplayClock = 0;
		timeState.timeSinceLoad = 0;
	}

	public override function render(scene2d:Scene) {
		var renderRect = getRenderRectangle();
		init(renderRect);
		if (scene2d.contains(sceneBitmap))
			scene2d.removeChild(sceneBitmap);
		if (visible)
			scene2d.addChild(sceneBitmap);
		sceneBitmap.x = renderRect.position.x;
		sceneBitmap.y = renderRect.position.y;
		sceneBitmap.width = renderRect.extent.x;
		sceneBitmap.height = renderRect.extent.y;
		super.render(scene2d);
	}

	public override function update(dt:Float, mouseState:MouseState) {
		super.update(dt, mouseState);
		timeState.currentAttemptTime += dt;
		timeState.timeSinceLoad += dt;
		timeState.dt = dt;
		sceneObject.update(timeState);
	}

	function init(targetRect:Rect) {
		if (!_initialized) {
			sceneTarget = new Texture(cast targetRect.extent.x, cast targetRect.extent.y, [Target]);
			sceneTarget.depthBuffer = new DepthBuffer(cast targetRect.extent.x, cast targetRect.extent.y);

			sceneBitmap = new Bitmap(Tile.fromTexture(sceneTarget));

			scene.addChild(sceneObject);
			var objCenter = sceneObject.getBounds().getCenter();
			scene.camera.pos = new Vector(0, renderDistance * Math.cos(renderPitch), objCenter.z + renderDistance * Math.sin(renderPitch));
			scene.camera.target = new Vector(objCenter.x, objCenter.y, objCenter.z);
			_initialized = true;
		}
	}

	public override function renderEngine(engine:h3d.Engine) {
		if (_initialized) {
			engine.pushTarget(this.sceneTarget);
			engine.clear(0, 1);
			scene.render(engine);
			engine.popTarget();
		}
		super.renderEngine(engine);
	}

	override function dispose() {
		super.dispose();
		scene.dispose();
		sceneBitmap.remove();
		sceneTarget.dispose();
	}
}
