package src;

import h3d.shader.pbr.PropsValues;
import h3d.mat.Material;
import src.ResourceLoader;
import src.PathedInterior;
import h3d.Vector;
import collision.CollisionSurface;
import collision.CollisionEntity;
import h3d.mat.Data.Wrap;
import hxd.fs.FileSystem;
import hxd.res.Loader;
import hxd.res.Image;
import h3d.mat.Texture;
import haxe.io.Path;
import hxd.File;
import h3d.scene.Mesh;
import h3d.prim.UV;
import h3d.col.Point;
import h3d.prim.Polygon;
import dif.math.Point2F;
import dif.math.Point3F;
import h3d.prim.BigPrimitive;
import dif.Interior;
import dif.Dif;
import src.InteriorObject;

class DifBuilderTriangle {
	public var texture:String;
	public var normal1:Point3F;
	public var normal2:Point3F;
	public var normal3:Point3F;
	public var p1:Point3F;
	public var p2:Point3F;
	public var p3:Point3F;
	public var uv1:Point2F;
	public var uv2:Point2F;
	public var uv3:Point2F;

	public function new() {}
}

class DifBuilder {
	static var materialDict = [
		"friction_none" => {
			friction: 0.01,
			restitution: 0.5
		},
		"friction_low" => {
			friction: 0.2,
			restitution: 0.5
		},
		"friction_high" => {
			friction: 1.5,
			restitution: 0.5
		},
		"friction_ramp_yellow" => {
			friction: 2.0,
			restitution: 1.0
		},
		"oilslick" => {
			friction: 0.05,
			restitution: 0.5
		},
		"base.slick" => {
			friction: 0.05,
			restitution: 0.5
		},
		"ice.slick" => {
			friction: 0.05,
			restitution: 0.5
		}
	];

