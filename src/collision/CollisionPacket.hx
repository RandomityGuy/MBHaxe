package collision;

import h3d.Vector;

@:publicFields
class CollisionPacket {
	static var LARGE_NUMBER:Float = 1e20;

	/** Position in world space. Assumes Z-up. **/
	var r3_position = new Vector(0.0, 0.0, 0.0);

	/** Velocity in world space. Assumes Z-up. **/
	var r3_velocity = new Vector(0.0, 0.0, 0.0);

	/** Ellipsoid radius in world units. Assumes Z-up. **/
	var e_radius = new Vector(1.0, 1.0, 1.0);

	/** Position in ellipsoid-space. Used internally. **/
	var e_position = new Vector(0.0, 0.0, 0.0);

	/** Velocity in ellipsoid-space. Used internally. **/
	var e_velocity = new Vector(0.0, 0.0, 0.0);

	/** Found a collision. **/
	var found_collision = false;

	/** Distance to nearest collision if `found_collision` is set, otherwise `1e20` **/
	var nearest_distance = LARGE_NUMBER;

	/** Iteration depth. Useful for debugging slow collisions. **/
	var depth:Int = 0;

	// internal stuff
	var e_norm_velocity = new Vector(0.0, 0.0, 0.0);
	var e_base_point = new Vector(0.0, 0.0, 0.0);
	var intersect_point = new Vector(0.0, 0.0, 0.0);

	/** `true` if packet is on something reasonable to call the ground.
	 *
	 * _in practice, you probably want a sensor in your game code instead._ **/
	var grounded:Bool = false;

	/** Recalculate e-space from r3 vectors. Call this if you updated `r3_*` **/
	inline function to_e() {
		this.e_position = new Vector(this.r3_position.x / this.e_radius.x, this.r3_position.y / this.e_radius.y, this.r3_position.z / this.e_radius.z);
		this.e_velocity = new Vector(this.r3_velocity.x / this.e_radius.x, this.r3_velocity.y / this.e_radius.y, this.r3_velocity.z / this.e_radius.z);
	}

	/** Recalculate e-space from r3 vectors. Call this if you updated `e_*` **/
	inline function to_r3() {
		this.r3_position = new Vector(this.e_position.x * this.e_radius.x, this.e_position.y * this.e_radius.y, this.e_position.z * this.e_radius.z);
		this.r3_velocity = new Vector(this.e_velocity.x * this.e_radius.x, this.e_velocity.y * this.e_radius.y, this.e_velocity.z * this.e_radius.z);
	}

	inline function new(?position:Vector, ?velocity:Vector, ?radius:Vector) {
		if (position != null) {
			this.r3_position = position;
		}
		if (velocity != null) {
			this.r3_velocity = velocity;
		}
		if (radius != null) {
			this.e_radius = radius;
		}
		this.to_e();
	}
}
