package src;

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
import src.MeshBatch;
import src.MarbleGame;
import src.ProfilerUI;
import src.Settings;

@:publicFields
class MeshBatchInfo {
	var instances:Array<MeshInstance>;
	var meshbatch:MeshBatch;
	var transparencymeshbatch:MeshBatch;
	var mesh:Mesh;
	var dtsShader:DtsTexture;
	var glowPassDtsShader:DtsTexture;
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

	public inline function get(i:Int):T {
		return array[i];
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
			&& Settings.optionsSettings.reflectionDetail >= 3
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
					var mb = minfo.meshbatch;
					var mbPass = mb.material.mainPass;
					var srcPass = minfo.mesh.material.mainPass;
					mb.begin(opaqueinstances.length);

					// Per-batch state: invariant across instances (the batch draws with one shared
					// material), so set it once instead of rewriting these ~13 pass properties plus a
					// setPassName + getPass("glow") on every single instance.
					mbPass.depthWrite = srcPass.depthWrite;
					mbPass.depthTest = srcPass.depthTest;
					mbPass.setPassName(srcPass.name);
					mbPass.enableLights = srcPass.enableLights;
					mbPass.culling = srcPass.culling;
					mbPass.blendSrc = srcPass.blendSrc;
					mbPass.blendDst = srcPass.blendDst;
					mbPass.blendOp = srcPass.blendOp;
					mbPass.blendAlphaSrc = srcPass.blendAlphaSrc;
					mbPass.blendAlphaDst = srcPass.blendAlphaDst;
					mbPass.blendAlphaOp = srcPass.blendAlphaOp;

					var dtsShader = minfo.dtsShader;
					var glowDtsShader = mb.material.getPass("glow") != null ? minfo.glowPassDtsShader : null;

					for (i in 0...opaqueinstances.length) { // Draw the opaque shit first
						var instance = opaqueinstances.get(i);
						var subOpacity = 1.0;
						if (dtsShader != null) {
							if (instance.gameObject.animateSubObjectOpacities) {
								subOpacity = instance.gameObject.getSubObjectOpacity(instance.emptyObj);
								if (subOpacity == 0)
									continue; // Do not draw
							}
							dtsShader.currentOpacity = instance.gameObject.currentOpacity * subOpacity;
						}
						// handle the glow pass too
						if (glowDtsShader != null)
							glowDtsShader.currentOpacity = instance.gameObject.currentOpacity * subOpacity;
						mb.worldPosition = instance.emptyObj.getAbsPos();
						mb.emitInstance();
					}
				}
				if (minfo.transparencymeshbatch != null) {
					var tmb = minfo.transparencymeshbatch;
					tmb.begin(transparentinstances.length);
					// Invariant per-batch state, set once (was redundantly re-set every instance).
					tmb.material.blendMode = Alpha;
					tmb.material.mainPass.enableLights = minfo.mesh.material.mainPass.enableLights;
					var dtsShader = minfo.dtsShader;
					for (i in 0...transparentinstances.length) { // Non opaque shit
						var instance = transparentinstances.get(i);
						if (dtsShader != null)
							dtsShader.currentOpacity = instance.gameObject.currentOpacity;
						tmb.worldPosition = instance.emptyObj.getAbsPos();
						tmb.emitInstance();
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
				var isMesh = obj is Mesh;
				var minfo:MeshBatchInfo = new MeshBatchInfo();
				minfo.instances = [new MeshInstance(obj, object)];
				minfo.meshbatch = isMesh ? new MeshBatch(cast(cast(obj, Mesh).primitive), cast(cast(obj, Mesh)).material.clone(), scene) : null;
				minfo.mesh = isMesh ? cast obj : null;
				minfo.baseBounds = isMesh ? @:privateAccess cast(minfo.meshbatch.primitive, Instanced).baseBounds : null;

				if (isMesh) {
					var mat = cast(obj, Mesh).material;
					var minfoshaders = [];
					for (shader in minfo.meshbatch.material.mainPass.getShaders()) {
						minfoshaders.push(shader);
					}
					for (shader in minfoshaders)
						minfo.meshbatch.material.mainPass.removeShader(shader);
					var addshaders = [];
					for (shader in mat.mainPass.getShaders()) {
						addshaders.push(shader);
					}
					for (shader in addshaders)
						minfo.meshbatch.material.mainPass.addShader(shader);
					var glowPass = mat.getPass("glow");
					if (glowPass != null) {
						var gpass = glowPass.clone();
						gpass.enableLights = false;
						gpass.depthTest = glowPass.depthTest;
						gpass.blendSrc = glowPass.blendSrc;
						gpass.blendDst = glowPass.blendDst;
						gpass.blendOp = glowPass.blendOp;
						gpass.blendAlphaSrc = glowPass.blendAlphaSrc;
						gpass.blendAlphaDst = glowPass.blendAlphaDst;
						gpass.blendAlphaOp = glowPass.blendAlphaOp;
						if (glowPass.culling == None) {
							gpass.culling = glowPass.culling;
						}

						minfoshaders = [];

						for (shader in gpass.getShaders()) {
							minfoshaders.push(shader);
						}
						for (shader in minfoshaders)
							gpass.removeShader(shader);
						var addshaders = [];
						for (shader in glowPass.getShaders()) {
							addshaders.push(shader);
						}
						for (shader in addshaders)
							gpass.addShader(shader);

						minfo.glowPassDtsShader = gpass.getShader(DtsTexture);

						minfo.meshbatch.material.addPass(gpass);
					}
					var refractPass = mat.getPass("refract");
					if (refractPass != null) {
						var gpass = refractPass.clone();
						gpass.enableLights = false;
						gpass.depthTest = refractPass.depthTest;
						gpass.blendSrc = refractPass.blendSrc;
						gpass.blendDst = refractPass.blendDst;
						gpass.blendOp = refractPass.blendOp;
						gpass.blendAlphaSrc = refractPass.blendAlphaSrc;
						gpass.blendAlphaDst = refractPass.blendAlphaDst;
						gpass.blendAlphaOp = refractPass.blendAlphaOp;
						if (refractPass.culling == None) {
							gpass.culling = refractPass.culling;
						}

						minfoshaders = [];

						for (shader in gpass.getShaders()) {
							minfoshaders.push(shader);
						}
						for (shader in minfoshaders)
							gpass.removeShader(shader);
						var addshaders = [];
						for (shader in refractPass.getShaders()) {
							addshaders.push(shader);
						}
						for (shader in addshaders)
							gpass.addShader(shader);

						minfo.meshbatch.material.addPass(gpass);
					}
					var zPass = mat.getPass("zPass");
					if (zPass != null) {
						var gpass = zPass.clone();
						gpass.enableLights = false;
						gpass.depthTest = zPass.depthTest;
						gpass.blendSrc = zPass.blendSrc;
						gpass.blendDst = zPass.blendDst;
						gpass.blendOp = zPass.blendOp;
						gpass.blendAlphaSrc = zPass.blendAlphaSrc;
						gpass.blendAlphaDst = zPass.blendAlphaDst;
						gpass.blendAlphaOp = zPass.blendAlphaOp;
						gpass.colorMask = zPass.colorMask;
						minfoshaders = [];

						for (shader in gpass.getShaders()) {
							minfoshaders.push(shader);
						}
						for (shader in minfoshaders)
							gpass.removeShader(shader);
						var addshaders = [];
						for (shader in zPass.getShaders()) {
							addshaders.push(shader);
						}
						for (shader in addshaders)
							gpass.addShader(shader);

						minfo.meshbatch.material.addPass(gpass);
					}
					minfo.dtsShader = minfo.meshbatch.material.mainPass.getShader(DtsTexture);
					// var dtsshader = mat.mainPass.getShader(DtsTexture);
					// if (dtsshader != null) {
					// 	minfo.meshbatch.material.mainPass.removeShader(minfo.meshbatch.material.textureShader);
					// 	minfo.meshbatch.material.mainPass.addShader(dtsshader);
					// 	minfo.meshbatch.material.mainPass.culling = mat.mainPass.culling;
					// 	minfo.meshbatch.material.mainPass.depthWrite = mat.mainPass.depthWrite;
					// }
					// var phongshader = mat.mainPass.getShader(PhongMaterial);
					// if (phongshader != null) {
					// 	minfo.meshbatch.material.mainPass.removeShader(minfo.meshbatch.material.textureShader);
					// 	minfo.meshbatch.material.mainPass.addShader(phongshader);
					// 	// minfo.meshbatch.material.mainPass.culling = mat.mainPass.culling;
					// }
					// var noiseshder = mat.mainPass.getShader(NoiseTileMaterial);
					// if (noiseshder != null) {
					// 	minfo.meshbatch.material.mainPass.removeShader(minfo.meshbatch.material.textureShader);
					// 	minfo.meshbatch.material.mainPass.addShader(noiseshder);
					// 	// minfo.meshbatch.material.mainPass.culling = mat.mainPass.culling;
					// }
					// var nmapshdr = mat.mainPass.getShader(NormalMaterial);
					// if (nmapshdr != null) {
					// 	minfo.meshbatch.material.mainPass.removeShader(minfo.meshbatch.material.textureShader);
					// 	minfo.meshbatch.material.mainPass.addShader(nmapshdr);
					// 	// minfo.meshbatch.material.mainPass.culling = mat.mainPass.culling;
					// }
					// var cubemapshdr = mat.mainPass.getShader(EnvMap);
					// if (cubemapshdr != null) {
					// 	minfo.meshbatch.material.mainPass.addShader(cubemapshdr);
					// }
					minfo.transparencymeshbatch = new MeshBatch(cast(cast(obj, Mesh).primitive), cast(cast(obj, Mesh)).material.clone(), scene);
					minfoshaders = [];
					for (shader in minfo.transparencymeshbatch.material.mainPass.getShaders()) {
						minfoshaders.push(shader);
					}
					for (shader in minfoshaders)
						minfo.transparencymeshbatch.material.mainPass.removeShader(shader);
					minfo.transparencymeshbatch.material.mainPass.removeShader(minfo.meshbatch.material.textureShader);
					for (shader in mat.mainPass.getShaders()) {
						minfo.transparencymeshbatch.material.mainPass.addShader(shader);
					}
					// minfo.transparencymeshbatch.material.mainPass.culling = mat.mainPass.culling;

					// minfo.meshbatch.material.mainPass.removeShader(minfo.meshbatch.material.mainPass.getShader(PropsValues));
					// minfo.transparencymeshbatch.material.mainPass.removeShader(minfo.transparencymeshbatch.material.mainPass.getShader(PropsValues));

					// var pbrshader = mat.mainPass.getShader(PropsValues);
					// if (pbrshader != null) {
					// 	minfo.meshbatch.material.mainPass.addShader(pbrshader);
					// 	minfo.transparencymeshbatch.material.mainPass.addShader(pbrshader);
					// }
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
