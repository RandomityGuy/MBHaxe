package src;

import dts.TSDrawPrimitive;
import hxd.res.Sound;
import h3d.col.Bounds;
import src.TimeState;
import shaders.Billboard;
import collision.BoxCollisionEntity;
import shaders.DtsTexture;
import h3d.shader.AlphaMult;
import src.MarbleWorld;
import src.GameObject;
import collision.CollisionHull;
import collision.CollisionSurface;
import collision.CollisionEntity;
import hxd.FloatBuffer;
import src.DynamicPolygon;
import dts.Sequence;
import h3d.scene.Mesh;
import h3d.prim.Polygon;
import h3d.prim.UV;
import h3d.Vector;
import h3d.Quat;
import dts.Node;
import h3d.mat.BlendMode;
import h3d.mat.Data.Wrap;
import h3d.mat.Texture;
import h3d.mat.Material;
import h3d.scene.Object;
import haxe.io.Path;
import src.ResourceLoader;
import dts.DtsFile;
import h3d.Matrix;
import src.Util;
import src.Resource;

var DROP_TEXTURE_FOR_ENV_MAP = ['shapes/items/superjump.dts', 'shapes/items/antigravity.dts'];

var dtsMaterials = [
	"oilslick" => {friction: 0.05, restitution: 0.5, force: 0.0},
	"base.slick" => {friction: 0.05, restitution: 0.5, force: 0.0},
	"ice.slick" => {friction: 0.05, restitution: 0.5, force: 0.0},
	"bumper-rubber" => {friction: 0.5, restitution: 0.0, force: 15.0},
	"triang-side" => {friction: 0.5, restitution: 0.0, force: 15.0},
	"triang-top" => {friction: 0.5, restitution: 0.0, force: 15.0},
	"pball-round-side" => {friction: 0.5, restitution: 0.0, force: 15.0},
	"pball-round-top" => {friction: 0.5, restitution: 0.0, force: 15.0},
	"pball-round-bottm" => {friction: 0.5, restitution: 0.0, force: 15.0}
];

typedef GraphNode = {
	var index:Int;
	var node:Node;
	var children:Array<GraphNode>;
	var parent:GraphNode;
}

typedef MaterialGeometry = {
	var vertices:Array<Vector>;
	var normals:Array<Vector>;
	var uvs:Array<UV>;
	var indices:Array<Int>;
}

typedef SkinMeshData = {
	var meshIndex:Int;
	var vertices:Array<Vector>;
	var normals:Array<Vector>;
	var indices:Array<Int>;
	var geometry:Object;
}

@:publicFields
class DtsObject extends GameObject {
	var dtsPath:String;
	var directoryPath:String;
	var dts:DtsFile;
	var dtsResource:Resource<DtsFile>;

	var level:MarbleWorld;

	var materials:Array<Material> = [];
	var materialInfos:Map<Material, Array<String>> = new Map();
	var matNameOverride:Map<String, String> = new Map();

	var sequenceKeyframeOverride:Map<Sequence, Float> = new Map();
	var lastSequenceKeyframes:Map<Sequence, Float> = new Map();

	var graphNodes:Array<Object> = [];
	var dirtyTransforms:Array<Bool> = [];

	var useInstancing:Bool = true;
	var isTSStatic:Bool;
	var showSequences:Bool = true;
	var hasNonVisualSequences:Bool = true;
	var isInstanced:Bool = false;

	var _regenNormals:Bool = false;

	var skinMeshData:SkinMeshData;

	var rootObject:Object;
	var colliders:Array<CollisionEntity>;
	var boundingCollider:BoxCollisionEntity;

	var mountPointNodes:Array<Int>;
	var alphaShader:AlphaMult;

	var ambientRotate = false;
	var ambientSpinFactor = -1 / 3 * Math.PI * 2;

	public var idInLevel:Int = -1;

	public function new() {
		super();
	}

