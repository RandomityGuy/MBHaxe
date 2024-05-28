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

	public var ellipseScreenFraction = new Vector(0.79, 0.9);
	public var fullArrowLength = 60.0;
	public var fullArrowWidth = 40.0;
	public var maxArrowAlpha = 0.6;
	public var maxTargetAlpha = 0.4;
	public var minArrowFraction = 0.4;

	var time:Float = 0.0;

	var _dirty = false;

	public function new(level:MarbleWorld, scene2d:Scene) {
		this.level = level;
		this.scene2d = scene2d;
		this.marbleNameTexts = [];
	}

	public function init() {
		g = new Graphics(scene2d);
	}

	public function update(dt:Float) {
		time += dt;
		_dirty = true;
	}

	public function render() {
		if (!_dirty)
			return;
		g.clear();
		var gemCount = 0;
		for (gem in level.gems) {
			if (!gem.pickedUp) {
				renderArrow(gem.boundingCollider.boundingBox.getCenter().toVector(), gem.radarColor);
				gemCount++;
			}
		}
		if (@:privateAccess level.endPad != null && gemCount == 0) {
			renderArrow(@:privateAccess level.endPad.getAbsPos().getPosition(), 0xE6E6E6);
		}
		var fadeDistance = level.scene.camera.zFar * 0.1;
		for (marble => marbleName in marbleNameTexts) {
			if (marbleName != null)
				marbleName.alpha = 0;
		}
		for (marble in level.marbles) {
			if (marble != level.marble) {
				var shapePos = marble.getAbsPos().getPosition();
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

	function renderArrow(pos:Vector, color:Int) {
		var validProjection = frustumHasPoint(level.scene.camera.frustum, pos);
		var projectedPos = level.scene.camera.project(pos.x, pos.y, pos.z, scene2d.width, scene2d.height);

		var fovX = (level.scene.camera.getFovX() * 0.5) * Math.PI / 180.0;
		var fovY = (level.scene.camera.fovY * 0.5) * Math.PI / 180.0;

		var blink = time < 3 ? ((Std.int(Math.floor((time * 1000) / 500))) % 2 == 1) : false;

		var gravityMat = level.getOrientationQuat(level.timeState.currentAttemptTime).toMatrix();

		var front = level.scene.camera.target.sub(level.scene.camera.pos).normalized();
		var up = gravityMat.up();
		var right = up.cross(front).normalized();

		gravityMat.invert();

		var shapeDist = pos.sub(level.scene.camera.pos);
		var shapeDir = shapeDist.normalized();
		var distToShape = shapeDist.length();
		shapeDir.normalize();

		var p1 = front.add(right.multiply(Math.sin(fovX))).add(up.multiply(fovY));
		var p2 = front.add(right.multiply(Math.sin(fovX))).sub(up.multiply(fovY));

		var camCone1G = p1.transformed(gravityMat);
		var camCone2G = p2.transformed(gravityMat);

		var shapeDirGrav = shapeDir.transformed(gravityMat);
		var cc1 = new Vector(Math.sqrt(camCone1G.x * camCone1G.x + camCone1G.y * camCone1G.y), camCone1G.z, 0);
		var cc2 = new Vector(Math.sqrt(camCone2G.x * camCone2G.x + camCone2G.y * camCone2G.y), camCone2G.z, 0);
		var sd = new Vector(Math.sqrt(shapeDirGrav.x * shapeDirGrav.x + shapeDirGrav.y * shapeDirGrav.y), shapeDirGrav.z, 0);
		cc1.normalize();
		cc2.normalize();
		sd.normalize();

		var arrowPosY = 0.0;
		var arrowPosX = 0.0;
		if (cc1.y >= sd.y) {
			if (cc2.y <= sd.y) {
				arrowPosY = scene2d.height * ((sd.x * cc1.y - cc1.x * sd.y) / (sd.y * (cc2.x - cc1.x) - (cc2.y - cc1.y) * sd.x));
			} else {
				arrowPosY = scene2d.height;
			}
		}
		var r1 = shapeDist.transformed(gravityMat);
		var r2 = front.transformed(gravityMat);
		r1.z = 0;
		r2.z = 0;
		r1.normalize();
		r2.normalize();
		var cp = r1.cross(r2);
		var forwardness = r1.dot(r2);
		var xfPosAngle = -Math.asin(cp.z);

		var normal = new Vector(0, 1, 0);

		var foldAmount = 0.0;
		var foldArrow = false;
		if (forwardness < 0.5) {
			foldArrow = true;
			foldAmount = (0.5 - forwardness) / 3;
		}
		// Is the object behind us?
		if (forwardness < 0.0) {
			// Get the angle into the correct range
			if (xfPosAngle >= 0.0)
				xfPosAngle += Math.PI;
			else
				xfPosAngle -= Math.PI;
		}

		// If aSinZ is between -fov and fov, then
		if (-fovX <= xfPosAngle) {
			if (fovX >= xfPosAngle) {
				// the new x is the fraction of where it is but convert it from an angle to tangent
				arrowPosX = scene2d.width * 0.5 + Math.tan(xfPosAngle) * (scene2d.width * 0.5) / Math.tan(fovX);
			} else {
				// otherwise snap to edge
				arrowPosX = scene2d.width;
			}
		}

		var drawPoint = new Vector(arrowPosX, arrowPosY);
		if (validProjection) {
			drawPoint.load(projectedPos);
			if (drawPoint.distanceSq(projectedPos) <= 75 * 75) {
				var distOff = drawPoint.distance(projectedPos);
				drawPoint = Util.lerpThreeVectors(projectedPos, new Vector(arrowPosX, arrowPosY), distOff / 75);
			}
		}

		var ellipse = new Vector((scene2d.width / 2) * ellipseScreenFraction.x, (scene2d.height / 2) * ellipseScreenFraction.y);
		var arrowDir = drawPoint.sub(new Vector(scene2d.width / 2, scene2d.height / 2));
		var ellipseDistance = Math.sqrt(arrowDir.x * arrowDir.x / (ellipse.x * ellipse.x) + arrowDir.y * arrowDir.y / (ellipse.y * ellipse.y));

		var arrowAlpha = maxArrowAlpha;
		var circleAlpha = 0.0;
		if (ellipseDistance <= 1) {
			if (ellipseDistance <= 0.7) {
				arrowAlpha = 0;
				circleAlpha = maxTargetAlpha;
			} else {
				arrowAlpha = (ellipseDistance - 0.7) * (10 / 3) * maxArrowAlpha;
				circleAlpha = maxArrowAlpha - arrowAlpha * maxTargetAlpha / maxArrowAlpha;
			}
		} else {
			drawPoint = arrowDir.multiply(1 / ellipseDistance);
			drawPoint.x += scene2d.width / 2;
			drawPoint.y += scene2d.height / 2;
		}
		arrowDir.normalize();

		if (blink) {
			var r = color >> 16 & 0xFF;
			var g = color >> 8 & 0xFF;
			var b = color & 0xFF;
			r = r > 127 ? r : 127;
			g = g > 127 ? g : 127;
			b = b > 127 ? b : 127;
			color = r << 16 | g << 8 | b;

			arrowAlpha *= 1.3;
			if (arrowAlpha > 1)
				arrowAlpha = 1;
			circleAlpha *= 1.3;
			if (circleAlpha > 1)
				circleAlpha = 1;
		}

		var arrowScale = Util.clamp(1 - distToShape / 100, minArrowFraction, 1);

		var yScaleLength = scene2d.height / 480;

		if (arrowAlpha != 0) {
			var arrowWidth = fullArrowWidth * arrowScale * yScaleLength;
			var arrowLength = fullArrowLength * arrowScale * yScaleLength;

			var arrowSideVector = new Vector(arrowWidth * arrowDir.y, arrowWidth * -arrowDir.x);
			var halfArrowSideVec = arrowSideVector.multiply(0.5);

			var arrowForwardVec = arrowDir.multiply(arrowLength);
			var arrowBack = drawPoint.sub(arrowForwardVec);

			var lowerRight = arrowBack.add(halfArrowSideVec);
			var lowerLeft = arrowBack.sub(halfArrowSideVec);

			if (foldAmount == 0)
				foldArrow = false;

			var halfFoldWidth = 0.5 * arrowWidth * foldAmount;
			var halfFoldForwardWidthVec = new Vector(halfFoldWidth * arrowDir.y, -halfFoldWidth * arrowDir.x);

			var foldLength = foldAmount * arrowLength;
			var foldForwardVec = arrowDir.multiply(foldLength);

			var foldBack = drawPoint.sub(foldForwardVec);
			var foldLowerRight = foldBack.add(halfFoldForwardWidthVec);
			var foldLowerLeft = foldBack.sub(halfFoldForwardWidthVec);

			var doubleFoldVec = arrowDir.multiply(foldLength + foldLength);

			var foldedTip = drawPoint.sub(doubleFoldVec);

			g.beginFill(color, arrowAlpha);
			g.lineStyle(0, color, arrowAlpha);
			if (foldArrow) {
				g.moveTo(lowerRight.x, lowerRight.y);
				g.lineTo(lowerLeft.x, lowerLeft.y);
				g.lineTo(foldLowerLeft.x, foldLowerLeft.y);
				g.moveTo(lowerRight.x, lowerRight.y);
				g.lineTo(foldLowerRight.x, foldLowerRight.y);
				g.lineTo(foldLowerLeft.x, foldLowerLeft.y);
			} else {
				g.moveTo(drawPoint.x, drawPoint.y);
				g.lineTo(lowerRight.x, lowerRight.y);
				g.lineTo(lowerLeft.x, lowerLeft.y);
			}
			g.endFill();
			g.lineStyle(1, 0x000000, arrowAlpha);
			g.setColor(0x000000, arrowAlpha);

			if (foldArrow) {
				g.moveTo(lowerRight.x, lowerRight.y);
				g.lineTo(foldLowerRight.x, foldLowerRight.y);
				g.lineTo(foldLowerLeft.x, foldLowerLeft.y);
				g.lineTo(lowerLeft.x, lowerLeft.y);
				g.lineTo(lowerRight.x, lowerRight.y);
				g.moveTo(foldLowerRight.x, foldLowerRight.y);
				g.lineTo(foldedTip.x, foldedTip.y);
				g.lineTo(foldLowerLeft.x, foldLowerLeft.y);
				g.moveTo(foldedTip.x, foldedTip.y);
			} else {
				g.moveTo(drawPoint.x, drawPoint.y);
				g.lineTo(lowerRight.x, lowerRight.y);
				g.lineTo(lowerLeft.x, lowerLeft.y);
				g.lineTo(drawPoint.x, drawPoint.y);
			}
		}

		if (circleAlpha != 0) {
			var arrowLen = fullArrowLength * arrowScale * 0.4 * yScaleLength;
			var halfArrowLen = arrowLen * 0.55;

			if (arrowScale >= 0.7) {
				if (arrowScale < 0.8)
					arrowLen = ((arrowScale - 0.7) * 10.0) * (arrowLen - halfArrowLen) + halfArrowLen;

				var topLeft = drawPoint.sub(new Vector(arrowLen, arrowLen));
				var midTopLeft = topLeft.add(new Vector(halfArrowLen, halfArrowLen));
				var bottomRight = drawPoint.add(new Vector(arrowLen, arrowLen));
				var midBottomRight = bottomRight.sub(new Vector(halfArrowLen, halfArrowLen));

				// Top Left
				g.beginFill(color, circleAlpha);
				g.lineStyle(0, color, circleAlpha);
				g.moveTo(midTopLeft.x, midTopLeft.y);
				g.lineTo(midTopLeft.x, topLeft.y);
				g.lineTo(topLeft.x, midTopLeft.y);
				g.endFill();

				// Top Right
				g.beginFill(color, circleAlpha);
				g.lineStyle(0, color, circleAlpha);
				g.moveTo(midBottomRight.x, midTopLeft.y);
				g.lineTo(midBottomRight.x, topLeft.y);
				g.lineTo(bottomRight.x, midTopLeft.y);
				g.endFill();

				// Bottom Right
				g.beginFill(color, circleAlpha);
				g.lineStyle(0, color, circleAlpha);
				g.moveTo(midBottomRight.x, midBottomRight.y);
				g.lineTo(midBottomRight.x, bottomRight.y);
				g.lineTo(bottomRight.x, midBottomRight.y);
				g.endFill();

				// Bottom Left
				g.beginFill(color, circleAlpha);
				g.lineStyle(0, color, circleAlpha);
				g.moveTo(midTopLeft.x, midBottomRight.y);
				g.lineTo(midTopLeft.x, bottomRight.y);
				g.lineTo(topLeft.x, midBottomRight.y);
				g.endFill();

				// Border
				g.lineStyle(1, 0x000000, circleAlpha);
				g.setColor(0x000000, circleAlpha);
				g.moveTo(midTopLeft.x, topLeft.y);
				g.lineTo(topLeft.x, midTopLeft.y);

				g.moveTo(midBottomRight.x, topLeft.y);
				g.lineTo(bottomRight.x, midTopLeft.y);

				g.moveTo(midBottomRight.x, bottomRight.y);
				g.lineTo(bottomRight.x, midBottomRight.y);

				g.moveTo(midTopLeft.x, bottomRight.y);
				g.lineTo(topLeft.x, midBottomRight.y);
			} else {
				var halfTopLeft = drawPoint.sub(new Vector(halfArrowLen, halfArrowLen));
				var halfBottomRight = drawPoint.add(new Vector(halfArrowLen, halfArrowLen));

				g.beginFill(color, circleAlpha);
				g.lineStyle(0, color, circleAlpha);
				g.moveTo(halfTopLeft.x, drawPoint.y);
				g.lineTo(drawPoint.x, halfTopLeft.y);
				g.lineTo(halfBottomRight.x, drawPoint.y);
				g.endFill();

				g.beginFill(color, circleAlpha);
				g.lineStyle(0, color, circleAlpha);
				g.moveTo(halfTopLeft.x, drawPoint.y);
				g.lineTo(drawPoint.x, halfBottomRight.y);
				g.lineTo(halfBottomRight.x, drawPoint.y);
				g.endFill();

				g.lineStyle(1, 0x000000, circleAlpha);
				g.setColor(0x000000, circleAlpha);

				g.moveTo(halfBottomRight.x, drawPoint.y);
				g.lineTo(drawPoint.x, halfTopLeft.y);

				g.moveTo(drawPoint.x, halfTopLeft.y);
				g.lineTo(halfTopLeft.x, drawPoint.y);

				g.moveTo(halfTopLeft.x, drawPoint.y);
				g.lineTo(drawPoint.x, halfBottomRight.y);

				g.moveTo(drawPoint.x, halfBottomRight.y);
				g.lineTo(halfBottomRight.x, drawPoint.y);
			}
		}
	}

	function renderName(pos:Vector, marble:Marble, opacity:Float) {
		if (!marbleNameTexts.exists(marble)) {
			var arialb14fontdata = ResourceLoader.getFileEntry("data/font/Arial Bold.fnt");
			var arialb14b = new BitmapFont(arialb14fontdata.entry);
			@:privateAccess arialb14b.loader = ResourceLoader.loader;
			var arialBold14 = arialb14b.toSdfFont(cast 16 * Settings.uiScale, MultiChannel);
			var txt = new h2d.Text(arialBold14, scene2d);
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
			marbleNameTexts.get(marble).alpha = 0;
		}
	}
}
