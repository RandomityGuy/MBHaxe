package src;

import shaders.DefaultCubemapMaterial;
import shaders.DefaultNormalMaterial;
import shaders.DefaultMaterial;
import h3d.scene.Mesh;
import shaders.NormalMaterial;
import shaders.NoiseTileMaterial;
import shaders.DirLight;
import shaders.PhongMaterial;
import dif.Edge;
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
import mesh.Polygon;
import h3d.prim.UV;
import h3d.col.Point;
import dif.math.Point2F;
import dif.math.Point3F;
import h3d.prim.BigPrimitive;
import dif.Interior;
import dif.Dif;
import src.InteriorObject;
import src.MarbleGame;
import src.ResourceLoaderWorker;
import src.Console;
import src.Debug;
import src.LRUCache;

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
	public var t1:Point3F;
	public var t2:Point3F;
	public var t3:Point3F;
	public var b1:Point3F;
	public var b2:Point3F;
	public var b3:Point3F;
	public var n1:Point3F;
	public var n2:Point3F;
	public var n3:Point3F;

	public function new() {}
}

class TriangleEdge {
	public var index1:Int;
	public var index2:Int;
	public var farPoint:Int;

	public var surfaceIndex:Int;

	public function new(i1:Int, i2:Int, farPoint:Int, surfaceIndex:Int) {
		if (i2 < i1) {
			index1 = i2;
			index2 = i1;
		} else {
			index1 = i1;
			index2 = i2;
		}
		this.farPoint = farPoint;
		this.surfaceIndex = surfaceIndex;
	}
}

@:publicFields
class DifCache {
	var dif:Dif;
	var difTriangles:Map<String, Array<DifBuilderTriangle>>;
	var prims:Map<String, Polygon>;

	public function new() {}
}

typedef VertexBucket = {
	var referenceNormal:Point3F;
	var triangleIndices:Array<Int>;
	var normals:Array<Point3F>;
}

class DifBuilder {
	static var difCache:LRUCache<DifCache> = new LRUCache(24);

	static var materialDict:Map<String, {
		friction:Float,
		restitution:Float,
		?force:Float
	}> = [
		"friction_none" => {
			friction: 0.01,
			restitution: 0.5
		},
		"friction_low" => {
			friction: 0.2,
			restitution: 0.5
		},
		"friction_low_shadow" => {
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
		},
		"grass" => {
			friction: 1.5,
			restitution: 0.35
		},
		"ice1" => {
			friction: 0.03,
			restitution: 0.95
		},
		"rug" => {
			friction: 6.0,
			restitution: 0.5,
		},
		"tarmac" => {
			friction: 0.35,
			restitution: 0.7
		},
		"carpet" => {
			friction: 6.0,
			restitution: 0.5
		},
		"sand" => {
			friction: 4.0,
			restitution: 0.1
		},
		"water" => {
			friction: 6.0,
			restitution: 0.0,
		},
		"floor_bounce" => {
			friction: 0.2,
			restitution: 0.0,
			force: 15
		},
		"mbp_chevron_friction" => {
			friction: -1.0,
			restitution: 1.0
		},
		"mbp_chevron_friction2" => {
			friction: -1.0,
			restitution: 1.0
		},
		"mbp_chevron_friction3" => {
			friction: -1.0,
			restitution: 1.0
		},
		"mmg_grass" => {
			friction: 0.9,
			restitution: 0.5
		},
		"mmg_sand" => {
			friction: 6.0,
			restitution: 0.1
		},
		"mmg_water" => {
			friction: 6.0,
			restitution: 0.0
		},
		"mmg_ice" => {
			friction: 0.03,
			restitution: 0.95
		},
		"mmg_ice_shadow" => {
			friction: 0.03,
			restitution: 0.95
		},
		"friction_mp_high" => {
			friction: 6,
			restitution: 0.3
		},
		"friction_mp_high_shadow" => {
			friction: 6,
			restitution: 0.3
		},
		"friction_high_shadow" => {
			friction: 6,
			restitution: 0.3
		},
		];

	static function createDefaultMaterial(onFinish:hxsl.Shader->Void, baseTexture:String, normalTexture:String, shininess:Float, specularColor:Vector,
			uvScaleFactor:Float = 1, half:Bool = false) {
		var worker = new ResourceLoaderWorker(() -> {
			var diffuseTex = ResourceLoader.getTexture(baseTexture).resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			// diffuseTex.filter = Linear;
			var normalTex = ResourceLoader.getTexture(normalTexture).resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;
			var shader = new DefaultMaterial(diffuseTex, normalTex, shininess, specularColor, uvScaleFactor, half);
			onFinish(shader);
		});
		worker.loadFile(baseTexture);
		worker.loadFile(normalTexture);
		worker.run();
	}