	public function init(level:MarbleWorld, onFinish:Void->Void) {
		this.dtsResource = ResourceLoader.loadDts(this.dtsPath);
		this.dtsResource.acquire();
		this.dts = this.dtsResource.resource;

		this.directoryPath = Path.directory(this.dtsPath);
		if (level != null)
			this.level = level;

		isInstanced = false;
		if (this.level != null)
			isInstanced = this.level.instanceManager.isInstanced(this) && useInstancing;
		if (!isInstanced)
			this.computeMaterials();

		var graphNodes = [];
		var rootNodesIdx = [];
		colliders = [];
		this.mountPointNodes = [for (i in 0...32) -1];

		for (i in 0...this.dts.nodes.length) {
			graphNodes.push(new Object());
		}

		for (i in 0...this.dts.nodes.length) {
			var node = this.dts.nodes[i];
			if (node.parent != -1) {
				graphNodes[node.parent].addChild(graphNodes[i]);
			} else {
				rootNodesIdx.push(i);
			}
		}

		this.graphNodes = graphNodes;
		// this.rootGraphNodes = graphNodes.filter(node -> node.parent == null);

		var affectedBySequences = this.dts.sequences.length > 0 ? (this.dts.sequences[0].rotationMatters.length < 0 ? 0 : this.dts.sequences[0].rotationMatters[0]) | (this.dts.sequences[0].translationMatters.length > 0 ? this.dts.sequences[0].translationMatters[0] : 0) : 0;

		for (i in 0...dts.nodes.length) {
			var objects = dts.objects.filter(object -> object.node == i);
			var sequenceAffected = ((1 << i) & affectedBySequences) != 0;

			if (dts.names[dts.nodes[i].name].substr(0, 5) == "mount") {
				var mountindex = dts.names[dts.nodes[i].name].substr(5);
				var mountNode = Std.parseInt(mountindex);
				mountPointNodes[mountNode] = i;
			}

			for (object in objects) {
				var isCollisionObject = dts.names[object.name].substr(0, 3).toLowerCase() == "col";

				if (isCollisionObject)
					continue;

				for (j in object.firstMesh...(object.firstMesh + object.numMeshes)) {
					if (j >= this.dts.meshes.length)
						continue;

					var mesh = this.dts.meshes[j];
					if (mesh == null)
						continue;

					if (!isInstanced) {
						var vertices = mesh.vertices.map(v -> new Vector(-v.x, v.y, v.z));
						var vertexNormals = mesh.normals.map(v -> new Vector(-v.x, v.y, v.z));

						var geometry = this.generateMaterialGeometry(mesh, vertices, vertexNormals);
						for (k in 0...geometry.length) {
							if (geometry[k].vertices.length == 0)
								continue;

							var poly = new Polygon(geometry[k].vertices.map(x -> x.toPoint()));
							poly.normals = geometry[k].normals.map(x -> x.toPoint());
							poly.uvs = geometry[k].uvs;

							var obj = new Mesh(poly, materials[k], this.graphNodes[i]);
						}
					} else {
						var usedMats = [];

						for (prim in mesh.primitives) {
							if (!usedMats.contains(prim.matIndex)) {
								usedMats.push(prim.matIndex);
							}
						}

						for (k in usedMats) {
							var obj = new Object(this.graphNodes[i]);
						}
					}
				}
			}
		}

		if (this.isCollideable) {
			for (i in 0...dts.nodes.length) {
				var objects = dts.objects.filter(object -> object.node == i);
				var localColliders:Array<CollisionEntity> = [];

				for (object in objects) {
					var isCollisionObject = dts.names[object.name].substr(0, 3).toLowerCase() == "col";

					if (isCollisionObject) {
						for (j in object.firstMesh...(object.firstMesh + object.numMeshes)) {
							if (j >= this.dts.meshes.length)
								continue;

							var mesh = this.dts.meshes[j];
							if (mesh == null)
								continue;

							var vertices = mesh.vertices.map(v -> new Vector(-v.x, v.y, v.z));
							var vertexNormals = mesh.normals.map(v -> new Vector(-v.x, v.y, v.z));

							var hulls = this.generateCollisionGeometry(mesh, vertices, vertexNormals, i);
							localColliders = localColliders.concat(hulls);
						}
					}
				}
				colliders = colliders.concat(localColliders);
			}
		}

		this.updateNodeTransforms();

		for (i in 0...this.dts.meshes.length) {
			var mesh = this.dts.meshes[i];
			if (mesh == null)
				continue;

			if (mesh.meshType == 1) {
				var skinObj = new Object();

				if (!isInstanced) {
					var vertices = mesh.vertices.map(v -> new Vector(-v.x, v.y, v.z));
					var vertexNormals = mesh.normals.map(v -> new Vector(-v.x, v.y, v.z));
					var geometry = this.generateMaterialGeometry(mesh, vertices, vertexNormals);
					for (k in 0...geometry.length) {
						if (geometry[k].vertices.length == 0)
							continue;

						var poly = new DynamicPolygon(geometry[k].vertices.map(x -> x.toPoint()));
						poly.normals = geometry[k].normals.map(x -> x.toPoint());
						poly.uvs = geometry[k].uvs;

						var obj = new Mesh(poly, materials[k], skinObj);
					}
					skinMeshData = {
						meshIndex: i,
						vertices: vertices,
						normals: vertexNormals,
						indices: [],
						geometry: skinObj
					};
					var idx = geometry.map(x -> x.indices);
					for (indexes in idx) {
						skinMeshData.indices = skinMeshData.indices.concat(indexes);
					}
				} else {
					var usedMats = [];

					for (prim in mesh.primitives) {
						if (!usedMats.contains(prim.matIndex)) {
							usedMats.push(prim.matIndex);
						}
					}

					for (k in usedMats) {
						var obj = new Object(skinObj);
					}
					skinMeshData = {
						meshIndex: i,
						vertices: [],
						normals: [],
						indices: [],
						geometry: skinObj
					};
				}
			}
		}

		if (!this.isInstanced) {
			for (i in 0...this.materials.length) {
				var info = this.materialInfos.get(this.materials[i]);
				if (info == null)
					continue;

				var iflSequence = this.dts.sequences.filter(seq -> seq.iflMatters.length > 0 ? seq.iflMatters[0] > 0 : false);
				if (iflSequence.length == 0)
					continue;

				var completion = 0 / (iflSequence[0].duration);
				var keyframe = Math.floor(completion * info.length) % info.length;
				var currentFile = info[keyframe];
				var texture = ResourceLoader.getResource(this.directoryPath + '/' + currentFile, ResourceLoader.getTexture, this.textureResources);

				var flags = this.dts.matFlags[i];
				if (flags & 1 > 0 || flags & 2 > 0)
					texture.wrap = Wrap.Repeat;

				this.materials[i].texture = texture;
			}
		}

		rootObject = new Object(this);

		for (i in rootNodesIdx) {
			rootObject.addChild(this.graphNodes[i]);
		}

		if (this.skinMeshData != null) {
			rootObject.addChild(this.skinMeshData.geometry);
		}

		// rootObject.scaleX = -1;

		if (this.level != null && this.isBoundingBoxCollideable) {
			var boundthing = new Bounds();
			for (mesh in this.dts.meshes) {
				if (mesh == null)
					continue;
				for (pt in mesh.vertices)
					boundthing.addPoint(new h3d.col.Point(-pt.x, pt.y, pt.z));
			}
			boundthing.addPoint(new h3d.col.Point(this.dts.bounds.minX, this.dts.bounds.minY, this.dts.bounds.minZ));
			boundthing.addPoint(new h3d.col.Point(this.dts.bounds.maxX, this.dts.bounds.maxY, this.dts.bounds.maxZ));
			this.boundingCollider = new BoxCollisionEntity(boundthing, cast this);
			this.boundingCollider.setTransform(this.getTransform());
		}

		this.dirtyTransforms = [];
		for (i in 0...graphNodes.length) {
			this.dirtyTransforms.push(true);
		}

		onFinish();
	}

