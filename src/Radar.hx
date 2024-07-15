package src;

import hxd.res.BitmapFont;
import h3d.Matrix;
import src.DtsObject;
import h3d.Vector;
import gui.Graphics;
import src.GameObject;
import h2d.Scene;
import src.MarbleWorld;
import src.Util;
import src.Marble;
import src.Settings;
import src.ResourceLoader;

class Radar {
	var level:MarbleWorld;
	var scene2d:Scene;

	var g:Graphics;

	var marbleNameTexts:Map<Marble, h2d.Text>;

	public var ellipseScreenFraction = new Vector(0.79, 0.85);
	public var fullArrowLength = 60.0;
	public var fullArrowWidth = 40.0;
	public var maxArrowAlpha = 0.6;
	public var maxTargetAlpha = 0.4;
	public var minArrowFraction = 0.4;

	var radarTiles:Array<h2d.Tile>;

	var time:Float = 0.0;

	var _dirty = false;

	public function new(level:MarbleWorld, scene2d:Scene) {
		this.level = level;
		this.scene2d = scene2d;
		this.marbleNameTexts = [];
		var radarTileRedGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemRed.png").resource.toTile();
		var radarTileYellowGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemYellow.png").resource.toTile();
		var radarTileBlueGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemBlue.png").resource.toTile();
		var radarTileGreenGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemGreen.png").resource.toTile();
		var radarTileOrangeGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemOrange.png").resource.toTile();
		var radarTilePinkGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemPink.png").resource.toTile();
		var radarTilePurpleGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemPurple.png").resource.toTile();
		var radarTileTurquoiseGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemTurquoise.png").resource.toTile();
		var radarTileBlackGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemBlack.png").resource.toTile();
		var radarTilePlatinumGem = ResourceLoader.getImage("data/ui/mp/radar/GemItemPlatinum.png").resource.toTile();
		var radarTileEndPad = ResourceLoader.getImage("data/ui/mp/radar/EndPad.png").resource.toTile();
		radarTiles = [
			radarTileRedGem, radarTileYellowGem, radarTileBlueGem, radarTileGreenGem, radarTileOrangeGem, radarTilePinkGem, radarTilePurpleGem,
			radarTileTurquoiseGem, radarTileBlackGem, radarTilePlatinumGem, radarTileEndPad
		];
		for (tile in radarTiles) {
			tile.scaleToSize(tile.width * Settings.uiScale, tile.height * Settings.uiScale);
		}
	}

	public function init() {
		g = new Graphics(scene2d);
	}

	public function update(dt:Float) {
		time += dt;
		_dirty = true;
	}

	public function render(doRender) {
		if (!_dirty)
			return;
		g.clear();
		if (!doRender) {
			for (marble => marbleName in marbleNameTexts) {
				if (marbleName != null)
					marbleName.alpha = 0;
			}
			return;
		}
		var gemCount = 0;
		for (gem in level.gems) {
			if (!gem.pickedUp) {
				renderArrow(gem.boundingCollider.boundingBox.getCenter().toVector(), gem.radarGemColor, radarTiles[gem.radarGemIndex]);
				gemCount++;
			}
		}
		if (@:privateAccess level.endPad != null && gemCount == 0) {
			renderArrow(@:privateAccess level.endPad.getAbsPos().getPosition(), 0xE6E6E6, radarTiles[10]);
		}
		var fadeDistance = level.scene.camera.zFar * 0.1;
		for (marble => marbleName in marbleNameTexts) {
			if (marbleName != null)
				marbleName.alpha = 0;
		}
		for (marble in level.marbles) {
			if (marble != level.marble) {
				var shapePos = @:privateAccess marble.lastRenderPos.clone();
				var shapeDir = shapePos.sub(level.scene.camera.pos);
				var shapeDist = shapeDir.lengthSq();
				if (shapeDist == 0 || shapeDist > level.scene.camera.zFar * level.scene.camera.zFar) {
					dontRenderName(marble);
					continue;
				}
				var validProjection = frustumHasPoint(level.scene.camera.frustum, shapePos);
				if (!validProjection) {
					dontRenderName(marble);
					continue;
				}
				shapePos.z += 0.5; // Vertical offset

				var projectedPos = level.scene.camera.project(shapePos.x, shapePos.y, shapePos.z, scene2d.width, scene2d.height);
				var opacity = (shapeDist < fadeDistance) ? 1.0 : (1.0 - (shapeDist - fadeDistance) / (level.scene.camera.zFar - fadeDistance));
				renderName(projectedPos, marble, opacity);
			}
		}
		_dirty = false;
	}

