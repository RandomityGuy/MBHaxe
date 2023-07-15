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
import h3d.scene.MeshBatch;
import src.MarbleGame;
import src.ProfilerUI;

typedef MeshBatchInfo = {
	var instances:Array<MeshInstance>;
	var meshbatch:MeshBatch;
	var ?transparencymeshbatch:MeshBatch;
	var mesh:Mesh;
}

typedef MeshInstance = {
	var emptyObj:Object;
	var gameObject:GameObject;
}

class InstanceManager {
	var objects:Array<Array<MeshBatchInfo>> = [];

	var objectMap:Map<String, Int> = [];
	var scene:Scene;

	public function new(scene:Scene) {
		this.scene = scene;
	}

	public function render() {
		var renderFrustums = [scene.camera.frustum];
		// This sucks holy shit
		if (MarbleGame.instance.world != null
			&& MarbleGame.instance.world.marble != null
			&& MarbleGame.instance.world.marble.cubemapRenderer != null)
			renderFrustums = renderFrustums.concat(MarbleGame.instance.world.marble.cubemapRenderer.getCameraFrustums());

		for (meshes in objects) {
			for (minfo in meshes) {
				var visibleinstances = [];
				// Culling
				if (minfo.meshbatch != null || minfo.transparencymeshbatch != null) {
					for (inst in minfo.instances) {
						var objBounds = @:privateAccess cast(minfo.meshbatch.primitive, Instanced).baseBounds.clone();
						objBounds.transform(inst.emptyObj.getAbsPos());
						for (frustum in renderFrustums) {
							if (frustum.hasBounds(objBounds)) {
								visibleinstances.push(inst);
								break;
							}
						}
					}
				}

				// Emit non culled primitives
				if (minfo.meshbatch != null) {
					var opaqueinstances = visibleinstances.filter(x -> x.gameObject.currentOpacity == 1);
					minfo.meshbatch.begin(opaqueinstances.length);
					for (instance in opaqueinstances) { // Draw the opaque shit first
						var dtsShader = minfo.meshbatch.material.mainPass.getShader(DtsTexture);
						var subOpacity = 1.0;
						if (dtsShader != null) {
							if (instance.gameObject.animateSubObjectOpacities) {
								subOpacity = instance.gameObject.getSubObjectOpacity(instance.emptyObj);
								if (subOpacity == 0)
									continue; // Do not draw
								// minfo.meshbatch.shadersChanged = true;
							}

							dtsShader.currentOpacity = instance.gameObject.currentOpacity * subOpacity;
						}
						var transform = instance.emptyObj.getAbsPos();
						minfo.meshbatch.material.mainPass.depthWrite = minfo.mesh.material.mainPass.depthWrite;
						minfo.meshbatch.material.mainPass.depthTest = minfo.mesh.material.mainPass.depthTest;
						// minfo.meshbatch.shadersChanged = true;
						minfo.meshbatch.material.mainPass.setPassName(minfo.mesh.material.mainPass.name);
						minfo.meshbatch.material.mainPass.enableLights = minfo.mesh.material.mainPass.enableLights;
						minfo.meshbatch.worldPosition = transform;
						minfo.meshbatch.material.mainPass.culling = minfo.mesh.material.mainPass.culling;

						minfo.meshbatch.material.mainPass.blendSrc = minfo.mesh.material.mainPass.blendSrc;
						minfo.meshbatch.material.mainPass.blendDst = minfo.mesh.material.mainPass.blendDst;
						minfo.meshbatch.material.mainPass.blendOp = minfo.mesh.material.mainPass.blendOp;
						minfo.meshbatch.material.mainPass.blendAlphaSrc = minfo.mesh.material.mainPass.blendAlphaSrc;
						minfo.meshbatch.material.mainPass.blendAlphaDst = minfo.mesh.material.mainPass.blendAlphaDst;
						minfo.meshbatch.material.mainPass.blendAlphaOp = minfo.mesh.material.mainPass.blendAlphaOp;

						// handle the glow pass too
						var glowPass = minfo.meshbatch.material.getPass("glow");
						if (glowPass != null) {
							dtsShader = glowPass.getShader(DtsTexture);
							if (dtsShader != null)
								dtsShader.currentOpacity = instance.gameObject.currentOpacity * subOpacity;
						}

						minfo.meshbatch.emitInstance();
					}
				}
				if (minfo.transparencymeshbatch != null) {
					var transparentinstances = visibleinstances.filter(x -> x.gameObject.currentOpacity != 1 && x.gameObject.currentOpacity != 0); // Filter out all zero opacity things too
					minfo.transparencymeshbatch.begin(transparentinstances.length);
					for (instance in transparentinstances) { // Non opaque shit
						var dtsShader = minfo.transparencymeshbatch.material.mainPass.getShader(DtsTexture);
						if (dtsShader != null) {
							dtsShader.currentOpacity = instance.gameObject.currentOpacity;
						}
						minfo.transparencymeshbatch.material.blendMode = Alpha;
						// minfo.transparencymeshbatch.material.color.a = instance.gameObject.currentOpacity;
						// minfo.transparencymeshbatch.material.mainPass.setPassName(minfo.mesh.material.mainPass.name);
						minfo.transparencymeshbatch.shadersChanged = true;
						minfo.transparencymeshbatch.material.mainPass.enableLights = minfo.mesh.material.mainPass.enableLights;
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
				minfos[i].instances.push({emptyObj: objs[i], gameObject: object});
			}
		} else {
			// First time appending the thing so bruh
			var infos = [];
			var objs = getAllChildren(object);
			var minfos = [];
			for (obj in objs) {
				var isMesh = obj is Mesh;
				var minfo:MeshBatchInfo = {
					instances: [{emptyObj: obj, gameObject: object}],
					meshbatch: isMesh ? new MeshBatch(cast(cast(obj, Mesh).primitive), cast(cast(obj, Mesh)).material.clone(), scene) : null,
					mesh: isMesh ? cast obj : null
				}
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