	function computeMaterials() {
		var environmentMaterial:Material = null;

		for (i in 0...dts.matNames.length) {
			var matName = matNameOverride.exists(dts.matNames[i]) ? matNameOverride.get(dts.matNames[i]) : this.dts.matNames[i];
			var flags = dts.matFlags[i];
			var fullNames = ResourceLoader.getFullNamesOf(this.directoryPath + '/' + matName).filter(x -> Path.extension(x) != "dts");
			var fullName = fullNames.length > 0 ? fullNames[0] : null;

			if (this.isTSStatic && environmentMaterial != null && DROP_TEXTURE_FOR_ENV_MAP.contains(this.dtsPath)) {
				this.materials.push(environmentMaterial);
				continue;
			}

			var material = Material.create();

			var iflMaterial = false;

			if (fullName == null || (this.isTSStatic && ((flags & (1 << 31) > 0)))) {
				if (this.isTSStatic) {
					// TODO USE PBR???
				}
			} else if (Path.extension(fullName) == "ifl") {
				var keyframes = parseIfl(fullName);
				this.materialInfos.set(material, keyframes);
				iflMaterial = true;
			} else {
				var texture = ResourceLoader.getResource(fullName, ResourceLoader.getTexture, this.textureResources);
				texture.wrap = Wrap.Repeat;
				material.texture = texture;
				if (this.useInstancing) {
					var dtsshader = new DtsTexture();
					dtsshader.texture = texture;
					dtsshader.currentOpacity = 1;
					if (this.identifier == "Tornado")
						dtsshader.normalizeNormals = false; // These arent normalized
					material.mainPass.removeShader(material.textureShader);
					material.mainPass.addShader(dtsshader);
				}
				// TODO TRANSLUENCY SHIT
			}
			material.shadows = false;
			if (this.isCollideable)
				material.receiveShadows = true;
			if (material.texture == null && !iflMaterial) {
				var dtsshader = new DtsTexture();
				dtsshader.currentOpacity = 1;
				if (this.identifier == "Tornado")
					dtsshader.normalizeNormals = false; // These arent normalized
				// Make a 1x1 white texture
				#if hl
				var bitmap = new hxd.BitmapData(1, 1);
				bitmap.lock();
				bitmap.setPixel(0, 0, 0xFFFFFF);
				bitmap.unlock();
				var texture = new Texture(1, 1);
				texture.uploadBitmap(bitmap);
				texture.wrap = Wrap.Repeat;
				#end
				// Apparently creating these bitmap datas dont work so we'll just get the snag a white texture in the filesystem
				#if js
				var texture:Texture = ResourceLoader.getResource("data/shapes/pads/white.jpg", ResourceLoader.getTexture, this.textureResources);
				texture.wrap = Wrap.Repeat;
				#end
				material.texture = texture;
				dtsshader.texture = texture;
				material.mainPass.addShader(dtsshader);
				material.shadows = false;
			}
			if (flags & 4 > 0) {
				material.blendMode = BlendMode.Alpha;
				material.mainPass.culling = h3d.mat.Data.Face.None;
				material.receiveShadows = false;
				material.mainPass.depthWrite = false;
			}
			// // TODO TRANSPARENCY SHIT
			if (flags & 8 > 0) {
				material.blendMode = BlendMode.Add;
				// material.mainPass.setPassName("overlay");
				// material.textureShader.additive = true;
			}
			if (flags & 16 > 0) {
				material.blendMode = BlendMode.Sub;
			}

			if (flags & 32 > 0) {
				material.mainPass.enableLights = false;
				material.receiveShadows = false;
				// material.mainPass.setPassName("overlay");
				// var pbrprops = material.mainPass.getShader(h3d.shader.pbr.PropsValues);
				// pbrprops.emissiveValue = 1;
				// pbrprops.roughnessValue = 1;
				// pbrprops.occlusionValue = 0;
				// pbrprops.metalnessValue = 0;
			}

			// if (this.isTSStatic && !(flags & 64 > 0)) {
			// 	// TODO THIS SHIT
			// }
			// ((flags & 32) || environmentMaterial) ? new Materia

			// material.mainPass.addShader(new AlphaMult());

			this.materials.push(material);
		}

		if (this.materials.length == 0) {
			#if hl
			var bitmap = new hxd.BitmapData(1, 1);
			bitmap.lock();
			bitmap.setPixel(0, 0, 0xFFFFFF);
			bitmap.unlock();
			var texture = new Texture(1, 1);
			texture.uploadBitmap(bitmap);
			texture.wrap = Wrap.Repeat;
			#end
			// Apparently creating these bitmap datas dont work so we'll just get the snag a white texture in the filesystem
			#if js
			var texture:Texture = ResourceLoader.getResource("data/shapes/pads/white.jpg", ResourceLoader.getTexture, this.textureResources);
			texture.wrap = Wrap.Repeat;
			#end
			var dtsshader = new DtsTexture();
			var mat = Material.create();
			mat.texture = texture;
			dtsshader.texture = texture;
			mat.mainPass.addShader(dtsshader);
			mat.shadows = false;
			this.materials.push(mat);
			// TODO THIS
		}
	}

