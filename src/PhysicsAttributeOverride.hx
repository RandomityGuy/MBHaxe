package src;

/** One `attribute`/`value` override within a pushed physics layer - see
	`Marble.pushPhysicsLayer`/`popPhysicsLayer`, ported from PQ's `Physics::pushLayer` attribute
	records (`client/scripts/physics.cs`). */
@:structInit
class PhysicsAttributeOverride {
	public var attribute:String;
	public var value:Float;
}
