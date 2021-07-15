package collision.gjk;

import h3d.Vector;

interface GJKShape {
	function getCenter():Vector;
	function support(dir:Vector):Vector;
}