	function parseIfl(path:String) {
		var text = ResourceLoader.fileSystem.get(path).getText();
		var lines = text.split('\n');
		var keyframes = [];
		for (line in lines) {
			line = StringTools.trim(line);
			if (line.substr(0, 2) == "//")
				continue;
			if (line == "")
				continue;

			var parts = line.split(' ');
			var count = parts.length > 1 ? Std.parseInt(parts[1]) : 1;

			for (i in 0...count) {
				keyframes.push(parts[0]);
			}
		}

		return keyframes;
	}

	function updateNodeTransforms(quaternions:Array<Quat> = null, translations:Array<Vector> = null, bitField = 0xffffffff) {
		for (i in 0...this.graphNodes.length) {
			var translation = this.dts.defaultTranslations[i];
			var rotation = this.dts.defaultRotations[i];
			var mat = Matrix.I();
			var quat = new Quat(-rotation.x, rotation.y, rotation.z, -rotation.w);
			quat.normalize();
			quat.conjugate();
			quat.toMatrix(mat);
			mat.setPosition(new Vector(-translation.x, translation.y, translation.z));
			this.graphNodes[i].setTransform(mat);
			var absTform = this.graphNodes[i].getAbsPos().clone();
			if (this.colliders[i] != null)
				// this.colliders[i].setTransform(Matrix.I());
				this.colliders[i].setTransform(absTform);
		}
	}

