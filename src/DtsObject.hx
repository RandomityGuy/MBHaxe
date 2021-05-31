import h3d.Matrix;
import h3d.scene.CustomObject;

class DtsObject extends CustomObject {
	public function getMountTransform(mountPoint:Int) {
		// TODO FIX WHEN DTS SUPPORT
		return Matrix.I();
	}
}