	public function blink() {
		time = 0;
	}

	public function reset() {
		time = 0;
		g.clear();
	}

	public function dispose() {
		g.clear();
		scene2d.removeChild(g);
		g = null;
		for (txt in marbleNameTexts) {
			if (txt != null) {
				scene2d.removeChild(txt);
			}
		}
		marbleNameTexts = null;
	}

	inline function planeDistance(plane:h3d.col.Plane, p:Vector) {
		return @:privateAccess plane.nx * p.x + @:privateAccess plane.ny * p.y + @:privateAccess plane.nz * p.z - @:privateAccess plane.d;
	}

	function frustumHasPoint(frustum:h3d.col.Frustum, p:Vector) {
		if (planeDistance(frustum.pleft, p) < 0)
			return false;
		if (planeDistance(frustum.pright, p) < 0)
			return false;
		if (planeDistance(frustum.ptop, p) < 0)
			return false;
		if (planeDistance(frustum.pbottom, p) < 0)
			return false;
		if (frustum.checkNearFar) {
			if (planeDistance(frustum.pnear, p) < 0)
				return false;
			if (planeDistance(frustum.pfar, p) < 0)
				return false;
		}
		return true;
	}

	function renderArrow(pos:Vector, color:Int, tile:h2d.Tile) {
		var validProjection = frustumHasPoint(level.scene.camera.frustum, pos);
		var projectedPos = level.scene.camera.project(pos.x, pos.y, pos.z, scene2d.width, scene2d.height);

		if (validProjection && tile != null) {
			g.lineStyle(0, 0, 0);
			g.beginTileFill(projectedPos.x - tile.width / 2, projectedPos.y - tile.height / 2, Settings.uiScale, Settings.uiScale, tile);
			g.drawRect(projectedPos.x - tile.width / 2, projectedPos.y - tile.height / 2, tile.width, tile.height);
			g.endFill();
		} else if (!validProjection) {
			var centerDiff = projectedPos.sub(new Vector(scene2d.width / 2, scene2d.height / 2));

			var theta = Math.atan2(centerDiff.y, centerDiff.x);
			if (projectedPos.z > 1)
				theta += Math.PI;

			var ellipsePos = new Vector(scene2d.width * (ellipseScreenFraction.x * Math.cos(theta) + 1) / 2,
				scene2d.height * (ellipseScreenFraction.y * Math.sin(theta) + 1) / 2);
			var arrowDir = projectedPos.sub(new Vector(scene2d.width / 2, scene2d.height / 2)).normalized();
			var arrowDirPerp = new Vector(-arrowDir.y, arrowDir.x);
			if (projectedPos.z > 1)
				arrowDir.scale(-1);

			var tipPosition = ellipsePos.add(arrowDir.multiply(fullArrowLength));
			var tipUpperPosition = ellipsePos.add(arrowDirPerp.multiply(fullArrowWidth / 2));
			var tipLowerPosition = ellipsePos.add(arrowDirPerp.multiply(-fullArrowWidth / 2));

			g.beginFill(color, 0.6);
			g.lineStyle(1, 0, 0.6);
			g.moveTo(tipPosition.x, tipPosition.y);
			g.lineTo(tipUpperPosition.x, tipUpperPosition.y);
			g.lineTo(tipLowerPosition.x, tipLowerPosition.y);
			g.endFill();
		}
	}

	function renderName(pos:Vector, marble:Marble, opacity:Float) {
		if (!marbleNameTexts.exists(marble)) {
			var markerFelt32fontdata = ResourceLoader.getFileEntry("data/font/MarkerFelt.fnt");
			var markerFelt32b = new BitmapFont(markerFelt32fontdata.entry);
			@:privateAccess markerFelt32b.loader = ResourceLoader.loader;
			var markerFelt18 = markerFelt32b.toSdfFont(cast 14 * Settings.uiScale, MultiChannel);
			var txt = new h2d.Text(markerFelt18, scene2d);
			marbleNameTexts.set(marble, txt);
			txt.textColor = 0xFFFF00;
		}
		var textObj = marbleNameTexts.get(marble);
		textObj.text = @:privateAccess marble.connection.getName();
		textObj.setPosition(pos.x - textObj.textWidth / 2, pos.y - textObj.textHeight);
		textObj.alpha = opacity;
	}

	function dontRenderName(marble:Marble) {
		if (marbleNameTexts.exists(marble)) {
			var el = marbleNameTexts.get(marble);
			el.alpha = 0;
		}
	}
}