	function generateCollisionGeometry(dtsMesh:dts.Mesh, vertices:Array<Vector>, vertexNormals:Array<Vector>, node:Int) {
		var hulls:Array<CollisionEntity> = [];
		for (primitive in dtsMesh.primitives) {
			var k = 0;

			var chull = new CollisionHull(cast this);
			chull.userData = node;
			var hs = new CollisionSurface();
			hs.points = [];
			hs.normals = [];
			hs.indices = [];
			hs.transformKeys = [];

			var material = this.dts.matNames[primitive.matIndex & TSDrawPrimitive.MaterialMask];
			if (dtsMaterials.exists(material) && !this.isTSStatic) {
				var data = dtsMaterials.get(material);
				hs.friction = data.friction;
				hs.force = data.force;
				hs.restitution = data.restitution;
			}

			for (i in primitive.firstElement...(primitive.firstElement + primitive.numElements - 2)) {
				var i1 = dtsMesh.indices[i];
				var i2 = dtsMesh.indices[i + 1];
				var i3 = dtsMesh.indices[i + 2];

				if (k % 2 == 0) {
					// Swap the first and last index to mainting correct winding order
					var temp = i1;
					i1 = i3;
					i3 = temp;
				}

				for (index in [i1, i2, i3]) {
					var vertex = vertices[index];
					hs.points.push(new Vector(vertex.x, vertex.y, vertex.z));
					hs.transformKeys.push(0);

					var normal = vertexNormals[index];
					hs.normals.push(new Vector(normal.x, normal.y, normal.z));
				}

				hs.indices.push(hs.indices.length);
				hs.indices.push(hs.indices.length);
				hs.indices.push(hs.indices.length);

				k++;
			}

			hs.generateBoundingBox();
			chull.addSurface(hs);
			chull.generateBoundingBox();
			chull.finalize();
			hulls.push(chull);
		}
		return hulls;
	}

	function generateMaterialGeometry(dtsMesh:dts.Mesh, vertices:Array<Vector>, vertexNormals:Array<Vector>) {
		var materialGeometry:Array<MaterialGeometry> = this.dts.matNames.map(x -> {
			vertices: [],
			normals: [],
			uvs: [],
			indices: []
		});
		if (materialGeometry.length == 0 && dtsMesh.primitives.length > 0) {
			materialGeometry.push({
				vertices: [],
				normals: [],
				uvs: [],
				indices: []
			});
		}

		for (primitive in dtsMesh.primitives) {
			var k = 0;
			var geometrydata = materialGeometry[primitive.matIndex];

			for (i in primitive.firstElement...(primitive.firstElement + primitive.numElements - 2)) {
				var i1 = dtsMesh.indices[i];
				var i2 = dtsMesh.indices[i + 1];
				var i3 = dtsMesh.indices[i + 2];

				if (k % 2 == 0) {
					// Swap the first and last index to mainting correct winding order
					var temp = i1;
					i1 = i3;
					i3 = temp;
				}

				for (index in [i1, i2, i3]) {
					var vertex = vertices[index];
					geometrydata.vertices.push(new Vector(vertex.x, vertex.y, vertex.z));

					var uv = dtsMesh.uv[index];
					geometrydata.uvs.push(new UV(uv.x, uv.y));

					var normal = vertexNormals[index];
					geometrydata.normals.push(new Vector(normal.x, normal.y, normal.z));
				}

				geometrydata.indices.push(i1);
				geometrydata.indices.push(i2);
				geometrydata.indices.push(i3);

				k++;
			}
		}

		return materialGeometry;
	}

