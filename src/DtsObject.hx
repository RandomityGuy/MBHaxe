package src;

import dts.Sequence;
import h3d.scene.Mesh;
import h3d.scene.CustomObject;
import h3d.prim.Polygon;
import h3d.prim.UV;
import h3d.Vector;
import h3d.Quat;
import dts.Node;
import h3d.mat.BlendMode;
import h3d.mat.Data.Wrap;
import h3d.mat.Texture;
import hxd.res.Loader;
import h3d.mat.Material;
import h3d.scene.Object;
import haxe.io.Path;
import src.ResourceLoader;
import dts.DtsFile;
import h3d.Matrix;
import src.Util;

var DROP_TEXTURE_FOR_ENV_MAP = ['shapes/items/superjump.dts', 'shapes/items/antigravity.dts'];

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
class DtsObject extends Object {
	var dtsPath:String;
	var directoryPath:String;
	var dts:DtsFile;

	var materials:Array<Material> = [];
	var matNameOverride:Map<String, String> = new Map();

	var sequenceKeyframeOverride:Map<Sequence, Float> = new Map();
	var lastSequenceKeyframes:Map<Sequence, Float> = new Map();

	var graphNodes:Array<GraphNode> = [];
	var rootGraphNodes:Array<GraphNode> = [];
	var nodeTransforms:Array<Matrix> = [];

	var dynamicGeometryLookup:Map<Object, Int> = new Map();

	var isTSStatic:Bool;
	var isCollideable:Bool;
	var showSequences:Bool = true;
	var hasNonVisualSequences:Bool = true;

	var geometries:Array<Object> = [];
	var skinMeshData:SkinMeshData;

	var fs:Loader;

	public function new() {
		super();
	}

	public function init() {
		this.dts = ResourceLoader.loadDts(this.dtsPath);
		this.directoryPath = Path.directory(this.dtsPath);

		for (i in 0...dts.nodes.length)
			this.nodeTransforms.push(new Matrix());

		this.computeMaterials();

		var graphNodes = [];
		for (i in 0...dts.nodes.length) {
			var graphNode:GraphNode = {
				index: i,
				node: dts.nodes[i],
				children: [],
				parent: null
			};
			graphNodes.push(graphNode);
		}
		for (i in 0...dts.nodes.length) {
			var node = this.dts.nodes[i];
			if (node.parent != -1) {
				graphNodes[i].parent = graphNodes[node.parent];
				graphNodes[node.parent].children.push(graphNodes[i]);
			}
		}

		this.graphNodes = graphNodes;
		this.rootGraphNodes = graphNodes.filter(node -> node.parent == null);
		this.updateNodeTransforms();

		var affectedBySequences = this.dts.sequences.length > 0 ? (this.dts.sequences[0].rotationMatters.length < 0 ? 0 : this.dts.sequences[0].rotationMatters[0]) | (this.dts.sequences[0].translationMatters.length > 0 ? this.dts.sequences[0].translationMatters[0] : 0) : 0;

		var staticMaterialGeometries = [];
		var dynamicMaterialGeometries = [];
		var dynamicGeometriesMatrices = [];
		var collisionMaterialGeometries = [];

		var staticGeometries = [];
		var dynamicGeometries = [];
		var collisionGeometries = [];

		for (i in 0...dts.nodes.length) {
			var objects = dts.objects.filter(object -> object.node == i);
			var sequenceAffected = ((1 << i) & affectedBySequences) != 0;

			for (object in objects) {
				var isCollisionObject = dts.names[object.name].substr(0, 3).toLowerCase() == "col";

				if (!isCollisionObject || this.isCollideable) {
					var mat = this.nodeTransforms[i];

					for (i in object.firstMesh...(object.firstMesh + object.numMeshes)) {
						if (i >= this.dts.meshes.length)
							continue;

						var mesh = this.dts.meshes[i];

						var vertices = mesh.vertices.map(v -> new Vector(v.x, v.y, v.z));
						var vertexNormals = mesh.normals.map(v -> new Vector(v.x, v.y, v.z));

						if (!sequenceAffected)
							for (vector in vertices) {
								vector.transform(mat);
							}
						if (!sequenceAffected)
							for (vector in vertexNormals) {
								vector.transform3x3(mat);
							}

						var geometry = this.generateMaterialGeometry(mesh, vertices, vertexNormals);
						if (!sequenceAffected) {
							staticMaterialGeometries.push(geometry);
						} else {
							dynamicMaterialGeometries.push(geometry);
							dynamicGeometriesMatrices.push(mat);
						}

						if (isCollisionObject)
							collisionMaterialGeometries.push(geometry);
					}
				}
			}
		}

		var skinnedMeshIndex:Int = -1;
		for (i in 0...dts.meshes.length) {
			var dtsMesh = this.dts.meshes[i];

			if (dtsMesh == null || dtsMesh.type != 1)
				continue;

			var vertices = [];
			for (i in 0...dtsMesh.vertices.length)
				vertices.push(new Vector());

			var vertexNormals = [];
			for (i in 0...dtsMesh.normals.length)
				vertexNormals.push(new Vector());

			var materialGeometry = this.generateMaterialGeometry(dtsMesh, vertices, vertexNormals);
			staticMaterialGeometries.push(materialGeometry);

			skinnedMeshIndex = i;
			break; // Bruh
		}

		var staticNonCollision = staticMaterialGeometries.filter(x -> !collisionMaterialGeometries.contains(x));
		var staticCollision = staticMaterialGeometries.filter(x -> collisionMaterialGeometries.contains(x));

		if (staticNonCollision.length > 0) {
			var merged = this.mergeMaterialGeometries(staticNonCollision);
			var geometry = this.createGeometryFromMaterialGeometry(merged);
			staticGeometries.push(geometry);
			this.geometries.push(geometry);

			if (skinnedMeshIndex != -1) {
				this.skinMeshData = {
					meshIndex: skinnedMeshIndex,
					vertices: this.dts.meshes[skinnedMeshIndex].vertices.map(x -> new Vector()),
					normals: this.dts.meshes[skinnedMeshIndex].normals.map(x -> new Vector()),
					indices: [],
					geometry: geometry
				}
				var idx = merged.map(x -> x.indices);
				for (i in idx) {
					this.skinMeshData.indices = this.skinMeshData.indices.concat(i);
				}
			}
		}

		if (staticCollision.length > 0) {
			var geometry = this.createGeometryFromMaterialGeometry(this.mergeMaterialGeometries(staticCollision));
			staticGeometries.push(geometry);
			collisionGeometries.push(geometry);
			this.geometries.push(geometry);
		}

		for (materialGeom in dynamicMaterialGeometries) {
			var geometry = this.createGeometryFromMaterialGeometry(materialGeom);
			dynamicGeometries.push(geometry);
			if (collisionMaterialGeometries.contains(materialGeom))
				collisionGeometries.push(geometry);
			this.geometries.push(geometry);
		}

		for (geometry in staticGeometries) {
			this.addChild(geometry);
		}

		for (i in 0...dynamicGeometries.length) {
			var geometry = dynamicGeometries[i];
			dynamicGeometryLookup.set(geometry, this.nodeTransforms.indexOf(dynamicGeometriesMatrices[i]));
			geometry.setTransform(dynamicGeometriesMatrices[i]);
			this.addChild(geometry);
		}
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

			if (fullName == null || (this.isTSStatic && ((flags & (1 << 31) > 0)))) {
				if (this.isTSStatic) {
					// TODO USE PBR???
				}
			} else if (Path.extension(fullName) == "ifl") {
				// TODO IFL SHIT
			} else {
				var texture:Texture = this.fs.load(this.directoryPath + "/" + fullName).toImage().toTexture();
				texture.wrap = Wrap.Repeat;
				material.texture = texture;
				// TODO TRANSLUENCY SHIT
			}
			// TODO TRANSPARENCY SHIT
			if (flags & 8 > 0)
				material.blendMode = BlendMode.Add;
			if (flags & 16 > 0)
				material.blendMode = BlendMode.Sub;

			if (this.isTSStatic && !(flags & 64 > 0)) {
				// TODO THIS SHIT
			}
			// ((flags & 32) || environmentMaterial) ? new Materia

			this.materials.push(material);
		}