	static function createDefaultCubemapMaterial(onFinish:hxsl.Shader->Void, baseTexture:String, normalTexture:String, shininess:Float, specularColor:Vector,
			uvScaleFactor:Float = 1) {
		var worker = new ResourceLoaderWorker(() -> {
			var diffuseTex = ResourceLoader.getTexture(baseTexture).resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Linear;
			diffuseTex.filter = Linear;
			var normalTex = ResourceLoader.getTexture(normalTexture).resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;

			var cubemapTex = new h3d.mat.Texture(128, 128, [Cube]);
			var cubemapFace1 = ResourceLoader.getImage('data/textures/acubexpos2.png').resource;
			var cubemapFace2 = ResourceLoader.getImage('data/textures/acubexneg2.png').resource;
			var cubemapFace3 = ResourceLoader.getImage('data/textures/acubezneg2.png').resource;
			var cubemapFace4 = ResourceLoader.getImage('data/textures/acubezpos2.png').resource;
			var cubemapFace5 = ResourceLoader.getImage('data/textures/acubeypos2.png').resource;
			var cubemapFace6 = ResourceLoader.getImage('data/textures/acubeyneg2.png').resource;
			cubemapTex.uploadPixels(cubemapFace1.getPixels(), 0, 0);
			cubemapTex.uploadPixels(cubemapFace2.getPixels(), 0, 1);
			cubemapTex.uploadPixels(cubemapFace3.getPixels(), 0, 2);
			cubemapTex.uploadPixels(cubemapFace4.getPixels(), 0, 3);
			cubemapTex.uploadPixels(cubemapFace5.getPixels(), 0, 4);
			cubemapTex.uploadPixels(cubemapFace6.getPixels(), 0, 5);

			var shader = new DefaultCubemapMaterial(diffuseTex, normalTex, shininess, specularColor, uvScaleFactor, cubemapTex);
			onFinish(shader);
		});
		worker.loadFile(baseTexture);
		worker.loadFile(normalTexture);
		worker.run();
	}

	static function createDefaultNormalMaterial(onFinish:hxsl.Shader->Void, baseTexture:String, shininess:Float, specularColor:Vector,
			uvScaleFactor:Float = 1) {
		var worker = new ResourceLoaderWorker(() -> {
			var diffuseTex = ResourceLoader.getTexture(baseTexture).resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Linear;
			diffuseTex.filter = Linear;
			var shader = new DefaultNormalMaterial(diffuseTex, shininess, specularColor, uvScaleFactor);
			onFinish(shader);
		});
		worker.loadFile(baseTexture);
		worker.run();
	}

	static function createNoiseTileMaterial(onFinish:hxsl.Shader->Void, baseTexture:String, noiseSuffix:String, shininess:Float, specular:Vector,
			uvScale:Float = 1.0) {
		var worker = new ResourceLoaderWorker(() -> {
			var diffuseTex = ResourceLoader.getTexture('data/textures/${baseTexture}').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Linear;
			diffuseTex.filter = Linear;
			var normalTex = ResourceLoader.getTexture('data/textures/tile_intermediate.normal.png').resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;
			var noiseTex = ResourceLoader.getTexture('data/textures/noise${noiseSuffix}.jpg').resource;
			noiseTex.wrap = Repeat;
			noiseTex.mipMap = None;
			var shader = new NoiseTileMaterial(diffuseTex, normalTex, noiseTex, shininess, specular, uvScale);
			#if hl
			shader.useAccurateNoise = true;
			#end
			onFinish(shader);
		});
		worker.loadFile('textures/${baseTexture}');
		worker.loadFile('textures/noise${noiseSuffix}.jpg');
		worker.loadFile('textures/tile_intermediate.normal.png');
		worker.run();
	}

	static function createNormalMapMaterial(onFinish:hxsl.Shader->Void, baseTexture:String, normalTexture:String) {
		var worker = new ResourceLoaderWorker(() -> {
			var diffuseTex = ResourceLoader.getTexture('data/interiors_mbu/${baseTexture}').resource;
			var normalTex = ResourceLoader.getTexture('data/shaders/tex/${normalTexture}').resource;
			normalTex.wrap = Repeat;
			var shader = new NormalMaterial(diffuseTex, normalTex, MarbleGame.instance.world.ambient, MarbleGame.instance.world.dirLight,
				MarbleGame.instance.world.dirLightDir);
			onFinish(shader);
		});
		worker.loadFile('interiors_mbu/${baseTexture}');
		worker.loadFile('shaders/tex/${normalTexture}');
		worker.run();
	}