	function mergeMaterialGeometries(materialGeometries:Array<Array<MaterialGeometry>>) {
		var merged = materialGeometries[0].map(x -> {
			vertices: [],
			normals: [],
			uvs: [],
			indices: []
		});

		for (matGeom in materialGeometries) {
			for (i in 0...matGeom.length) {
				merged[i].vertices = merged[i].vertices.concat(matGeom[i].vertices);
				merged[i].normals = merged[i].normals.concat(matGeom[i].normals);
				merged[i].uvs = merged[i].uvs.concat(matGeom[i].uvs);
				merged[i].indices = merged[i].indices.concat(matGeom[i].indices);
			}
		}

		return merged;
	}

	function createGeometryFromMaterialGeometry(materialGeometry:Array<MaterialGeometry>) {
		var geo = new Object();
		for (i in 0...materialGeometry.length) {
			if (materialGeometry[i].vertices.length == 0)
				continue;

			var poly = new Polygon(materialGeometry[i].vertices.map(x -> x.toPoint()));
			poly.normals = materialGeometry[i].normals.map(x -> x.toPoint());
			poly.uvs = materialGeometry[i].uvs;

			var obj = new Mesh(poly, materials[i], geo);
		}
		return geo;
	}

	public override function setTransform(mat:Matrix) {
		super.setTransform(mat);
		if (this.isBoundingBoxCollideable) {
			this.boundingCollider.setTransform(mat);
			this.level.collisionWorld.updateTransform(this.boundingCollider);
		}
		for (i in 0...this.dirtyTransforms.length) {
			this.dirtyTransforms[i] = true;
		}
	}

