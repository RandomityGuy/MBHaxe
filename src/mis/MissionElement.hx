package mis;

enum MissionElementType {
	SimGroup;
	ScriptObject;
	MissionArea;
	Sky;
	Sun;
	InteriorInstance;
	StaticShape;
	Item;
	Path;
	Marker;
	PathedInterior;
	Trigger;
	AudioProfile;
	MessageVector;
	TSStatic;
	ParticleEmitterNode;
}

@:publicFields
class MissionElementBase {
	// Underscore prefix to avoid name clashes

	/** The general type of the element. */
	var _type:MissionElementType; /** The object name; specified in the () of the "constructor". */

	var _name:String;

	/** Is unique for every element in the mission file. */
	var _id:Int;

	var fields:Map<String, Array<String>>;
}

@:publicFields
class MissionElementSimGroup extends MissionElementBase {
	var elements:Array<MissionElementBase>;

	public function new() {
		_type = MissionElementType.SimGroup;
	}
}

@:publicFields
/** Stores metadata about the mission. */
class MissionElementScriptObject extends MissionElementBase {
	var time:String;
	var name:String;
	var desc:String;
	var type:String;
	var starthelptext:String;
	var level:String;
	var artist:String;
	var goldtime:String;
	var ultimatetime:String;
	var music:String;
	var alarmstarttime:String;
	var game:String;
	var gamemode:String;
	var maxgemsperspawn:String;
	var radiusfromgem:String;
	var spawnblock:String;
	var overviewwidth:String;
	var overviewheight:String;
	var spawnchancered:String;
	var spawnchanceyellow:String;
	var spawnchanceblue:String;
	var spawnchanceplatinum:String;

	public function new() {
		_type = MissionElementType.ScriptObject;
	}
}

@:publicFields
class MissionElementMissionArea extends MissionElementBase {
	var area:String;
	var flightceiling:String;
	var flightceilingRange:String;
	var locked:String;

	public function new() {
		_type = MissionElementType.MissionArea;
	}
}

@:publicFields
class MissionElementSky extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var cloudheightper0:String;
	var cloudheightper1:String;
	var cloudheightper2:String;
	var cloudspeed1:String;
	var cloudspeed2:String;
	var cloudspeed3:String;
	var visibledistance:String;
	var useskytextures:String;
	var renderbottomtexture:String;
	var skysolidcolor:String;
	var fogdistance:String;
	var fogcolor:String;
	var fogvolume1:String;
	var fogvolume2:String;
	var fogvolume3:String;
	var materiallist:String;
	var windvelocity:String;
	var windeffectprecipitation:String;
	var norenderbans:String;
	var fogvolumecolor1:String;
	var fogvolumecolor2:String;
	var fogvolumecolor3:String;

	public function new() {
		_type = MissionElementType.Sky;
	}
}

@:publicFields
/** Stores information about the lighting direction and color. */
class MissionElementSun extends MissionElementBase {
	var direction:String;
	var color:String;
	var ambient:String;

	public function new() {
		_type = MissionElementType.Sun;
	}
}

@:publicFields
/** Represents a static (non-moving) interior instance. */
class MissionElementInteriorInstance extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var interiorfile:String;
	var showterraininside:String;

	public function new() {
		_type = MissionElementType.InteriorInstance;
	}
}

@:publicFields
/** Represents a static shape. */
class MissionElementStaticShape extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var datablock:String;
	var resettime:Null<String>;
	var timeout:Null<String>;

	public function new() {
		_type = MissionElementType.StaticShape;
	}
}

@:publicFields
/** Represents an item. */
class MissionElementItem extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var datablock:String;
	var collideable:String;
	var isStatic:String;
	var rotate:String;
	var showhelponpickup:String;
	var timebonus:Null<String>;
	var timepenalty:Null<String>;

	public function new() {
		_type = MissionElementType.Item;
	}
}

@:publicFields
/** Holds the markers used for the path of a pathed interior. */
class MissionElementPath extends MissionElementBase {
	var markers:Array<MissionElementMarker>;

	public function new() {
		_type = MissionElementType.Path;
	}
}

@:publicFields
/** One keyframe in a pathed interior path. */
class MissionElementMarker extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var seqnum:String;
	var mstonext:String;

	/** Either Linear; Accelerate or Spline. */
	var smoothingtype:String;

	public function new() {
		_type = MissionElementType.Marker;
	}
}

@:publicFields
/** Represents a moving interior. */
class MissionElementPathedInterior extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var datablock:String;
	var interiorresource:String;
	var interiorindex:String;
	var baseposition:String;
	var baserotation:String;
	var basescale:String;
	// These two following values are a bit weird. See usage for more explanation.
	var initialtargetposition:String;
	var initialposition:String;

	public function new() {
		_type = MissionElementType.PathedInterior;
	}
}

@:publicFields
/** Represents a trigger area used for out-of-bounds and help. */
class MissionElementTrigger extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var datablock:String;

	/** A list of 12 Strings representing 4 vectors. The first vector corresponds to the origin point of the cuboid; the other three are the side vectors. */
	var polyhedron:String;

	var text:Null<String>;
	var targettime:Null<String>;
	var instant:Null<String>;
	var icontinuetottime:Null<String>;

	// checkpoint stuff:
	var respawnpoint:Null<String>;
	var add:Null<String>;
	var sub:Null<String>;
	var gravity:Null<String>;
	var disableOob:Null<String>;
	// teleport/destination trigger stuff:
	var destination:Null<String>;
	var delay:Null<String>;
	var centerdestpoint:Null<String>;
	var keepvelocity:Null<String>;
	var inversevelocity:Null<String>;
	var keepangular:Null<String>;
	var keepcamera:Null<String>;
	var camerayaw:Null<String>;
	var g:Null<String>;

	public function new() {
		_type = MissionElementType.Trigger;
	}
}

@:publicFields
/** Represents the song choice. */
class MissionElementAudioProfile extends MissionElementBase {
	var filename:String;
	var description:String;
	var preload:String;

	public function new() {
		_type = MissionElementType.AudioProfile;
	}
}

@:publicFields
class MissionElementMessageVector extends MissionElementBase {
	public function new() {
		_type = MissionElementType.MessageVector;
	}
}

@:publicFields
/** Represents a static; unmoving; unanimated DTS shape. They're pretty dumb; tbh. */
class MissionElementTSStatic extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var shapename:String;

	public function new() {
		_type = MissionElementType.TSStatic;
	}
}

@:publicFields
/** Represents a particle emitter. Currently unused by this port (these are really niche). */
class MissionElementParticleEmitterNode extends MissionElementBase {
	var position:String;
	var rotation:String;
	var scale:String;
	var datablock:String;
	var emitter:String;
	var velocity:String;

	public function new() {
		_type = MissionElementType.ParticleEmitterNode;
	}
}
