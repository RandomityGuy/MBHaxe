package src;

import shapes.Gem;
import shapes.SuperSpeed;
import shapes.SuperJump;
import shapes.AnvilItem;
import shapes.Blast;
import shapes.BubbleItem;
import shapes.FireballItem;
import shapes.Helicopter;
import shapes.MegaMarble;
import shapes.RandomPowerup;
import shapes.TeleportItem;
import shapes.TimeTravel;
import shapes.SuperBounce;
import shapes.ShockAbsorber;
import shapes.AntiGravity;
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
import shapes.PowerUp;
import shapes.Cannon;

enum abstract RadarRule(Int) from Int to Int {
	var None = 0;
	var Gems = 1 << 0;
	var TimeTravels = 1 << 1;
	var EndPad = 1 << 2;
	var Checkpoints = 1 << 3;
	var Cannons = 1 << 4;
	var Powerups = 1 << 5;
}

@:structInit
@:publicFields
class RadarItem {
	var obj:DtsObject;
	var dist:Float;
	var used:Bool;
	var index:Int;
}

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

	public var itemSearchDistance:Float = 50.0;
	public var gemFinishSearchDistance:Float = 50000.0;

	public var customRadarRule:Int = RadarRule.Gems | RadarRule.EndPad;

	var maxRadarItems = 25;

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
		var radarTileAntiGravity = ResourceLoader.getImage("data/ui/mp/radar/AntiGravityItem.png").resource.toTile();
		var radarTileAnvil = ResourceLoader.getImage("data/ui/mp/radar/AnvilItem.png").resource.toTile();
		var radarTileBlast = ResourceLoader.getImage("data/ui/mp/radar/BlastItem.png").resource.toTile();
		var radarTileBubble = ResourceLoader.getImage("data/ui/mp/radar/BubbleItem.png").resource.toTile();
		var radarTileCandyBlue = ResourceLoader.getImage("data/ui/mp/radar/CandyItemBlue.png").resource.toTile();
		var radarTileCandyRed = ResourceLoader.getImage("data/ui/mp/radar/CandyItemRed.png").resource.toTile();
		var radarTileCandyYellow = ResourceLoader.getImage("data/ui/mp/radar/CandyItemYellow.png").resource.toTile();
		var radarTileCannon = ResourceLoader.getImage("data/ui/mp/radar/Cannon.png").resource.toTile();
		var radarTileCannonHigh = ResourceLoader.getImage("data/ui/mp/radar/Cannon_High.png").resource.toTile();
		var radarTileCannonLow = ResourceLoader.getImage("data/ui/mp/radar/Cannon_Low.png").resource.toTile();
		var radarTileCannonMid = ResourceLoader.getImage("data/ui/mp/radar/Cannon_Mid.png").resource.toTile();
		var radarTileCannonNoGlow = ResourceLoader.getImage("data/ui/mp/radar/Cannon_NoGlow.png").resource.toTile();
		var radarTileCheckpoint = ResourceLoader.getImage("data/ui/mp/radar/Checkpoint.png").resource.toTile();
		var radarTileHelicopter = ResourceLoader.getImage("data/ui/mp/radar/HelicopterItem.png").resource.toTile();
		var radarTileMegaMarble = ResourceLoader.getImage("data/ui/mp/radar/MegaMarbleItem.png").resource.toTile();
		var radarTileRandomPowerUp = ResourceLoader.getImage("data/ui/mp/radar/RandomPowerUpItem.png").resource.toTile();
		var radarTileShockAbsorber = ResourceLoader.getImage("data/ui/mp/radar/ShockAbsorberItem.png").resource.toTile();
		var radarTileSuperBounce = ResourceLoader.getImage("data/ui/mp/radar/SuperBounceItem.png").resource.toTile();
		var radarTileSuperJump = ResourceLoader.getImage("data/ui/mp/radar/SuperJumpItem.png").resource.toTile();
		var radarTileSuperSpeed = ResourceLoader.getImage("data/ui/mp/radar/SuperSpeedItem.png").resource.toTile();
		var radarTileTeleport = ResourceLoader.getImage("data/ui/mp/radar/TeleportItem.png").resource.toTile();
		var radarTileTimeTravel = ResourceLoader.getImage("data/ui/mp/radar/TimeTravelItem.png").resource.toTile();
		radarTiles = [
			radarTileRedGem,
			radarTileYellowGem,
			radarTileBlueGem,
			radarTileGreenGem,
			radarTileOrangeGem,
			radarTilePinkGem,
			radarTilePurpleGem,
			radarTileTurquoiseGem,
			radarTileBlackGem,
			radarTilePlatinumGem,
			radarTileEndPad,
			radarTileAntiGravity,
			radarTileAnvil,
			radarTileBlast,
			radarTileBubble,
			radarTileCandyBlue,
			radarTileCandyRed,
			radarTileCandyYellow,
			radarTileCannon,
			radarTileCannonHigh,
			radarTileCannonLow,
			radarTileCannonMid,
			radarTileCannonNoGlow,
			radarTileCheckpoint,
			radarTileHelicopter,
			radarTileMegaMarble,
			radarTileRandomPowerUp,
			radarTileShockAbsorber,
			radarTileSuperBounce,
			radarTileSuperJump,
			radarTileSuperSpeed,
			radarTileTeleport,
			radarTileTimeTravel,
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

		var marblePos = @:privateAccess level.marble.newPos;

		var gemCount = 0;

		var endpads = [];

		// first scan
		var candidates:Array<RadarItem> = [];
		if ((this.customRadarRule & RadarRule.Gems) != 0) {
			for (gem in level.gems) {
				if (!gem.pickedUp) {
					gemCount++;
					var gemDistance = marblePos.distance(new Vector(gem.x, gem.y, gem.z));
					if (gemDistance < gemFinishSearchDistance) {
						candidates.push({
							obj: gem,
							dist: gemDistance,
							used: false,
							index: -1
						});
					}
				}
			}
		}
		if ((this.customRadarRule & (RadarRule.TimeTravels | RadarRule.Powerups)) != 0) {
			// iterate over powerups
			for (powerup in level.powerUps) {
				if (powerup.currentOpacity != 0) {
					var dist = marblePos.distance(new Vector(powerup.x, powerup.y, powerup.z));
					if (dist < itemSearchDistance) {
						if ((this.customRadarRule & RadarRule.Powerups) != 0) {
							if (powerup is SuperJump || powerup is SuperSpeed || powerup is AnvilItem || powerup is Blast || powerup is BubbleItem
								|| powerup is FireballItem || powerup is Helicopter || powerup is RandomPowerup || powerup is ShockAbsorber
								|| powerup is SuperBounce || powerup is TeleportItem || powerup is MegaMarble || powerup is AntiGravity) {
								if (powerup is AntiGravity) {
									var direction = new Vector(0, 0, -1);
									direction.transform(powerup.getRotationQuat().toMatrix()); // ignore the ones that have the same direction as up
									if (direction.equals(level.marble.currentUp))
										continue;
								}
								candidates.push({
									obj: powerup,
									dist: dist,
									used: false,
									index: -1
								});
							}
						}
						if ((this.customRadarRule & RadarRule.TimeTravels) != 0) {
							if (powerup is TimeTravel) {
								candidates.push({
									obj: powerup,
									dist: dist,
									used: false,
									index: -1
								});
							}
						}
					}
				}
			}
		}

		if ((this.customRadarRule & (RadarRule.EndPad | RadarRule.Checkpoints | RadarRule.Cannons)) != 0) {
			// have to scan over everything
			for (obj in level.dtsObjects) {
				@:privateAccess if (gemCount == 0
					&& (this.customRadarRule & RadarRule.EndPad) != -1
						&& level.endPad != null
						&& (obj.dtsPath.indexOf("endpad") != -1 || obj.dtsPath.indexOf("endarea") != -1)) {
					endpads.push(obj);
				}
				if ((this.customRadarRule & RadarRule.Checkpoints) != -1 && obj.dtsPath.indexOf("checkpoint") != -1) {
					var dist = marblePos.distance(new Vector(obj.x, obj.y, obj.z));
					if (dist < itemSearchDistance)
						candidates.push({
							obj: obj,
							dist: dist,
							used: false,
							index: 23
						});
				}
				if ((this.customRadarRule & RadarRule.Cannons) != -1 && obj is Cannon) {
					var dist = marblePos.distance(new Vector(obj.x, obj.y, obj.z));
					if (dist < itemSearchDistance) {
						var cannon:Cannon = cast obj;

						candidates.push({
							obj: obj,
							dist: dist,
							used: false,
							index: switch (cannon.skinOverride) {
								case "red": 19;
								case "green": 20;
								case "blue": 21;
								default: 18;
							}
						});
					}
				}
			}
		}

		// sort everything by distance
		candidates.sort((a, b) -> a.dist == b.dist ? 0 : (a.dist > b.dist ? 1 : -1));
		var itemCount = candidates.length;
		var showCount = itemCount < maxRadarItems ? itemCount : maxRadarItems;
		var alwaysShowCount = Std.int(itemCount > maxRadarItems ? maxRadarItems * 0.8 : itemCount);

		var spawned = 0;

		// show as many gems and finishes
		for (item in candidates) {
			if (item.obj is Gem) {
				var gem:Gem = cast item.obj;
				if (renderArrow(gem.boundingCollider.boundingBox.getCenter().toVector(), gem.radarGemColor, radarTiles[gem.radarGemIndex]))
					spawned++;
				item.used = true;
				if (spawned >= alwaysShowCount)
					break;
			}
		}
		if (@:privateAccess level.endPad != null && gemCount == 0) {
			// show finishes
			for (finish in endpads) {
				if (renderArrow(finish.getAbsPos().getPosition(), 0xE6E6E6, radarTiles[10]))
					spawned++;
				if (spawned >= alwaysShowCount)
					break;
			}
		}
		// show remaining
		for (item in candidates) {
			if (item.used)
				continue;

			var targetPos = item.obj.boundingCollider != null ? item.obj.boundingCollider.boundingBox.getCenter()
				.toVector() : item.obj.getAbsPos().getPosition();

			var radarIndex = item.index;
			if (radarIndex == -1) {
				if (item.obj is PowerUp) {
					var p:PowerUp = cast item.obj;
					radarIndex = p.radarIndex;
					if (radarIndex == 0)
						continue; // no-icon :/
				} else {
					continue; // lets just not show
				}
			}

			if (renderArrow(targetPos, 0xFFFFFF, radarTiles[radarIndex], false))
				spawned++;
			item.used = true;

			if (spawned >= showCount)
				break;
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

	function renderArrow(pos:Vector, color:Int, tile:h2d.Tile, drawArrow:Bool = true) {
		var validProjection = frustumHasPoint(level.scene.camera.frustum, pos);
		var projectedPos = level.scene.camera.project(pos.x, pos.y, pos.z, scene2d.width, scene2d.height);

		if (validProjection && tile != null) {
			g.lineStyle(0, 0, 0);
			g.beginTileFill(projectedPos.x - tile.width / 2, projectedPos.y - tile.height / 2, Settings.uiScale, Settings.uiScale, tile);
			g.drawRect(projectedPos.x - tile.width / 2, projectedPos.y - tile.height / 2, tile.width, tile.height);
			g.endFill();
			return true;
		} else if (!validProjection && drawArrow) {
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

			var tipPosition = ellipsePos.add(arrowDir.multiply(fullArrowLength * Settings.uiScale));
			var tipUpperPosition = ellipsePos.add(arrowDirPerp.multiply(fullArrowWidth * Settings.uiScale / 2));
			var tipLowerPosition = ellipsePos.add(arrowDirPerp.multiply(-fullArrowWidth * Settings.uiScale / 2));

			g.beginFill(color, 0.6);
			g.lineStyle(1, 0, 0.6);
			g.moveTo(tipPosition.x, tipPosition.y);
			g.lineTo(tipUpperPosition.x, tipUpperPosition.y);
			g.lineTo(tipLowerPosition.x, tipLowerPosition.y);
			g.endFill();
			return true;
		}
		return false;
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