	public function update(timeState:TimeState) {
		for (sequence in this.dts.sequences) {
			if (!this.showSequences)
				break;
			if (!this.hasNonVisualSequences)
				break;

			var rot = sequence.rotationMatters.length > 0 ? sequence.rotationMatters[0] : 0;
			var trans = sequence.translationMatters.length > 0 ? sequence.translationMatters[0] : 0;
			var scale = sequence.scaleMatters.length > 0 ? sequence.scaleMatters[0] : 0;
			var affectedCount = 0;
			var completion = timeState.timeSinceLoad / sequence.duration;

			var quaternions:Array<Quat> = null;
			var translations:Array<Vector> = null;
			var scales:Array<Vector> = null;

			var actualKeyframe = this.sequenceKeyframeOverride.exists(sequence) ? this.sequenceKeyframeOverride.get(sequence) : ((completion * sequence.numKeyFrames) % sequence.numKeyFrames);
			if (this.lastSequenceKeyframes.get(sequence) == actualKeyframe)
				continue;
			lastSequenceKeyframes.set(sequence, actualKeyframe);

			var keyframeLow = Math.floor(actualKeyframe);
			var keyframeHigh = Math.ceil(actualKeyframe) % sequence.numKeyFrames;
			var t = (actualKeyframe - keyframeLow) % 1;

			if (rot > 0) {
				quaternions = [];

				for (i in 0...this.dts.nodes.length) {
					var affected = ((1 << i) & rot) != 0;

					if (affected) {
						var rot1 = this.dts.nodeRotations[sequence.numKeyFrames * affectedCount + keyframeLow];
						var rot2 = this.dts.nodeRotations[sequence.numKeyFrames * affectedCount + keyframeHigh];

						var q1 = new Quat(-rot1.x, rot1.y, rot1.z, -rot1.w);
						q1.normalize();
						q1.conjugate();

						var q2 = new Quat(-rot2.x, rot2.y, rot2.z, -rot2.w);
						q2.normalize();
						q2.conjugate();

						var quat = new Quat();
						quat.slerp(q1, q2, t);
						quat.normalize();

						this.graphNodes[i].setRotationQuat(quat);
						this.dirtyTransforms[i] = true;
						affectedCount++;
						// quaternions.push(quat);
					} else {
						var rotation = this.dts.defaultRotations[i];
						var quat = new Quat(-rotation.x, rotation.y, rotation.z, -rotation.w);
						quat.normalize();
						quat.conjugate();
						this.graphNodes[i].setRotationQuat(quat);
						// quaternions.push(quat);
					}
				}
			}

			affectedCount = 0;
			if (trans > 0) {
				translations = [];

				for (i in 0...this.dts.nodes.length) {
					var affected = ((1 << i) & trans) != 0;

					if (affected) {
						var trans1 = this.dts.nodeTranslations[sequence.numKeyFrames * affectedCount + keyframeLow];
						var trans2 = this.dts.nodeTranslations[sequence.numKeyFrames * affectedCount + keyframeHigh];

						var v1 = new Vector(-trans1.x, trans1.y, trans1.z);
						var v2 = new Vector(-trans2.x, trans2.y, trans2.z);
						var trans = Util.lerpThreeVectors(v1, v2, t);
						this.graphNodes[i].setPosition(trans.x, trans.y, trans.z);
						this.dirtyTransforms[i] = true;

						// translations.push(Util.lerpThreeVectors(v1, v2, t));
					} else {
						var translation = this.dts.defaultTranslations[i];
						var trans = new Vector(-translation.x, translation.y, translation.z);
						this.graphNodes[i].setPosition(trans.x, trans.y, trans.z);
						// translations.push();
					}
				}
			}

			if (scale > 0) {
				scales = [];

				for (i in 0...this.dts.nodes.length) {
					var affected = ((1 << i) & scale) != 0;

					if (affected) {
						var scale1 = this.dts.nodeAlignedScales[sequence.numKeyFrames * affectedCount + keyframeLow];
						var scale2 = this.dts.nodeAlignedScales[sequence.numKeyFrames * affectedCount + keyframeHigh];

						var v1 = new Vector(scale1.x, scale1.y, scale1.z);
						var v2 = new Vector(scale2.x, scale2.y, scale2.z);

						var scaleVec = Util.lerpThreeVectors(v1, v2, t);
						this.graphNodes[i].scaleX = scaleVec.x;
						this.graphNodes[i].scaleY = scaleVec.y;
						this.graphNodes[i].scaleZ = scaleVec.z;

						this.dirtyTransforms[i] = true;
					} else {
						this.graphNodes[i].scaleX = 1;
						this.graphNodes[i].scaleY = 1;
						this.graphNodes[i].scaleZ = 1;
					}
				}
			}
		}

		if (this.skinMeshData != null && !isInstanced) {
			var info = this.skinMeshData;
			var mesh = this.dts.meshes[info.meshIndex];

			for (i in 0...info.vertices.length) {
				info.vertices[i] = new Vector();
				info.normals[i] = new Vector();
			}

			var boneTransformations = [];

			for (i in 0...mesh.nodeIndices.length) {
				var mat = mesh.initialTransforms[i].clone();
				mat.scale(-1);
				mat.transpose();
				var tform = this.graphNodes[mesh.nodeIndices[i]].getRelPos(this).clone();
				tform.prependScale(-1);
				mat.multiply(mat, tform);

				boneTransformations.push(mat);
			}

			for (i in 0...mesh.vertexIndices.length) {
				var vIndex = mesh.vertexIndices[i];
				var vertex = mesh.vertices[vIndex];
				var normal = mesh.normals[vIndex];

				var vec = new Vector();
				var vec2 = new Vector();

				vec.set(-vertex.x, vertex.y, vertex.z);
				vec2.set(-normal.x, normal.y, normal.z);
				var mat = boneTransformations[mesh.boneIndices[i]];

				vec.transform(mat);
				vec = vec.multiply(mesh.weights[i]);

				Util.m_matF_x_vectorF(mat, vec2);
				vec2 = vec2.multiply(mesh.weights[i]);

				info.vertices[vIndex] = info.vertices[vIndex].add(vec);
				info.normals[vIndex] = info.normals[vIndex].add(vec2);
			}

			for (i in 0...info.normals.length) {
				var norm = info.normals[i];
				var len2 = norm.dot(norm);

				if (len2 > 0.01)
					norm.normalize();
			}

			var meshIndex = 0;
			var mesh:Mesh = cast info.geometry.children[meshIndex];
			var prim:DynamicPolygon = cast mesh.primitive;
			var vbuffer:FloatBuffer = null;
			if (prim.buffer != null) {
				vbuffer = prim.getDrawBuffer(prim.points.length);
			}
			var pos = 0;
			for (i in info.indices) {
				if (pos >= prim.points.length) {
					meshIndex++;
					mesh.primitive = prim;
					mesh = cast info.geometry.children[meshIndex];
					prim = cast mesh.primitive;
					pos = 0;
					if (prim.buffer != null) {
						vbuffer = prim.getDrawBuffer(prim.points.length);
					}
				}
				var vertex = info.vertices[i];
				var normal = info.normals[i];
				prim.points[pos] = vertex.toPoint();
				prim.normals[pos] = normal.toPoint(); // .normalized();
				if (prim.buffer != null) {
					prim.dirtyFlags[pos] = true;
				}
				pos++;
			}
			if (prim.buffer != null) {
				// prim.addNormals();
				// for (norm in prim.normals)
				// 	norm = norm.multiply(-1);
				prim.flush();
			}
			if (_regenNormals) {
				_regenNormals = false;
			}
		}

		if (!this.isInstanced && !this.isTSStatic) {
			for (i in 0...this.materials.length) {
				var info = this.materialInfos.get(this.materials[i]);
				if (info == null)
					continue;

				var iflSequence = this.dts.sequences.filter(seq -> seq.iflMatters.length > 0 ? seq.iflMatters[0] > 0 : false);
				if (iflSequence.length == 0 || !this.showSequences)
					continue;

				var completion = timeState.timeSinceLoad / (iflSequence[0].duration);
				var keyframe = Math.floor(completion * info.length) % info.length;
				var currentFile = info[keyframe];
				var texture = ResourceLoader.getResource(this.directoryPath + '/' + currentFile, ResourceLoader.getTexture, this.textureResources);

				var flags = this.dts.matFlags[i];
				if (flags & 1 > 0 || flags & 2 > 0)
					texture.wrap = Wrap.Repeat;

				this.materials[i].texture = texture;
			}
		}

		if (this.ambientRotate) {
			var spinAnimation = new Quat();
			spinAnimation.initRotateAxis(0, 0, -1, timeState.timeSinceLoad * this.ambientSpinFactor);

			var orientation = this.getRotationQuat();
			// spinAnimation.multiply(orientation, spinAnimation);

			this.rootObject.setRotationQuat(spinAnimation);
		}

		for (i in 0...this.colliders.length) {
			if (this.dirtyTransforms[this.colliders[i].userData]) {
				var absTform = this.graphNodes[this.colliders[i].userData].getAbsPos().clone();
				if (this.colliders[i] != null) {
					this.colliders[i].setTransform(absTform);
					this.level.collisionWorld.updateTransform(this.colliders[i]);
				}
			}
		}
		for (i in 0...this.dirtyTransforms.length) {
			this.dirtyTransforms[i] = false;
		}
	}