	public static function loadDif(path:String, itr:InteriorObject, ?so:Int = -1) {
		var dif = ResourceLoader.loadInterior(path);

		var geo = so == -1 ? dif.interiors[0] : dif.subObjects[so];

		var hulls = geo.convexHulls;

		var triangles = [];
		var textures = [];

		var collider = new CollisionEntity(itr);

		function stripTexName(tex:String) {
			var dotpos = tex.lastIndexOf(".");
			var slashpos = tex.lastIndexOf("/") + 1;
			if (dotpos == -1) {
				dotpos = tex.length;
			}
			if (slashpos == -1) {
				slashpos = 0;
			}
			return tex.substring(slashpos, dotpos);
		}

		for (i in 0...hulls.length) {
			var hullTris = [];
			var hull = hulls[i];

			for (j in hull.surfaceStart...(hull.surfaceStart + hull.surfaceCount)) {
				var surfaceindex = geo.hullSurfaceIndices[j];
				var surface = geo.surfaces[surfaceindex];
				if (surface == null)
					continue;
				var planeindex = surface.planeIndex;

				var planeFlipped = (planeindex & 0x8000) == 0x8000;
				if (planeFlipped)
					planeindex &= ~0x8000;

				var plane = geo.planes[planeindex];
				var normal = geo.normals[plane.normalIndex];

				if (planeFlipped)
					normal = normal.scalar(-1);

				var texture = geo.materialList[surface.textureIndex];
				if (!textures.contains(texture))
					textures.push(texture);

				var points = geo.points;

				var colliderSurface = new CollisionSurface();
				colliderSurface.points = [];
				colliderSurface.normals = [];
				colliderSurface.indices = [];

				for (k in (surface.windingStart + 2)...(surface.windingStart + surface.windingCount)) {
					var p1, p2, p3;
					if ((k - (surface.windingStart + 2)) % 2 == 0) {
						p1 = points[geo.windings[k]];
						p2 = points[geo.windings[k - 1]];
						p3 = points[geo.windings[k - 2]];
					} else {
						p1 = points[geo.windings[k - 2]];
						p2 = points[geo.windings[k - 1]];
						p3 = points[geo.windings[k]];
					}

					var texgen = geo.texGenEQs[surface.texGenIndex];

					var uv1 = new Point2F(p1.x * texgen.planeX.x
						+ p1.y * texgen.planeX.y
						+ p1.z * texgen.planeX.z
						+ texgen.planeX.d,
						p1.x * texgen.planeY.x
						+ p1.y * texgen.planeY.y
						+ p1.z * texgen.planeY.z
						+ texgen.planeY.d);
					var uv2 = new Point2F(p2.x * texgen.planeX.x
						+ p2.y * texgen.planeX.y
						+ p2.z * texgen.planeX.z
						+ texgen.planeX.d,
						p2.x * texgen.planeY.x
						+ p2.y * texgen.planeY.y
						+ p2.z * texgen.planeY.z
						+ texgen.planeY.d);
					var uv3 = new Point2F(p3.x * texgen.planeX.x
						+ p3.y * texgen.planeX.y
						+ p3.z * texgen.planeX.z
						+ texgen.planeX.d,
						p3.x * texgen.planeY.x
						+ p3.y * texgen.planeY.y
						+ p3.z * texgen.planeY.z
						+ texgen.planeY.d);

					var tri = new DifBuilderTriangle();
					tri.texture = texture;
					tri.normal1 = normal;
					tri.normal2 = normal;
					tri.normal3 = normal;
					tri.p1 = p1;
					tri.p2 = p2;
					tri.p3 = p3;
					tri.uv1 = uv1;
					tri.uv2 = uv2;
					tri.uv3 = uv3;
					triangles.push(tri);
					hullTris.push(tri);
					var materialName = stripTexName(texture);
					var hasMaterialInfo = materialDict.exists(materialName);
					if (hasMaterialInfo) {
						var minfo = materialDict.get(materialName);
						colliderSurface.friction = minfo.friction;
						colliderSurface.restitution = minfo.restitution;
					}
					colliderSurface.points.push(new Vector(-p1.x, p1.y, p1.z));
					colliderSurface.points.push(new Vector(-p2.x, p2.y, p2.z));
					colliderSurface.points.push(new Vector(-p3.x, p3.y, p3.z));
					colliderSurface.normals.push(new Vector(-normal.x, normal.y, normal.z));
					colliderSurface.normals.push(new Vector(-normal.x, normal.y, normal.z));
					colliderSurface.normals.push(new Vector(-normal.x, normal.y, normal.z));
					colliderSurface.indices.push(colliderSurface.indices.length);
					colliderSurface.indices.push(colliderSurface.indices.length);
					colliderSurface.indices.push(colliderSurface.indices.length);
				}

				colliderSurface.generateBoundingBox();
				collider.addSurface(colliderSurface);
			}
		}

		var mats = new Map<String, Array<DifBuilderTriangle>>();

		for (index => value in triangles) {
			if (mats.exists(value.texture)) {
				mats[value.texture].push(value);
			} else {
				mats.set(value.texture, [value]);
			}
		}

		collider.generateBoundingBox();
		itr.collider = collider;

		function canFindTex(tex:String) {
			if (["NULL"].contains(tex)) {
				return false;
			}
			if (tex.indexOf('/') != -1) {
				tex = tex.split('/')[1];
			}

			#if js
			path = StringTools.replace(path, "data/", "");
			#end

			if (ResourceLoader.fileSystem.exists(Path.directory(path) + "/" + tex + ".jpg")) {
				return true;
			}
			if (ResourceLoader.fileSystem.exists(Path.directory(path) + "/" + tex + ".png")) {
				return true;
			}
			var prevDir = Path.directory(Path.directory(path));

			if (ResourceLoader.fileSystem.exists(prevDir + "/" + tex + ".jpg")) {
				return true;
			}
			if (ResourceLoader.fileSystem.exists(prevDir + "/" + tex + ".png")) {
				return true;
			}

			return false;
		}

		function tex(tex:String):String {
			if (tex.indexOf('/') != -1) {
				tex = tex.split('/')[1];
			}

			if (ResourceLoader.fileSystem.exists(Path.directory(path) + "/" + tex + ".jpg")) {
				return Path.directory(path) + "/" + tex + ".jpg";
			}
			if (ResourceLoader.fileSystem.exists(Path.directory(path) + "/" + tex + ".png")) {
				return Path.directory(path) + "/" + tex + ".png";
			}

			var prevDir = Path.directory(Path.directory(path));

			if (ResourceLoader.fileSystem.exists(prevDir + "/" + tex + ".jpg")) {
				return prevDir + "/" + tex + ".jpg";
			}
			if (ResourceLoader.fileSystem.exists(prevDir + "/" + tex + ".png")) {
				return prevDir + "/" + tex + ".png";
			}

			return null;
		}

		for (grp => tris in mats) {
			var points = [];
			var normals = [];
			var uvs = [];

			for (tri in tris) {
				var p1 = new Point(-tri.p1.x, tri.p1.y, tri.p1.z);
				var p2 = new Point(-tri.p2.x, tri.p2.y, tri.p2.z);
				var p3 = new Point(-tri.p3.x, tri.p3.y, tri.p3.z);
				var n1 = new Point(-tri.normal1.x, tri.normal1.y, tri.normal1.z);
				var n2 = new Point(-tri.normal2.x, tri.normal2.y, tri.normal2.z);
				var n3 = new Point(-tri.normal3.x, tri.normal3.y, tri.normal3.z);
				var uv1 = new UV(tri.uv1.x, tri.uv1.y);
				var uv2 = new UV(tri.uv2.x, tri.uv2.y);
				var uv3 = new UV(tri.uv3.x, tri.uv3.y);
				points.push(p3);
				points.push(p2);
				points.push(p1);
				normals.push(n3);
				normals.push(n2);
				normals.push(n1);
				uvs.push(uv3);
				uvs.push(uv2);
				uvs.push(uv1);
			}

			var prim = new Polygon(points);
			prim.uvs = uvs;
			prim.normals = normals;

			var material:Material;
			var texture:Texture;
			if (canFindTex(grp)) {
				texture = ResourceLoader.getFileEntry(tex(grp)).toImage().toTexture();
				texture.wrap = Wrap.Repeat;
				material = h3d.mat.Material.create(texture);
			} else {
				material = Material.create();
			}
			material.shadows = false;
			material.receiveShadows = true;
			// material.mainPass.addShader(new h3d.shader.pbr.PropsValues(1, 0, 0, 1));
			// material.mainPass.wireframe = true;

			var mesh = new Mesh(prim, material, itr);
		}
	}
}
