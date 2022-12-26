package src;

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
import src.MarbleGame;
import src.ResourceLoaderWorker;
import src.Console;
import src.Debug;

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

typedef VertexBucket = {
	var referenceNormal:Point3F;
	var triangleIndices:Array<Int>;
	var normals:Array<Point3F>;
}

class DifBuilder {
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
		}
		];

	static function createPhongMaterial(onFinish:hxsl.Shader->Void, baseTexture:String, normalTexture:String, shininess:Float, specularColor:Vector,
			uvScaleFactor:Float = 1) {
		var worker = new ResourceLoaderWorker(() -> {
			var diffuseTex = ResourceLoader.getTexture('data/interiors_mbu/${baseTexture}').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture('data/shaders/tex/${normalTexture}').resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;
			var shader = new PhongMaterial(diffuseTex, normalTex, shininess, specularColor, MarbleGame.instance.world.ambient,
				MarbleGame.instance.world.dirLight, MarbleGame.instance.world.dirLightDir, uvScaleFactor);
			onFinish(shader);
		});
		worker.loadFile('interiors_mbu/${baseTexture}');
		worker.loadFile('shaders/tex/${normalTexture}');
		worker.run();
	}

	static function createNoiseTileMaterial(onFinish:hxsl.Shader->Void, baseTexture:String, noiseSuffix:String, shininess:Float, specular:Vector) {
		var worker = new ResourceLoaderWorker(() -> {
			var diffuseTex = ResourceLoader.getTexture('data/interiors_mbu/${baseTexture}').resource;
			diffuseTex.wrap = Repeat;
			diffuseTex.mipMap = Nearest;
			var normalTex = ResourceLoader.getTexture('data/shaders/tex/tile_mbu.normal.png').resource;
			normalTex.wrap = Repeat;
			normalTex.mipMap = Nearest;
			var noiseTex = ResourceLoader.getTexture('data/shaders/tex/noise${noiseSuffix}.jpg').resource;
			noiseTex.wrap = Repeat;
			noiseTex.mipMap = Nearest;
			var shader = new NoiseTileMaterial(diffuseTex, normalTex, noiseTex, shininess, specular, MarbleGame.instance.world.ambient,
				MarbleGame.instance.world.dirLight, MarbleGame.instance.world.dirLightDir, 1);
			onFinish(shader);
		});
		worker.loadFile('interiors_mbu/${baseTexture}');
		worker.loadFile('shaders/tex/noise${noiseSuffix}.jpg');
		worker.loadFile('shaders/tex/tile_mbu.spec.jpg');
		worker.loadFile('shaders/tex/tile_mbu.normal.png');
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
		'interiors_mbu/plate_1.jpg' => (onFinish) -> createPhongMaterial(onFinish, 'plate.randomize.png', 'plate.normal.png', 8, new Vector(1, 1, 0.8, 1),
			0.5),
		'interiors_mbu/tile_beginner.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_beginner_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_beginner_red.jpg' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_beginner_red_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_beginner_blue.jpg' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_beginner_blue_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_intermediate.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_intermediate_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_intermediate_red.jpg' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red', 40,
			new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_intermediate_red_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_intermediate_green.jpg' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_green', 40,
			new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_intermediate_green_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_green_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_advanced.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_advanced_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_advanced_blue.jpg' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_advanced_blue_shadow.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_advanced_green.jpg' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/tile_advanced_green_shadow.jpg' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green_shadow', 40,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/tile_underside.png' => (onFinish) -> createNoiseTileMaterial(onFinish, 'tile_underside.png', '', 40, new Vector(1, 1, 1, 1)),
		'interiors_mbu/wall_beginner.png' => (onFinish) -> createPhongMaterial(onFinish, 'wall_beginner.png', 'wall_mbu.normal.png', 12,
			new Vector(0.8, 0.8, 0.6, 1)),
		'interiors_mbu/edge_white.png' => (onFinish) -> createPhongMaterial(onFinish, 'edge_white.png', 'edge.normal.png', 50, new Vector(0.8, 0.8, 0.8, 1)),
		'interiors_mbu/edge_white_shadow.png' => (onFinish) -> createPhongMaterial(onFinish, 'edge_white_shadow.png', 'edge.normal.png', 50,
			new Vector(0.2, 0.2, 0.2, 0.2)),
		'interiors_mbu/beam.png' => (onFinish) -> createPhongMaterial(onFinish, 'beam.png', 'beam.normal.png', 12, new Vector(0.8, 0.8, 0.6, 1)),
		'interiors_mbu/beam_side.png' => (onFinish) -> createPhongMaterial(onFinish, 'beam_side.png', 'beam_side.normal.png', 12,
			new Vector(0.8, 0.8, 0.6, 1)),
		'interiors_mbu/friction_low.png' => (onFinish) -> createPhongMaterial(onFinish, 'friction_low.png', 'friction_low.normal.png', 128,
			new Vector(1, 1, 1, 0.8)),
		'interiors_mbu/friction_low_shadow.png' => (onFinish) -> createPhongMaterial(onFinish, 'friction_low_shadow.png', 'friction_low.normal.png', 128,
			new Vector(0.3, 0.3, 0.35, 1)),
		'interiors_mbu/friction_high.png' => (onFinish) -> createPhongMaterial(onFinish, 'friction_high.png', 'friction_high.normal.png', 10,
			new Vector(0.3, 0.3, 0.35, 1)),
		'interiors_mbu/friction_high_shadow.png' => (onFinish) -> createPhongMaterial(onFinish, 'friction_high_shadow.png', 'friction_high.normal.png', 10,
			new Vector(0.15, 0.15, 0.16, 1.0)),
		'interiors_mbu/stripe_caution.png' => (onFinish) -> createPhongMaterial(onFinish, 'stripe_caution.png', 'DefaultNormal.png', 12,
			new Vector(0.8, 0.8, 0.6, 1)),
	];

	public static function loadDif(path:String, itr:InteriorObject, onFinish:Void->Void, ?so:Int = -1) {
		#if (js || android)
		path = StringTools.replace(path, "data/", "");
		#end
		ResourceLoader.load(path).entry.load(() -> {
			var difresource = ResourceLoader.loadInterior(path);
			difresource.acquire();
			var dif = difresource.resource;
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
			var vertexBuckets = new Map<Point3F, Array<VertexBucket>>();
			var edges = [];
			var colliderSurfaces = [];
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
					colliderSurface.edgeData = [];
					colliderSurface.edgeConcavities = [];
					colliderSurface.originalIndices = [];
					colliderSurface.originalSurfaceIndex = surfaceindex;
					for (k in (surface.windingStart + 2)...(surface.windingStart + surface.windingCount)) {
						var p1, p2, p3;
						if ((k - (surface.windingStart + 2)) % 2 == 0) {
							p1 = points[geo.windings[k]];
							p2 = points[geo.windings[k - 1]];
							p3 = points[geo.windings[k - 2]];
							colliderSurface.originalIndices.push(geo.windings[k]);
							colliderSurface.originalIndices.push(geo.windings[k - 1]);
							colliderSurface.originalIndices.push(geo.windings[k - 2]);
						} else {
							p1 = points[geo.windings[k - 2]];
							p2 = points[geo.windings[k - 1]];
							p3 = points[geo.windings[k]];
							colliderSurface.originalIndices.push(geo.windings[k - 2]);
							colliderSurface.originalIndices.push(geo.windings[k - 1]);
							colliderSurface.originalIndices.push(geo.windings[k]);
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
						triangles.push(tri);
						hullTris.push(tri);
						var materialName = stripTexName(texture);
						var hasMaterialInfo = materialDict.exists(materialName);
						if (hasMaterialInfo) {
							var minfo = materialDict.get(materialName);
							colliderSurface.friction = minfo.friction;
							colliderSurface.restitution = minfo.restitution;
							colliderSurface.force = minfo.force != null ? minfo.force : 0;
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
									normals: []
								};
								buckets.push(bucket);
							}
							bucket.triangleIndices.push(triangles.length - 1);
							bucket.normals.push(normal);
						}
					}
					colliderSurface.generateBoundingBox();
					collider.addSurface(colliderSurface);
					colliderSurfaces.push(colliderSurface);
				}
			}
			var edgeMap:Map<Int, TriangleEdge> = new Map();
			var internalEdges:Map<Int, Bool> = new Map();
			var difEdges:Map<Int, Edge> = [];
			for (edge in edges) {
				var edgeHash = edge.index1 >= edge.index2 ? edge.index1 * edge.index1 + edge.index1 + edge.index2 : edge.index1 + edge.index2 * edge.index2;
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
			for (colliderSurface in colliderSurfaces) {
				var i = 0;
				while (i < colliderSurface.indices.length) {
					var e1e2 = hashEdge(colliderSurface.originalIndices[i], colliderSurface.originalIndices[i + 1]);
					var e2e3 = hashEdge(colliderSurface.originalIndices[i + 1], colliderSurface.originalIndices[i + 2]);
					var e1e3 = hashEdge(colliderSurface.originalIndices[i], colliderSurface.originalIndices[i + 2]);
					var edgeData = 0;
					if (difEdges.exists(e1e2)) {
						// if (getEdgeDot(difEdges[e1e2]) < Math.cos(Math.PI / 12)) {
						edgeData |= 1;
						// }
						colliderSurface.edgeConcavities.push(getEdgeConcavity(difEdges[e1e2]));
						// colliderSurface.edgeNormals.push(getEdgeNormal(difEdges[e1e2]));
					} else {
						colliderSurface.edgeConcavities.push(false);
						// colliderSurface.edgeNormals.push(new Vector(0, 0, 0));
					}
					if (difEdges.exists(e2e3)) {
						// if (getEdgeDot(difEdges[e2e3]) < Math.cos(Math.PI / 12)) {
						edgeData |= 2;
						// }
						colliderSurface.edgeConcavities.push(getEdgeConcavity(difEdges[e2e3]));
						// colliderSurface.edgeNormals.push(getEdgeNormal(difEdges[e2e3]));
						// colliderSurface.edgeDots.push(dot);
					} else {
						colliderSurface.edgeConcavities.push(false);
						// colliderSurface.edgeNormals.push(new Vector(0, 0, 0));
					}
					if (difEdges.exists(e1e3)) {
						// if (getEdgeDot(difEdges[e1e3]) < Math.cos(Math.PI / 12)) {
						edgeData |= 4;
						// }
						colliderSurface.edgeConcavities.push(getEdgeConcavity(difEdges[e1e3]));
						// colliderSurface.edgeNormals.push(getEdgeNormal(difEdges[e1e3]));
						// colliderSurface.edgeDots.push(dot);
					} else {
						colliderSurface.edgeConcavities.push(false);
						// colliderSurface.edgeNormals.push(new Vector(0, 0, 0));
					}
					colliderSurface.edgeData.push(edgeData);
					i += 3;
				}
			}
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
						if (tri.p1 == vtex)
							tri.normal1 = avgNormal;
						if (tri.p2 == vtex)
							tri.normal2 = avgNormal;
						if (tri.p3 == vtex)
							tri.normal3 = avgNormal;
					}
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
			collider.difEdgeMap = difEdges;
			collider.finalize();
			itr.collider = collider;
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
			var loadtexs = [];
			for (grp => tris in mats) {
				if (canFindTex(grp)) {
					loadtexs.push(tex(grp));
				}
			}
			var worker = new ResourceLoaderWorker(() -> {
				var shaderWorker = new ResourceLoaderWorker(() -> {
					difresource.release();
					onFinish();
				});

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
						texture.mipMap = Nearest;
						var exactName = StringTools.replace(texture.name, "data/", "");
						material = h3d.mat.Material.create(texture);
						if (shaderMaterialDict.exists(exactName)) {
							var retrievefunc = shaderMaterialDict[exactName];
							shaderWorker.addTask(fwd -> {
								retrievefunc(shad -> {
									material.mainPass.removeShader(material.textureShader);
									material.mainPass.addShader(shad);
									var thisprops:Dynamic = material.getDefaultProps();
									thisprops.light = false; // We will calculate our own lighting
									material.props = thisprops;
									material.shadows = false;
									material.receiveShadows = true;
									fwd();
								});
							});
							prim.addTangents();
						} else {
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

				shaderWorker.run();
			});
			for (f in loadtexs) {
				worker.loadFile(f);
			}
			worker.run();
		});
	}
}