	public function getMountTransform(mountPoint:Int) {
		if (mountPoint < 32) {
			var ni = mountPointNodes[mountPoint];
			if (ni != -1) {
				var mtransform = this.graphNodes[ni].getAbsPos();
				return mtransform;
			}
		}
		return this.getTransform();
	}

	public function setOpacity(opacity:Float) {
		if (opacity == this.currentOpacity)
			return;
		this.currentOpacity = opacity;

		if (!this.useInstancing) {
			for (material in this.materials) {
				if (this.currentOpacity != 1) {
					// material.blendMode = BlendMode.Alpha;
					// 	if (this.alphaShader == null) {
					// 		this.alphaShader = new AlphaMult();
					// 	}
					// 	if (material.mainPass.getShader(AlphaMult) == null) {
					// 		material.mainPass.addShader(this.alphaShader);
					// 	}
					// 	this.alphaShader.alpha = this.currentOpacity;
					// } else {
					// 	if (alphaShader != null) {
					// 		alphaShader.alpha = this.currentOpacity;
					// 	}
				}
			}
		}
	}

	public function setHide(hide:Bool) {
		if (hide) {
			this.setCollisionEnabled(false);
			this.setOpacity(0);
		} else {
			this.setCollisionEnabled(true);
			this.setOpacity(1);
		}
	}

	public function setCollisionEnabled(flag:Bool) {
		this.isCollideable = flag;
	}

	public override function dispose() {
		super.dispose();
		this.dtsResource.release();
	}
}
