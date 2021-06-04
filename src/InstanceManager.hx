package src;

import h2d.col.Matrix;
import src.GameObject;
import h3d.scene.Scene;
import h3d.scene.Object;
import h3d.scene.Mesh;
import h3d.scene.MeshBatch;

typedef MeshBatchInfo = {
	var instances:Array<Object>;
	var meshbatch:MeshBatch;
	var mesh:Mesh;
}

class InstanceManager {
	var objects:Map<String, Array<MeshBatchInfo>> = new Map();
	var scene:Scene;

	public function new(scene:Scene) {
		this.scene = scene;
	}

	public function update(dt:Float) {
		for (obj => meshes in objects) {
			for (minfo in meshes) {
				if (minfo.meshbatch != null) {
					minfo.meshbatch.begin(minfo.instances.length);
					for (instance in minfo.instances) {
						var transform = instance.getAbsPos().clone();
						minfo.meshbatch.setTransform(transform);
						minfo.meshbatch.emitInstance();
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
			var minfos = objects.get(object.identifier);
			for (i in 0...objs.length) {
				minfos[i].instances.push(objs[i]);
			}
		} else {
			// First time appending the thing so bruh
			var infos = [];
			var objs = getAllChildren(object);
			var minfos = [];
			for (obj in objs) {
				var isMesh = obj is Mesh;
				var minfo:MeshBatchInfo = {
					instances: [obj],
					meshbatch: isMesh ? new MeshBatch(cast(cast(obj, Mesh).primitive), cast(cast(obj, Mesh)).material.clone(), scene) : null,
					mesh: isMesh ? cast obj : null
				}
				minfos.push(minfo);
			}
			objects.set(object.identifier, minfos);
		}
	}

	public function isInstanced(object:GameObject) {
		if (objects.exists(object.identifier))
			return true;
		return false;
	}
}
