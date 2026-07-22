package;

import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.TypeTools;
import haxe.macro.Expr;
import haxe.macro.Expr.ExprOf;
import mis.MissionElement.MissionElementType;

class MisParserMacros {
	public static macro function parseObject(name:ExprOf<String>, className:haxe.macro.Expr, classEnum:ExprOf<MissionElementType>) {
		switch (className.expr) {
			case EConst(c):
				switch (c) {
					case CIdent(s):
						var classType = Context.getType(s);
						switch (classType) {
							case TInst(ctype, cparams):
								var ct = ctype.get();
								var tfn:TypePath = {
									pack: ct.pack,
									name: ct.name
								};
								return {
									return macro {
										var fn = () -> {
											var obj = new $tfn();
											obj._type = $classEnum;
											obj._name = name;

											copyFields(obj);

											return obj;
										};
										element = fn();
									}
								};
							case _:
								throw 'Unsupported';
						}
					case _:
						throw 'Unsupported';
				}
			case _:
				throw 'Unsupported ' + Std.string(className);
		}
	}
}

class MarbleWorldMacros {
	public static macro function addStaticShapeOrItem() {
		// Rip intellisense
		return macro {
			var shape:DtsObject = null;

			// Add the correct shape based on type
			var dataBlockLowerCase = element.datablock.toLowerCase();
			if (dataBlockLowerCase == "") {} // Make sure we don't do anything if there's no data block
			else if (dataBlockLowerCase == "startpad" || dataBlockLowerCase == "startpad_mbu")
				shape = new StartPad();
			else if (dataBlockLowerCase == "endpad" || dataBlockLowerCase == "endpad_mbu") {
				shape = new EndPad();
				if (element is MissionElementStaticShape && cast(element, MissionElementStaticShape) == endPadElement)
					endPad = cast shape;
			} else if (StringTools.startsWith(dataBlockLowerCase, "arrow"))
				shape = new SignPlain(cast element);
			else if (StringTools.startsWith(dataBlockLowerCase, "gemitem")) {
				shape = new Gem(cast element);
				this.totalGems++;
				this.gems.push(cast shape);
			} else if (dataBlockLowerCase == "superjumpitem" || dataBlockLowerCase == "superjumpitem_mbu")
				shape = new SuperJump(cast element);
			else if (StringTools.startsWith(dataBlockLowerCase, "signcaution"))
				shape = new SignCaution(cast element);
			else if (dataBlockLowerCase == "roundbumper" || dataBlockLowerCase == "roundbumper_mbu")
				shape = new RoundBumper();
			else if (dataBlockLowerCase == "helicopteritem" || dataBlockLowerCase == "helicopteritem_mbu")
				shape = new Helicopter(cast element);
			else if (dataBlockLowerCase == "eastereggitem" || dataBlockLowerCase == "easteregg_mbu")
				shape = new EasterEgg(cast element);
			else if (dataBlockLowerCase == "checkpointshape") {
				shape = new Checkpoint(cast element);
			} else if (dataBlockLowerCase == "ductfan" || dataBlockLowerCase == "ductfan_mbu")
				shape = new DuctFan();
			else if (dataBlockLowerCase == "smallductfan" || dataBlockLowerCase == "smallductfan_mbu")
				shape = new SmallDuctFan();
			else if (dataBlockLowerCase == "antigravityitem" || dataBlockLowerCase == "antigravityitem_mbu")
				shape = new AntiGravity(cast element);
			else if (dataBlockLowerCase == "norespawnantigravityitem" || dataBlockLowerCase == "norespawnantigravityitem_mbu")
				shape = new AntiGravity(cast element, true);
			else if (dataBlockLowerCase == "superspeeditem" || dataBlockLowerCase == "superspeeditem_mbu")
				shape = new SuperSpeed(cast element);
			else if (dataBlockLowerCase == "timetravelitem"
				|| dataBlockLowerCase == "timepenaltyitem"
				|| dataBlockLowerCase == "timetravelitem_mbu"
				|| dataBlockLowerCase == "timepenaltyitem_mbu")
				shape = new TimeTravel(cast element);
			else if (dataBlockLowerCase == "blastitem" || dataBlockLowerCase == "blastitem_mbu")
				shape = new Blast(cast element);
			else if (dataBlockLowerCase == "megamarbleitem" || dataBlockLowerCase == "megamarbleitem_mbu")
				shape = new MegaMarble(cast element);
			else if (dataBlockLowerCase == "trapdoor" || dataBlockLowerCase == "trapdoor_mbu")
				shape = new Trapdoor();
			else if ([
				"glass_3shape",
				"glass_6shape",
				"glass_9shape",
				"glass_12shape",
				"glass_15shape",
				"glass_18shape"
			].contains(dataBlockLowerCase))
				shape = new Glass(cast element);
			else if ([
				"astrolabecloudsbeginnershape",
				"astrolabecloudsintermediateshape",
				"astrolabecloudsadvancedshape"
			].contains(dataBlockLowerCase))
				shape = new shapes.Sky(dataBlockLowerCase);
			else if (dataBlockLowerCase == "astrolabeshape" || dataBlockLowerCase == "astrolabe")
				shape = new shapes.Astrolabe();
			else {
				Console.error("Unknown item: " + element.datablock);
				onFinish();
				return;
			}

			if (element._name != null && element._name != "") {
				this.namedObjects.set(element._name, {
					obj: shape,
					elem: element
				});
			}

			var shapePosition = MisParser.parseVector3(element.position);
			shapePosition.x = -shapePosition.x;
			var shapeRotation = MisParser.parseRotation(element.rotation);
			shapeRotation.x = -shapeRotation.x;
			shapeRotation.w = -shapeRotation.w;
			var shapeScale = MisParser.parseVector3(element.scale);

			// Apparently we still do collide with zero-volume shapes
			if (shapeScale.x == 0)
				shapeScale.x = 0.0001;
			if (shapeScale.y == 0)
				shapeScale.y = 0.0001;
			if (shapeScale.z == 0)
				shapeScale.z = 0.0001;

			var mat = Matrix.S(shapeScale.x, shapeScale.y, shapeScale.z);
			var tmp = new Matrix();
			shapeRotation.toMatrix(tmp);
			mat.multiply3x4(mat, tmp);
			mat.setPosition(shapePosition);

			this.addDtsObject(shape, () -> {
				addToSimgroup(shape, simGroup);
				shape.setTransform(mat);
				onFinish();
			});
		}
	}
}
