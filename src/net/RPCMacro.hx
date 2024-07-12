package net;

import haxe.macro.Context;
import haxe.macro.Expr;

class RPCMacro {
	macro static public function build():Array<Field> {
		var fields = Context.getBuildFields();

		var rpcFnId = 1;

		var idtoFn:Map<Int, {
			name:String,
			serialize:Array<Expr>,
			deserialize:Array<Expr>
		}> = new Map();

		var fieldsToAdd = [];

		for (field in fields) {
			if (field.meta.length > 0 && field.meta[0].name == ':rpc') {
				switch (field.kind) {
					case FFun(f):
						{
							var serializeFns = [];
							var deserializeFns = [];
							var callExprs = [];
							for (arg in f.args) {
								var argName = arg.name;
								switch (arg.type) {
									case TPath({
										name: 'Int'
									}): {
										deserializeFns.push(macro var $argName = stream.readInt32());
										callExprs.push(macro $i{argName});
										serializeFns.push(macro stream.writeInt32($i{argName}));
									}

									case TPath({
										name: 'Bool'
									}): {
										deserializeFns.push(macro var $argName = stream.readFlag());
										callExprs.push(macro $i{argName});
										serializeFns.push(macro stream.writeFlag($i{argName}));
									}

									case TPath({
										name: 'Float'
									}): {
										deserializeFns.push(macro var $argName = stream.readFloat());
										callExprs.push(macro $i{argName});
										serializeFns.push(macro stream.writeFloat($i{argName}));
									}

									case TPath({
										name: 'String'
									}): {
										deserializeFns.push(macro var $argName = stream.readString());
										callExprs.push(macro $i{argName});
										serializeFns.push(macro stream.writeString($i{argName}));
									}

									case _: {}
								}
							}
							deserializeFns.push(macro {
								$i{field.name}($a{callExprs});
							});
							idtoFn.set(rpcFnId, {
								name: field.name,
								serialize: serializeFns,
								deserialize: deserializeFns
							});

							var directionParam = field.meta[0].params[0].expr;
							switch (directionParam) {
								case EConst(CIdent("server")):
									var lastExpr = macro {
										if (Net.isHost) {
											var stream = new net.BitStream.OutputBitStream();
											stream.writeByte(NetPacketType.NetCommand);
											stream.writeByte($v{rpcFnId});
											$b{serializeFns};
											Net.sendPacketToAll(stream);
										}
									};
									var origExpr = f.expr;
									var lastExprSingle = macro {
										if (Net.isHost) {
											var stream = new net.BitStream.OutputBitStream();
											stream.writeByte(NetPacketType.NetCommand);
											stream.writeByte($v{rpcFnId});
											$b{serializeFns};
											Net.sendPacketToClient(client, stream);
										}
									};

									var singleClientfn:Field = {
										name: field.name + "Client",
										pos: Context.currentPos(),
										access: [APublic, AStatic],
										kind: FFun({
											args: [
												{
													name: "client",
													type: haxe.macro.TypeTools.toComplexType(Context.getType('net.ClientConnection.GameConnection'))
												}
											].concat(f.args),
											expr: macro $b{[origExpr, lastExprSingle]}
										})
									};
									fieldsToAdd.push(singleClientfn);

									f.expr = macro $b{[f.expr, lastExpr]};

								case EConst(CIdent("client")):
									var lastExpr = macro {
										if (!Net.isHost) {
											var stream = new net.BitStream.OutputBitStream();
											stream.writeByte(NetPacketType.NetCommand);
											stream.writeByte($v{rpcFnId});
											$b{serializeFns};
											Net.sendPacketToHost(stream);
										}
									};

									f.expr = macro $b{[f.expr, lastExpr]};

								case _:
									{}
							}

							rpcFnId++;
						}

					case _:
						{}
				}
			}
		}

		var cases:Array<Case> = [];
		for (k => v in idtoFn) {
			cases.push({
				values: [macro $v{k}],
				expr: macro {
					$b{v.deserialize}
				}
			});
		}

		var deserializeField:Field = {
			name: "readPacket",
			pos: Context.currentPos(),
			access: [APublic, AStatic],
			kind: FFun({
				args: [
					{
						name: "stream",
						type: haxe.macro.TypeTools.toComplexType(Context.getType('net.BitStream.InputBitStream'))
					}
				],
				expr: macro {
					var fnId = stream.readByte();

					$e{
						{
							expr: ESwitch(macro fnId, cases, null),
							pos: Context.currentPos()
						}
					}
				}
			})
		};

		fields.push(deserializeField);
		for (fn in fieldsToAdd) {
			fields.push(fn);
		}

		return fields;
	}
}
