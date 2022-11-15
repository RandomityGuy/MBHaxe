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
