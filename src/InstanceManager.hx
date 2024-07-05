package src;

import h3d.mat.Material;
import h3d.scene.MultiMaterial;
import shaders.EnvMap;
import h3d.shader.CubeMap;
import shaders.NormalMaterial;
import shaders.NoiseTileMaterial;
import shaders.PhongMaterial;
import h3d.prim.Instanced;
import h3d.shader.pbr.PropsValues;
import shaders.Billboard;
import shaders.DtsTexture;
import h3d.mat.Pass;
import h3d.shader.AlphaMult;
import h2d.col.Matrix;
import src.GameObject;
import h3d.scene.Scene;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.scene.MeshBatch;
import src.MarbleGame;

@:publicFields
class MeshBatchInfo {
	var instances:Array<MeshInstance>;
	var meshbatch:MeshBatch;
	var transparencymeshbatch:MeshBatch;
	var mesh:Mesh;
	var dtsShader:DtsTexture;
	var baseBounds:h3d.col.Bounds;

	public function new() {}
}

@:publicFields
class MeshInstance {
	var emptyObj:Object;
	var gameObject:GameObject;

	public function new(eo, go) {
		this.emptyObj = eo;
		this.gameObject = go;
	}
}

@:generic
class ReusableListIterator<T> {
	var l:ReusableList<T>;
	var i = 0;

	public function new(l:ReusableList<T>) {
		this.l = l;
	}

	public inline function hasNext() {
		return i != l.length;
	}

	public inline function next() {
		var ret = @:privateAccess l.array[i];
		i += 1;
		return ret;
	}
}

@:allow(ReusableListIterator)
@:generic
class ReusableList<T> {
	var array:Array<T>;

	public var length:Int = 0;

	public inline function new() {
		array = [];
	}

	public inline function push(item:T) {
		if (array.length == length) {
			array.push(item);
			length += 1;
		} else {
			array[length] = item;
			length += 1;
		}
	}

	public inline function clear() {
		length = 0;
	}

	public inline function iterator():ReusableListIterator<T> {
		return new ReusableListIterator<T>(this);
	}
}

class InstanceManager {
	var objects:Array<Array<MeshBatchInfo>> = [];

	var objectMap:Map<String, Int> = [];
	var scene:Scene;
	var opaqueinstances = new ReusableList<MeshInstance>();
	var transparentinstances = new ReusableList<MeshInstance>();

	public function new(scene:Scene) {
		this.scene = scene;
	}

	public function render() {
		static var tmpBounds = new h3d.col.Bounds();
		var renderFrustum = scene.camera.frustum;
		var doFrustumCheck = true;
		// This sucks holy shit
		doFrustumCheck = MarbleGame.instance.world != null
			&& MarbleGame.instance.world.marble.cubemapRenderer != null
			&& @:privateAccess !MarbleGame.instance.world.marble.camera.spectate;
		var cameraFrustrums = doFrustumCheck ? MarbleGame.instance.world.marble.cubemapRenderer.getCameraFrustums() : null;

		for (meshes in objects) {
			for (minfo in meshes) {
				opaqueinstances.clear();
				transparentinstances.clear();
				// Culling
				if (minfo.meshbatch != null || minfo.transparencymeshbatch != null) {
					for (inst in minfo.instances) {
						// for (frustum in renderFrustums) {
						//	if (frustum.hasBounds(objBounds)) {

						tmpBounds.load(minfo.baseBounds);
						tmpBounds.transform(inst.emptyObj.getAbsPos());

						if (cameraFrustrums == null && !renderFrustum.hasBounds(tmpBounds))
							continue;

						if (cameraFrustrums != null) {
							var found = false;
							for (frustrum in cameraFrustrums) {
								if (frustrum.hasBounds(tmpBounds)) {
									found = true;
									break;
								}
							}
							if (!found)
								continue;
						}

						if (inst.gameObject.currentOpacity == 1)
							opaqueinstances.push(inst);
						else if (inst.gameObject.currentOpacity != 0)
							transparentinstances.push(inst);
						// break;
						//	}
						// }
					}
				}

				// Emit non culled primitives
				if (minfo.meshbatch != null) {
					minfo.meshbatch.begin(opaqueinstances.length);
					for (instance in opaqueinstances) { // Draw the opaque shit first
						var dtsShader = minfo.dtsShader;
						if (dtsShader != null) {
							dtsShader.currentOpacity = instance.gameObject.currentOpacity;
						}
						var transform = instance.emptyObj.getAbsPos();
						// minfo.meshbatch.shadersChanged = true;
						// minfo.meshbatch.material.mainPass.setPassName(minfo.mesh.material.mainPass.name);
						// minfo.meshbatch.material.mainPass.enableLights = minfo.mesh.material.mainPass.enableLights;
						minfo.meshbatch.worldPosition = transform;
						minfo.meshbatch.emitInstance();
					}
				}
				if (minfo.transparencymeshbatch != null) {
					minfo.transparencymeshbatch.begin(transparentinstances.length);
					for (instance in transparentinstances) { // Non opaque shit
						var dtsShader = minfo.dtsShader;
						if (dtsShader != null) {
							dtsShader.currentOpacity = instance.gameObject.currentOpacity;
						}
						// minfo.transparencymeshbatch.material.blendMode = Alpha;
						// minfo.transparencymeshbatch.material.color.a = instance.gameObject.currentOpacity;
						// minfo.transparencymeshbatch.material.mainPass.setPassName(minfo.mesh.material.mainPass.name);
						// minfo.transparencymeshbatch.shadersChanged = true;
						// minfo.transparencymeshbatch.material.mainPass.enableLights = minfo.mesh.material.mainPass.enableLights;
						// minfo.transparencymeshbatch.material.mainPass.depthWrite = false;
						// if (dtsShader != null) {
						// 	dtsShader.currentOpacity = instance.gameObject.currentOpacity;
						// 	minfo.transparencymeshbatch.shadersChanged = true;
						// }
						var transform = instance.emptyObj.getAbsPos();
						minfo.transparencymeshbatch.worldPosition = transform;
						minfo.transparencymeshbatch.emitInstance();
					}
				}
			}
		}
	}