	static var shaderMaterialDict:Map<String, (hxsl.Shader->Void)->Void> = [
		'plate_1' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/plate.randomize.png', 'data/textures/plate.normal.png', 8,
			new Vector(1, 1, 0.8, 1), 1, true),
		'plate_1_small' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/plate.randomize.png', 'data/textures/plate.normal.png', 8,
			new Vector(1, 1, 0.8, 1), 1, false),
		// Tiles
		'tile_beginner' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '', 40, new Vector(1, 1, 1, 1)),
		'tile_beginner_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_beginner_red' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red', 40, new Vector(1, 1, 1, 1)),
		'tile_beginner_red_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_beginner_blue' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue', 40, new Vector(1, 1, 1, 1)),
		'tile_beginner_blue_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_intermediate' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '', 40, new Vector(1, 1, 1, 1)),
		'tile_intermediate_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_intermediate_red' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red', 40, new Vector(1, 1, 1, 1)),
		'tile_intermediate_red_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_intermediate_green' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_green', 40, new Vector(1, 1, 1, 1)),
		'tile_intermediate_green_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_green_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_advanced' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '', 40, new Vector(1, 1, 1, 1)),
		'tile_advanced_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_advanced_blue' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue', 40, new Vector(1, 1, 1, 1)),
		'tile_advanced_blue_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_advanced_green' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green', 40, new Vector(1, 1, 1, 1)),
		'tile_advanced_green_shadow' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'tile_underside' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_underside.png', '', 40, new Vector(1, 1, 1, 1)),
		// 4x4 Variant
		'tile_beginner_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '', 40, new Vector(1, 1, 1, 1), 4),
		'tile_beginner_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_beginner_red_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red', 40, new Vector(1, 1, 1, 1), 4),
		'tile_beginner_red_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_beginner_blue_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue', 40, new Vector(1, 1, 1, 1), 4),
		'tile_beginner_blue_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_intermediate_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '', 40, new Vector(1, 1, 1, 1), 4),
		'tile_intermediate_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_intermediate_red_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red', 40, new Vector(1, 1, 1, 1), 4),
		'tile_intermediate_red_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_intermediate_green_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_green', 40, new Vector(1, 1, 1, 1), 4),
		'tile_intermediate_green_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_green_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_advanced_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '', 40, new Vector(1, 1, 1, 1), 4),
		'tile_advanced_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_advanced_blue_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue', 40, new Vector(1, 1, 1, 1), 4),
		'tile_advanced_blue_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2), 4),
		'tile_advanced_green_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green', 40, new Vector(1, 1, 1, 1), 4),
		'tile_advanced_green_shadow_4x4' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2), 4),
		// Others
		'wall_beginner' => (onFinish) -> createDefaultNormalMaterial(onFinish, 'data/textures/wall_beginner.png', 12, new Vector(0.8, 0.8, 0.6, 1)),
		'edge_white' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/edge_white.png', 'data/textures/edge.normal.png', 50,
			new Vector(0.8, 0.8, 0.8, 1)),
		'edge_white_shadow' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/edge_white_shadow.png', 'data/textures/edge.normal.png', 50,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'beam' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/beam.png', 'data/textures/beam.normal.png', 12, new Vector(0.8, 0.8, 0.6, 1)),
		'beam_side' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/beam_side.png', 'data/textures/beam_side.normal.png', 12,
			new Vector(0.8, 0.8, 0.6, 1)),
		'friction_low' => (onFinish) -> createDefaultCubemapMaterial(onFinish, 'data/textures/friction_low.png', 'data/textures/friction_low.normal.png', 128,
			new Vector(1, 1, 1, 0.8)),
		'friction_low_shadow' => (onFinish) -> createDefaultCubemapMaterial(onFinish, 'data/textures/friction_low_shadow.png',
			'data/textures/friction_low.normal.png', 128, new Vector(0.3, 0.3, 0.35, 1)),
		'friction_high' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/friction_high.png', 'data/textures/friction_high.normal.png', 10,
			new Vector(0.3, 0.3, 0.35, 1)),
		'friction_high_shadow' => (onFinish) -> createDefaultMaterial(onFinish, 'data/textures/friction_high_shadow.png',
			'data/textures/friction_high.normal.png', 10, new Vector(0.15, 0.15, 0.16, 1.0)),
		'stripe_caution' => (onFinish) -> createDefaultNormalMaterial(onFinish, 'data/textures/stripe_caution.png', 12, new Vector(0.8, 0.8, 0.6, 1)),
	];

	public static function loadDif(path:String, itr:InteriorObject, onFinish:Void->Void, ?so:Int = -1, makeCollideable = true) {
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end

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

		ResourceLoader.load(path).entry.load(() -> {
			var dif:Dif = null;
			var cache:DifCache = null;
			var cachePath = '${path}${so}';
			if (difCache.exists(cachePath)) {
				cache = difCache.get(cachePath);
				dif = cache.dif;
			} else {
				var difresource = ResourceLoader.loadInterior(path);
				difresource.acquire();
				dif = difresource.resource;
				dumbDownDif(dif);
			}
			var geo = (so == -1 ? dif.interiors[0] : dif.subObjects[so]);
			var triangles = [];
			var textures = [];
			var collider = new CollisionEntity(itr);
			var vertexBuckets = new Map<Point3F, Array<VertexBucket>>();
			var edges = [];
			var colliderSurfaces = [];
			var mats = new Map<String, Array<DifBuilderTriangle>>();
			var difEdges:Map<Int, Edge> = [];
			if (cache != null) {
				mats = cache.difTriangles;
			}
			if (cache == null || makeCollideable) {
				mats = [];
				colliderSurfaces = [];
				difEdges = [];
				for (i in 0...geo.surfaces.length) {
					var surfaceindex = i;
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
					colliderSurface.transformKeys = [];
					colliderSurface.originalIndices = [];
					colliderSurface.originalSurfaceIndex = surfaceindex;

					// Pick the three non-collinear points
					var texPlanes = geo.texGenEQs[surface.texGenIndex];

					var startIdx = 0;
					while (true) {
						var pc0 = geo.points[geo.windings[surface.windingStart + startIdx + 1]];
						var pc1 = geo.points[geo.windings[surface.windingStart + startIdx]];
						var pc2 = geo.points[geo.windings[surface.windingStart + startIdx + 2]];

						var tc0 = new Vector(texPlanes.planeX.x * pc0.x
							+ texPlanes.planeX.y * pc0.y
							+ texPlanes.planeX.z * pc0.z
							+ texPlanes.planeX.d,
							texPlanes.planeY.x * pc0.x
							+ texPlanes.planeY.y * pc0.y
							+ texPlanes.planeY.z * pc0.z
							+ texPlanes.planeY.d, 0, 0);
						var tc1 = new Vector(texPlanes.planeX.x * pc1.x
							+ texPlanes.planeX.y * pc1.y
							+ texPlanes.planeX.z * pc1.z
							+ texPlanes.planeX.d,
							texPlanes.planeY.x * pc1.x
							+ texPlanes.planeY.y * pc1.y
							+ texPlanes.planeY.z * pc1.z
							+ texPlanes.planeY.d, 0, 0);
						var tc2 = new Vector(texPlanes.planeX.x * pc2.x
							+ texPlanes.planeX.y * pc2.y
							+ texPlanes.planeX.z * pc2.z
							+ texPlanes.planeX.d,
							texPlanes.planeY.x * pc2.x
							+ texPlanes.planeY.y * pc2.y
							+ texPlanes.planeY.z * pc2.z
							+ texPlanes.planeY.d, 0, 0);

						var edge1 = new Vector(pc1.x - pc0.x, tc1.x - tc0.x, tc1.y - tc0.y);
						var edge2 = new Vector(pc2.x - pc0.x, tc2.x - tc0.x, tc2.y - tc0.y);
						var cp = edge1.cross(edge2);

						if (cp.lengthSq() > 1e-12) {
							break;
						}

						startIdx += 3;
						if (startIdx >= surface.windingCount) {
							startIdx = 0;
							break;
						}
					}

					var pc0 = geo.points[geo.windings[surface.windingStart + startIdx + 1]];
					var pc1 = geo.points[geo.windings[surface.windingStart + startIdx]];
					var pc2 = geo.points[geo.windings[surface.windingStart + startIdx + 2]];

					var tc0 = new Vector(texPlanes.planeX.x * pc0.x
						+ texPlanes.planeX.y * pc0.y
						+ texPlanes.planeX.z * pc0.z
						+ texPlanes.planeX.d,
						texPlanes.planeY.x * pc0.x
						+ texPlanes.planeY.y * pc0.y
						+ texPlanes.planeY.z * pc0.z
						+ texPlanes.planeY.d, 0, 0);
					var tc1 = new Vector(texPlanes.planeX.x * pc1.x
						+ texPlanes.planeX.y * pc1.y
						+ texPlanes.planeX.z * pc1.z
						+ texPlanes.planeX.d,
						texPlanes.planeY.x * pc1.x
						+ texPlanes.planeY.y * pc1.y
						+ texPlanes.planeY.z * pc1.z
						+ texPlanes.planeY.d, 0, 0);
					var tc2 = new Vector(texPlanes.planeX.x * pc2.x
						+ texPlanes.planeX.y * pc2.y
						+ texPlanes.planeX.z * pc2.z
						+ texPlanes.planeX.d,
						texPlanes.planeY.x * pc2.x
						+ texPlanes.planeY.y * pc2.y
						+ texPlanes.planeY.z * pc2.z
						+ texPlanes.planeY.d, 0, 0);

					var edge1 = new Vector(pc1.x - pc0.x, tc1.x - tc0.x, tc1.y - tc0.y);
					var edge2 = new Vector(pc2.x - pc0.x, tc2.x - tc0.x, tc2.y - tc0.y);
					var cp = edge1.cross(edge2);
					var s = new Vector();
					var t = new Vector();
					if (Math.abs(cp.x) > 1e-12) {
						s.x = -cp.y / cp.x;
						t.x = -cp.z / cp.x;
					}
					edge1.set(pc1.y - pc0.y, tc1.x - tc0.x, tc1.y - tc0.y);
					edge2.set(pc2.y - pc0.y, tc2.x - tc0.x, tc2.y - tc0.y);
					cp = edge1.cross(edge2);
					if (Math.abs(cp.x) > 1e-12) {
						s.y = -cp.y / cp.x;
						t.y = -cp.z / cp.x;
					}
					edge1.set(pc1.z - pc0.z, tc1.x - tc0.x, tc1.y - tc0.y);
					edge2.set(pc2.z - pc0.z, tc2.x - tc0.x, tc2.y - tc0.y);
					cp = edge1.cross(edge2);
					if (Math.abs(cp.x) > 1e-12) {
						s.z = -cp.y / cp.x;
						t.z = -cp.z / cp.x;
					}
					s.normalize();
					t.normalize();
					var st = s.cross(t);
					if (st.x * normal.x + st.y * normal.y + st.z * normal.z < 0) {
						st.scale(-1);
					}
					// s.x *= -1;
					// t.x *= -1;
					// st.x *= -1;

					for (k in (surface.windingStart + 2)...(surface.windingStart + surface.windingCount)) {
						var p1, p2, p3;
						var i1, i2, i3;
						if ((k - (surface.windingStart + 2)) % 2 == 0) {
							i1 = k;
							i2 = k - 1;
							i3 = k - 2;
							p1 = points[geo.windings[k]];
							p2 = points[geo.windings[k - 1]];
							p3 = points[geo.windings[k - 2]];
							if (makeCollideable) {
								colliderSurface.originalIndices.push(geo.windings[k]);
								colliderSurface.originalIndices.push(geo.windings[k - 1]);
								colliderSurface.originalIndices.push(geo.windings[k - 2]);
							}
						} else {
							i1 = k - 2;
							i2 = k - 1;
							i3 = k;
							p1 = points[geo.windings[k - 2]];
							p2 = points[geo.windings[k - 1]];
							p3 = points[geo.windings[k]];
							if (makeCollideable) {
								colliderSurface.originalIndices.push(geo.windings[k - 2]);
								colliderSurface.originalIndices.push(geo.windings[k - 1]);
								colliderSurface.originalIndices.push(geo.windings[k]);
							}
						}
						var e1 = new TriangleEdge(geo.windings[k], geo.windings[k - 1], geo.windings[k - 2], surfaceindex);
						var e2 = new TriangleEdge(geo.windings[k - 1], geo.windings[k - 2], geo.windings[k], surfaceindex);
						var e3 = new TriangleEdge(geo.windings[k], geo.windings[k - 2], geo.windings[k - 1], surfaceindex);
						edges.push(e1);
						edges.push(e2);
						edges.push(e3);
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

						// if (geo.normalIndices != null && geo.normalIndices.length > 0) {
						// 	tri.t1 = geo.normals2[geo.normalIndices[3 * i1 + 3 * surface.windingStart]];
						// 	tri.t1.x *= -1;
						// 	tri.n1 = geo.normals2[geo.normalIndices[3 * i1 + 1 + 3 * surface.windingStart]];
						// 	tri.n1.x *= -1;
						// 	tri.b1 = geo.normals2[geo.normalIndices[3 * i1 + 2 + 3 * surface.windingStart]];
						// 	tri.b1.x *= -1;
						// 	tri.t2 = geo.normals2[geo.normalIndices[3 * i2 + 3 * surface.windingStart]];
						// 	tri.t2.x *= -1;
						// 	tri.n2 = geo.normals2[geo.normalIndices[3 * i2 + 1 + 3 * surface.windingStart]];
						// 	tri.n2.x *= -1;
						// 	tri.b2 = geo.normals2[geo.normalIndices[3 * i2 + 2 + 3 * surface.windingStart]];
						// 	tri.b2.x *= -1;
						// 	tri.t3 = geo.normals2[geo.normalIndices[3 * i3 + 3 * surface.windingStart]];
						// 	tri.t3.x *= -1;
						// 	tri.n3 = geo.normals2[geo.normalIndices[3 * i3 + 1 + 3 * surface.windingStart]];
						// 	tri.n3.x *= -1;
						// 	tri.b3 = geo.normals2[geo.normalIndices[3 * i3 + 2 + 3 * surface.windingStart]];
						// 	tri.b3.x *= -1;
						// } else {
						tri.t1 = new Point3F(s.x, s.y, s.z);
						tri.n1 = new Point3F(st.x, st.y, st.z);
						tri.b1 = new Point3F(t.x, t.y, t.z);
						tri.t2 = new Point3F(s.x, s.y, s.z);
						tri.n2 = new Point3F(st.x, st.y, st.z);
						tri.b2 = new Point3F(t.x, t.y, t.z);
						tri.t3 = new Point3F(s.x, s.y, s.z);
						tri.n3 = new Point3F(st.x, st.y, st.z);
						tri.b3 = new Point3F(t.x, t.y, t.z);
						// }
						triangles.push(tri);
						var materialName = stripTexName(texture).toLowerCase();
						var hasMaterialInfo = materialDict.exists(materialName);
						if (hasMaterialInfo) {
							var minfo = materialDict.get(materialName);
							if (makeCollideable) {
								colliderSurface.friction = minfo.friction;
								colliderSurface.restitution = minfo.restitution;
								colliderSurface.force = minfo.force != null ? minfo.force : 0;
							}
						}
						if (makeCollideable) {
							colliderSurface.addPoint(-p1.x, p1.y, p1.z);
							colliderSurface.addPoint(-p2.x, p2.y, p2.z);
							colliderSurface.addPoint(-p3.x, p3.y, p3.z);
							colliderSurface.addNormal(-normal.x, normal.y, normal.z);
							colliderSurface.addNormal(-normal.x, normal.y, normal.z);
							colliderSurface.addNormal(-normal.x, normal.y, normal.z);
							colliderSurface.indices.push(colliderSurface.indices.length);
							colliderSurface.indices.push(colliderSurface.indices.length);
							colliderSurface.indices.push(colliderSurface.indices.length);
							colliderSurface.transformKeys.push(0);
							colliderSurface.transformKeys.push(0);
							colliderSurface.transformKeys.push(0);
						}
						for (v in [p1, p2, p3]) {
							var buckets = vertexBuckets.get(v);
							if (buckets == null) {
								buckets = [];
								vertexBuckets.set(v, buckets);
							}
							var bucket:VertexBucket = null;
							for (j in 0...buckets.length) {
								bucket = buckets[j];
								if (normal.dot(bucket.referenceNormal) > Math.cos(Math.PI / 12))
									break;
								bucket = null;
							}
							if (bucket == null) {
								bucket = {
									referenceNormal: normal,
									triangleIndices: [],
									normals: [],
								};
								buckets.push(bucket);
							}
							bucket.triangleIndices.push(triangles.length - 1);
							bucket.normals.push(normal);
						}
					}
					if (makeCollideable) {
						colliderSurface.generateBoundingBox();
						collider.addSurface(colliderSurface);
						colliderSurfaces.push(colliderSurface);
					}
				}
				var edgeMap:Map<Int, TriangleEdge> = new Map();
				var internalEdges:Map<Int, Bool> = new Map();
				for (edge in edges) {
					var edgeHash = edge.index1 >= edge.index2 ? edge.index1 * edge.index1 + edge.index1 + edge.index2 : edge.index1
						+ edge.index2 * edge.index2;
					if (internalEdges.exists(edgeHash))
						continue;
					if (edgeMap.exists(edgeHash)) {
						if (edgeMap[edgeHash].surfaceIndex == edge.surfaceIndex) {
							// Internal edge
							internalEdges.set(edgeHash, true);
							edgeMap.remove(edgeHash);
							// trace('Removing internal edge: ${edge.index1} ${edge.index2}');
						} else {
							var difEdge = new Edge(edge.index1, edge.index2, edge.surfaceIndex, edgeMap[edgeHash].surfaceIndex);
							difEdge.farPoint0 = edge.farPoint;
							difEdge.farPoint1 = edgeMap[edgeHash].farPoint;
							difEdges.set(edgeHash, difEdge); // Literal edge
						}
					} else {
						edgeMap.set(edgeHash, edge);
					}
				}
				function hashEdge(i1:Int, i2:Int) {
					return i1 >= i2 ? i1 * i1 + i1 + i2 : i1 + i2 * i2;
				}
				function getEdgeConcavity(edge:Edge) {
					var edgeSurface0 = edge.surfaceIndex0;
					var surface0 = geo.surfaces[edgeSurface0];

					var planeindex = surface0.planeIndex;

					var planeFlipped = (planeindex & 0x8000) == 0x8000;
					if (planeFlipped)
						planeindex &= ~0x8000;

					var plane = geo.planes[planeindex];
					var normal0 = geo.normals[plane.normalIndex];

					if (planeFlipped)
						normal0 = normal0.scalar(-1);

					var edgeSurface1 = edge.surfaceIndex1;
					var surface1 = geo.surfaces[edgeSurface1];

					planeindex = surface1.planeIndex;

					planeFlipped = (planeindex & 0x8000) == 0x8000;
					if (planeFlipped)
						planeindex &= ~0x8000;

					plane = geo.planes[planeindex];
					var normal1 = geo.normals[plane.normalIndex];

					if (planeFlipped)
						normal1 = normal1.scalar(-1);

					var dot = normal0.dot(normal1);

					if (Math.abs(dot) < 0.1)
						return false;

					var farP0 = geo.points[edge.farPoint0];
					var farP1 = geo.points[edge.farPoint1];

					var diff = farP1.sub(farP0);
					var cdot0 = normal0.dot(diff);
					if (cdot0 > -0.1) {
						return true;
					}

					return false;
				}
				function getEdgeNormal(edge:Edge) {
					var edgeSurface0 = edge.surfaceIndex0;
					var surface0 = geo.surfaces[edgeSurface0];

					var planeindex = surface0.planeIndex;

					var planeFlipped = (planeindex & 0x8000) == 0x8000;
					if (planeFlipped)
						planeindex &= ~0x8000;

					var plane = geo.planes[planeindex];
					var normal0 = geo.normals[plane.normalIndex];

					if (planeFlipped)
						normal0 = normal0.scalar(-1);

					var edgeSurface1 = edge.surfaceIndex1;
					var surface1 = geo.surfaces[edgeSurface1];

					planeindex = surface1.planeIndex;

					planeFlipped = (planeindex & 0x8000) == 0x8000;
					if (planeFlipped)
						planeindex &= ~0x8000;

					plane = geo.planes[planeindex];
					var normal1 = geo.normals[plane.normalIndex];

					if (planeFlipped)
						normal1 = normal1.scalar(-1);

					var norm = normal0.add(normal1).scalarDiv(2).normalized();

					var vec = new Vector(norm.x, norm.y, norm.z);

					return vec;
				}
				var time = Console.time();
				for (vtex => buckets in vertexBuckets) {
					for (i in 0...buckets.length) {
						var bucket = buckets[i];
						var avgNormal = new Point3F();
						for (normal in bucket.normals)
							avgNormal = avgNormal.add(normal);
						avgNormal = avgNormal.scalarDiv(bucket.normals.length);
						for (j in 0...bucket.triangleIndices.length) {
							var index = bucket.triangleIndices[j];
							var tri = triangles[index];
							if (tri.p1 == vtex) {
								tri.normal1 = avgNormal;
								tri.n1 = avgNormal;
								tri.t1 = tri.t1.sub(avgNormal.scalar(avgNormal.dot(tri.t1))).normalized();
								tri.b1 = tri.b1.sub(avgNormal.scalar(avgNormal.dot(tri.b1))).normalized();
							}
							if (tri.p2 == vtex) {
								tri.normal2 = avgNormal;
								tri.n2 = avgNormal;
								tri.t2 = tri.t2.sub(avgNormal.scalar(avgNormal.dot(tri.t2))).normalized();
								tri.b2 = tri.b2.sub(avgNormal.scalar(avgNormal.dot(tri.b2))).normalized();
							}
							if (tri.p3 == vtex) {
								tri.normal3 = avgNormal;
								tri.n3 = avgNormal;
								tri.t3 = tri.t3.sub(avgNormal.scalar(avgNormal.dot(tri.t3))).normalized();
								tri.b3 = tri.b3.sub(avgNormal.scalar(avgNormal.dot(tri.b3))).normalized();
							}
						}
					}
				}
				for (index => value in triangles) {
					if (mats.exists(value.texture)) {
						mats[value.texture].push(value);
					} else {
						mats.set(value.texture, [value]);
					}
				}
				var interval = Console.time() - time;
				Console.log('Normal smoothing build time: ${interval}');
			}
			if (makeCollideable) {
				collider.finalize();
				itr.collider = collider;
			}
			var buildNewCache = false;
			if (cache == null) {
				cache = new DifCache();
				cache.difTriangles = mats;
				cache.dif = dif;
				cache.prims = [];
				buildNewCache = true;
				difCache.set(cachePath, cache);
			}
			function canFindTex(tex:String) {
				if (["NULL"].contains(tex)) {
					return false;
				}
				if (tex.indexOf('/') != -1) {
					tex = tex.split('/')[1];
				}

				#if (js || android)
				path = StringTools.replace(path, "data/", "");
				#end

				if (ResourceLoader.exists("data/textures/" + tex + ".jpg")) {
					return true;
				}
				if (ResourceLoader.exists("data/textures/" + tex + ".png")) {
					return true;
				}

				return false;
			}
			function tex(tex:String):String {
				if (tex.indexOf('/') != -1) {
					tex = tex.split('/')[1];
				}

				if (ResourceLoader.exists("data/textures/" + tex + ".jpg")) {
					return "data/textures/" + tex + ".jpg";
				}
				if (ResourceLoader.exists("data/textures/" + tex + ".png")) {
					return "data/textures/" + tex + ".png";
				}

				return null;
			}
			var loadtexs = [];
			for (grp => tris in mats) {
				if (canFindTex(grp)) {
					loadtexs.push(tex(grp));
				}
			}
			#if hl
			var memStats = hl.Gc.stats();
			trace('Interior: ${path} ${memStats.currentMemory} ${memStats.totalAllocated} ${memStats.allocationCount}');
			#end
			var worker = new ResourceLoaderWorker(() -> {
				var shaderWorker = new ResourceLoaderWorker(() -> {
					onFinish();
				});

				var time = Console.time();
				for (grp => tris in mats) {
					var prim:Polygon = null;

					if (!buildNewCache && cache != null) {
						prim = cache.prims.get(grp);
					} else {
						var points = [];
						var normals = [];
						var uvs = [];
						var t = [];
						var b = [];
						var n = [];
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
							t.push(new Point(-tri.t3.x, tri.t3.y, tri.t3.z));
							t.push(new Point(-tri.t2.x, tri.t2.y, tri.t2.z));
							t.push(new Point(-tri.t1.x, tri.t1.y, tri.t1.z));
							b.push(new Point(-tri.b3.x, tri.b3.y, tri.b3.z));
							b.push(new Point(-tri.b2.x, tri.b2.y, tri.b2.z));
							b.push(new Point(-tri.b1.x, tri.b1.y, tri.b1.z));
							n.push(new Point(-tri.n3.x, tri.n3.y, tri.n3.z));
							n.push(new Point(-tri.n2.x, tri.n2.y, tri.n2.z));
							n.push(new Point(-tri.n1.x, tri.n1.y, tri.n1.z));
						}
						prim = new Polygon(points);
						prim.uvs = uvs;
						prim.normals = normals;
						prim.tangents = t;
						prim.bitangents = b;
						prim.texMatNormals = n;
						if (buildNewCache) {
							cache.prims.set(grp, prim);
						}
					}

					var texture:Texture;
					var material:Material;
					var exactName = stripTexName(StringTools.replace(grp.toLowerCase(), "textures/", ""));
					if (canFindTex(grp) || shaderMaterialDict.exists(exactName)) {
						material = h3d.mat.Material.create();
						if (shaderMaterialDict.exists(exactName)) {
							var retrievefunc = shaderMaterialDict[exactName];
							shaderWorker.addTask(fwd -> {
								retrievefunc(shad -> {
									var zPass = material.mainPass.clone();
									zPass.removeShader(material.textureShader);
									var tx = zPass.getShader(h3d.shader.Texture);
									zPass.removeShader(tx);
									zPass.setColorMask(false, false, false, false);
									zPass.depthWrite = true;
									zPass.setPassName("zPass");
									material.addPass(zPass);

									material.mainPass.depthTest = LessEqual;
									material.mainPass.removeShader(material.textureShader);
									material.mainPass.addShader(shad);
									var thisprops:Dynamic = material.getDefaultProps();
									thisprops.light = false; // We will calculate our own lighting
									material.props = thisprops;
									material.shadows = false;
									material.receiveShadows = true;
									material.mainPass.setPassName("interior");
									fwd();
								});
							});
						} else {
							texture = ResourceLoader.getTextureRealpath(tex(grp)).resource; // ResourceLoader.getTexture(tex(grp), false).resource;
							texture.wrap = Wrap.Repeat;
							texture.mipMap = Linear;
							material.texture = texture;
							material.shadows = false;
							material.receiveShadows = true;
						}
					} else {
						Console.warn('Unable to load ${grp} texture for dif ${path}');
						material = Material.create();
						material.shadows = false;
						material.receiveShadows = true;
					}
					// material.mainPass.addShader(new h3d.shader.pbr.PropsValues(1, 0, 0, 1));
					if (Debug.wireFrame)
						material.mainPass.wireframe = true;

					var mesh = new Mesh(prim, material, itr);
				}
				var interval = Console.time() - time;
				Console.log('Geometry build time ${interval}');

				time = Console.time();
				shaderWorker.run();
				interval = Console.time() - time;
				Console.log('Shader building time ${interval}');
			});
			for (f in loadtexs) {
				worker.loadFile(f);
			}
			worker.run();
		});
	}

	// Keeps only relevant parts of the dif to reduce memory footprint
	static function dumbDownDif(dif:Dif) {
		dif.aiSpecialNodes = null;
		dif.forceFields = null;
		dif.triggers = null;
		dif.gameEntities = null;
		dif.interiorPathfollowers = null;
		dif.triggers = null;
		dif.vehicleCollision = null;
		for (itr in dif.interiors.concat(dif.subObjects)) {
			itr.alarmAmbientColor = null;
			itr.alarmLMapIndices = null;
			itr.animatedLights = null;
			itr.baseAmbientColor = null;
			itr.bspNodes = null;
			itr.bspSolidLeaves = null;
			itr.convexHullEmitStrings = null;
			itr.convexHulls = null;
			itr.coordBinIndices = null;
			itr.boundingSphere = null;
			itr.coordBins = null;
			itr.edges = null;
			itr.edges2 = null;
			itr.hullEmitStringIndices = null;
			itr.hullIndices = null;
			itr.hullPlaneIndices = null;
			itr.hullSurfaceIndices = null;
			itr.lightMaps = null;
			itr.lightStates = null;
			itr.nameBuffer = null;
			itr.normalIndices = null;
			itr.normalLMapIndices = null;
			itr.nullSurfaces = null;
			itr.pointVisibilities = null;
			itr.polyListPlanes = null;
			itr.polyListPoints = null;
			itr.polyListStrings = null;
			itr.portals = null;
			itr.solidLeafSurfaces = null;
			itr.stateDataBuffers = null;
			itr.zones = null;
			itr.zoneSurfaces = null;
			itr.zoneStaticMeshes = null;
			itr.windingIndices = null;
			itr.texNormals = null;
			itr.texMatrices = null;
			itr.texMatIndices = null;
			itr.stateDatas = null;
		}
	}
}