		if (this.materials.length == 0) {
			var mat = Material.create();
			this.materials.push(mat);
			// TODO THIS
		}
	}

	function updateNodeTransforms(quaternions:Array<Quat> = null, translations:Array<Vector> = null, bitField = 0xffffffff) {
		if (quaternions == null) {
			quaternions = [];
			for (i in 0...this.dts.nodes.length) {
				var rotation = this.dts.defaultRotations[i];
				var quat = new Quat(rotation.x, rotation.y, rotation.z, rotation.w);
				quat.normalize();
				quat.conjugate();
				quaternions.push(quat);
			}
		}

		if (translations == null) {
			translations = [];
			for (i in 0...this.dts.nodes.length) {
				var translation = this.dts.defaultTranslations[i];
				translations.push(new Vector(translation.x, translation.y, translation.z));
			}
		}

		var utiltyMatrix = new Matrix();

		function traverse(node:GraphNode, needsUpdate:Bool) {
			if (((1 << node.index) & bitField) != 0)
				needsUpdate = true;

			if (needsUpdate) {
				// Recompute the matrix
				var mat = this.nodeTransforms[node.index];

				if (node.parent == null) {
					mat = Matrix.I();
				} else {
					mat = this.nodeTransforms[node.parent.index].clone(); // mat.load(this.nodeTransforms[node.parent.index]);
				}

				var quat = quaternions[node.index];
				var translation = translations[node.index];
				quat.toMatrix(utiltyMatrix);
				utiltyMatrix.scale(1 / utiltyMatrix.getDeterminant());
				utiltyMatrix.setPosition(translation);
				mat.multiply(mat, utiltyMatrix);
				this.nodeTransforms[node.index] = mat;
			}

			for (i in 0...node.children.length)
				traverse(node.children[i], needsUpdate);
		}

		for (i in 0...this.rootGraphNodes.length) {
			var rootNode = this.rootGraphNodes[i];
			traverse(rootNode, false);
		}
	}

	function generateMaterialGeometry(dtsMesh:dts.Mesh, vertices:Array<Vector>, vertexNormals:Array<Vector>) {
		var materialGeometry:Array<MaterialGeometry> = this.materials.map(x -> {
			vertices: [],
			normals: [],
			uvs: [],
			indices: []
		});

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

	public function update(currentTime:Float, dt:Float) {
		for (sequence in this.dts.sequences) {
			if (!this.showSequences)
				break;
			if (!this.hasNonVisualSequences)
				break;

			var rot = sequence.rotationMatters.length > 0 ? sequence.rotationMatters[0] : 0;
			var trans = sequence.translationMatters.length > 0 ? sequence.translationMatters[0] : 0;
			var affectedCount = 0;
			var completion = (currentTime + dt) / sequence.duration;

			var quaternions:Array<Quat> = null;
			var translations:Array<Vector> = null;

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

						var q1 = new Quat(rot1.x, rot1.y, rot1.z, rot1.w);
						q1.normalize();
						q1.conjugate();

						var q2 = new Quat(rot2.x, rot2.y, rot2.z, rot2.w);
						q2.normalize();
						q2.conjugate();

						var quat = new Quat();
						quat.slerp(q1, q2, t);
						quat.normalize();
						affectedCount++;
						quaternions.push(quat);
					} else {
						var rotation = this.dts.defaultRotations[i];
						var quat = new Quat(rotation.x, rotation.y, rotation.z, rotation.w);
						quat.normalize();
						quat.conjugate();

						quaternions.push(quat);
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

						var v1 = new Vector(trans1.x, trans1.y, trans1.z);
						var v2 = new Vector(trans2.x, trans2.y, trans2.z);

						translations.push(Util.lerpThreeVectors(v1, v2, t));
					} else {
						var translation = this.dts.defaultTranslations[i];
						translations.push(new Vector(translation.x, translation.y, translation.z));
					}
				}
			}

			if (rot > 0 || trans > 0) {
				this.updateNodeTransforms(quaternions, translations, rot | trans);
			}
		}

		for (kvp in dynamicGeometryLookup.keyValueIterator()) {
			var tform = this.nodeTransforms[kvp.value];
			kvp.key.setTransform(tform);
		}

		if (this.skinMeshData != null) {
			var info = this.skinMeshData;
			var mesh = this.dts.meshes[info.meshIndex];

			for (i in 0...info.vertices.length) {
				info.vertices[i] = new Vector();
				info.normals[i] = new Vector();
			}

			var boneTransformations = [];
			var boneTransformationsTransposed = [];

			for (i in 0...mesh.nodeIndices.length) {
				var mat = mesh.initialTransforms[i].clone();
				mat.transpose();
				mat.multiply(this.nodeTransforms[mesh.nodeIndices[i]], mat);

				boneTransformations.push(mat);
				var m = mat.clone();
				m.transpose();
				boneTransformationsTransposed.push(m);
			}

			var vec = new Vector();
			var vec2 = new Vector();

			for (i in 0...mesh.vertexIndices.length) {
				var vIndex = mesh.vertexIndices[i];
				var vertex = mesh.vertices[vIndex];
				var normal = mesh.normals[vIndex];

				vec.set(vertex.x, vertex.y, vertex.z);
				vec2.set(normal.x, normal.y, normal.z);
				var mat = boneTransformations[mesh.boneIndices[i]];

				vec.transform(mat);
				vec = vec.multiply(mesh.weights[i]);
				vec2.transform3x3(mat);
				vec2 = vec2.multiply(mesh.weights[i]);

				info.vertices[vIndex] = info.vertices[vIndex].add(vec);
				info.normals[vIndex] = info.normals[vIndex].add(vec2);
			}

			for (i in 0...info.normals.length) {
				var norm = info.normals[i];
				var len2 = norm.lengthSq();

				if (len2 > 0.01)
					norm.normalize();
			}

			var meshIndex = 0;
			var mesh:Mesh = cast info.geometry.children[meshIndex];
			var prim:Polygon = cast mesh.primitive;
			var pos = 0;
			for (i in info.indices) {
				if (pos >= prim.points.length) {
					meshIndex++;
					if (prim.buffer != null)
						prim.buffer.dispose();
					mesh.primitive = prim;
					mesh = cast info.geometry.children[meshIndex];
					prim = cast mesh.primitive;
					pos = 0;
				}
				var vertex = info.vertices[i];
				var normal = info.normals[i];
				prim.points[pos] = vertex.toPoint();
				prim.normals[pos] = normal.toPoint();
				pos++;
			}
			if (prim.buffer != null)
				prim.buffer.dispose();
		}
	}

	public function getMountTransform(mountPoint:Int) {
		// TODO FIX WHEN DTS SUPPORT
		return Matrix.I();
	}
}