	public function addObject(object:GameObject) {
		function getAllChildren(object:Object):Array<Object> {
			var ret = [object];
			for (i in 0...object.numChildren) {
				ret = ret.concat(getAllChildren(object.getChildAt(i)));
			}
			return ret;
		}

		if (isInstanced(object)) {
			// Add existing instance
			var objs = getAllChildren(object);
			var minfos = objects[objectMap.get(object.identifier)]; // objects.get(object.identifier);
			for (i in 0...objs.length) {
				minfos[i].instances.push(new MeshInstance(objs[i], object));
			}
		} else {
			// First time appending the thing so bruh
			var infos = [];
			var objs = getAllChildren(object);
			var minfos = [];
			for (obj in objs) {
				var isMesh = obj is MultiMaterial;
				var minfo:MeshBatchInfo = new MeshBatchInfo();
				minfo.instances = [new MeshInstance(obj, object)];
				minfo.meshbatch = isMesh ? new MeshBatch(cast(cast(obj, MultiMaterial).primitive), null, scene) : null;
				minfo.mesh = isMesh ? cast obj : null;
				minfo.baseBounds = isMesh ? @:privateAccess cast(minfo.meshbatch.primitive, Instanced).baseBounds : null;

				if (isMesh) {
					minfo.transparencymeshbatch = new MeshBatch(cast(cast(obj, MultiMaterial).primitive), null, scene);
					minfo.transparencymeshbatch.materials = [];
					minfo.meshbatch.materials = [];
					for (mat in cast(obj, MultiMaterial).materials) {
						var matclone:Material = cast mat.clone();
						var dtsshader = mat.mainPass.getShader(DtsTexture);
						if (dtsshader != null) {
							matclone.mainPass.removeShader(matclone.textureShader);
							matclone.mainPass.addShader(dtsshader);
							matclone.mainPass.culling = mat.mainPass.culling;
							matclone.mainPass.depthWrite = mat.mainPass.depthWrite;
							matclone.mainPass.blendSrc = mat.mainPass.blendSrc;
							matclone.mainPass.blendDst = mat.mainPass.blendDst;
							matclone.mainPass.blendOp = mat.mainPass.blendOp;
							matclone.mainPass.blendAlphaSrc = mat.mainPass.blendAlphaSrc;
							matclone.mainPass.blendAlphaDst = mat.mainPass.blendAlphaDst;
							matclone.mainPass.blendAlphaOp = mat.mainPass.blendAlphaOp;
							minfo.dtsShader = dtsshader;
						}
						var phongshader = mat.mainPass.getShader(PhongMaterial);
						if (phongshader != null) {
							matclone.mainPass.removeShader(matclone.textureShader);
							matclone.mainPass.addShader(phongshader);
							// minfo.meshbatch.material.mainPass.culling = mat.mainPass.culling;
						}
						var noiseshder = mat.mainPass.getShader(NoiseTileMaterial);
						if (noiseshder != null) {
							matclone.mainPass.removeShader(matclone.textureShader);
							matclone.mainPass.addShader(noiseshder);
							// minfo.meshbatch.material.mainPass.culling = mat.mainPass.culling;
						}
						var nmapshdr = mat.mainPass.getShader(NormalMaterial);
						if (nmapshdr != null) {
							matclone.mainPass.removeShader(matclone.textureShader);
							matclone.mainPass.addShader(nmapshdr);
							// minfo.meshbatch.material.mainPass.culling = mat.mainPass.culling;
						}
						var cubemapshdr = mat.mainPass.getShader(EnvMap);
						if (cubemapshdr != null) {
							matclone.mainPass.addShader(cubemapshdr);
						}
						matclone.mainPass.enableLights = mat.mainPass.enableLights;
						matclone.mainPass.setPassName(mat.mainPass.name);

						for (p in matclone.getPasses())
							@:privateAccess p.batchMode = true;
						minfo.meshbatch.materials.push(matclone);

						var matclonetransp:Material = cast mat.clone();

						matclonetransp.mainPass.removeShader(minfo.meshbatch.material.textureShader);
						matclonetransp.mainPass.addShader(dtsshader);

						matclonetransp.blendMode = Alpha;

						matclonetransp.mainPass.culling = mat.mainPass.culling;
						matclonetransp.mainPass.depthWrite = mat.mainPass.depthWrite;
						if (mat.blendMode == Alpha) {
							matclonetransp.mainPass.blendSrc = mat.mainPass.blendSrc;
							matclonetransp.mainPass.blendDst = mat.mainPass.blendDst;
							matclonetransp.mainPass.blendOp = mat.mainPass.blendOp;
							matclonetransp.mainPass.blendAlphaSrc = mat.mainPass.blendAlphaSrc;
							matclonetransp.mainPass.blendAlphaDst = mat.mainPass.blendAlphaDst;
							matclonetransp.mainPass.blendAlphaOp = mat.mainPass.blendAlphaOp;
							matclonetransp.mainPass.enableLights = mat.mainPass.enableLights;
							matclonetransp.receiveShadows = mat.receiveShadows;
						}

						matclonetransp.mainPass.enableLights = mat.mainPass.enableLights;

						for (p in matclonetransp.getPasses())
							@:privateAccess p.batchMode = true;
						minfo.transparencymeshbatch.materials.push(matclonetransp);
						// minfo.transparencymeshbatch.material.mainPass.culling = mat.mainPass.culling;

						// minfo.meshbatch.material.mainPass.removeShader(minfo.meshbatch.material.mainPass.getShader(PropsValues));
						// minfo.transparencymeshbatch.material.mainPass.removeShader(minfo.transparencymeshbatch.material.mainPass.getShader(PropsValues));

						// var pbrshader = mat.mainPass.getShader(PropsValues);
						// if (pbrshader != null) {
						// 	minfo.meshbatch.material.mainPass.addShader(pbrshader);
						// 	minfo.transparencymeshbatch.material.mainPass.addShader(pbrshader);
						// }
					}
				}
				minfos.push(minfo);
			}
			var curidx = objects.length;
			objects.push(minfos);
			objectMap.set(object.identifier, curidx);
		}
	}

	public function getObjectBounds(object:GameObject) {
		if (isInstanced(object)) {
			var minfos = objects[objectMap.get(object.identifier)];
			var invmat = minfos[0].instances[0].gameObject.getInvPos();
			var b = minfos[0].instances[0].gameObject.getBounds().clone();
			b.transform(invmat);
			return b;
		} else {
			var invmat = object.getInvPos();
			var b = object.getBounds().clone();
			b.transform(invmat);
			return b;
		}
	}

	public function isInstanced(object:GameObject) {
		if (objectMap.exists(object.identifier))
			return true;
		return false;
	}
}
