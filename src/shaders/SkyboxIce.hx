package shaders;

/** Ported from `skybox_iceF.glsl`/`interiorV.glsl` (`platinum/data/shaders/`) - the `SkyboxIce`
	material shader (`PQIceShaderMaterial` in `pack.json`), used for PQ's ice interior surfaces.
	Reflection uses `level.sky.cubemap` (the static skybox cubemap already built for sky rendering,
	see `Sky.hx`) rather than a per-object `CubemapRenderer` like the marble's own reflective skins
	(`MarbleReflection`/`ClassicGlass`) - real source's `skyboxSampler` is genuinely just a fixed
	reflection of the skybox, not a live scene reflection, so no per-frame cubemap render is needed
	here at all. `rot_from_torque_mat` (real source's fixup between Torque's raw world axes and the
	skybox's own orientation) is dropped - this port's existing skybox-reflection shaders
	(`EnvMap`/`MarbleReflection`) already reflect correctly against `sky.cubemap` with no extra
	rotation, since Heaps' world-space vectors here are already in the same frame the cubemap was
	rendered in. */
class SkyboxIce extends hxsl.Shader {
	static var SRC = {
		@param var diffuseMap:Sampler2D;
		@param var normalMap:Sampler2D;
		@param var specularMap:Sampler2D;
		@param var envMap:SamplerCube;
		@param var shininess:Float;
		@param var reflectivity:Float;
		@param var ambientLight:Vec3;
		@param var dirLight:Vec3;
		@param var dirLightDir:Vec3;
		@param var textureScale:Vec2;
		@global var camera:{
			var position:Vec3;
			@var var dir:Vec3;
		};
		@global var global:{
			@perObject var modelView:Mat4;
			@perObject var modelViewInverse:Mat4;
		};
		@input var input:{
			var normal:Vec3;
			var tangent:Vec3;
			var uv:Vec2;
		};
		var calculatedUV:Vec2;
		var pixelColor:Vec4;
		var transformedPosition:Vec3;
		var transformedNormal:Vec3;
		@var var transformedTangent:Vec4;
		function __init__vertex() {
			transformedTangent = vec4(input.tangent * global.modelView.mat3(), input.tangent.dot(input.tangent) > 0.5 ? 1. : -1.);
		}
		function vertex() {
			calculatedUV = input.uv * textureScale;
		}
		function fragment() {
			// Diffuse + bump-mapped normal, same tangent-space construction as `PQMaterial`.
			var diffuse = diffuseMap.get(calculatedUV);

			var n = transformedNormal;
			var nf = normalMap.get(calculatedUV) * 2.0 - 1.0;
			var tanX = transformedTangent.xyz.normalize();
			var tanY = n.cross(tanX) * transformedTangent.w;
			var bumpNormal = (nf.x * tanX + nf.y * tanY + nf.z * n).normalize();
			transformedNormal = bumpNormal;

			var lightNormal = -dirLightDir;
			var cosTheta = clamp(dot(bumpNormal, lightNormal), 0, 1);
			var effectiveSun = dirLight * cosTheta + ambientLight;
			effectiveSun = vec3(clamp(effectiveSun.r, 0, 1), clamp(effectiveSun.g, 0, 1), clamp(effectiveSun.b, 0, 1));

			var outCol = vec4(diffuse.rgb * effectiveSun.rgb, 1);

			// Skybox reflection (real source's `QUALITY_LEVEL > 1` branch - always on here, this
			// port has no interior-shader quality tiering).
			var eyeVec = (camera.position - transformedPosition).normalize();
			var incidentRay = -eyeVec;
			var reflectionRay = reflect(incidentRay, bumpNormal);
			var reflectionColor = envMap.get(reflectionRay);
			outCol = vec4(outCol.rgb.mix(reflectionColor.rgb, reflectivity), 1);

			// Ice is too dark without a little color added, so we adjust it a bit.
			outCol += vec4(0.2, 0.25, 0.3, 1.0) * cosTheta;

			// Real Phong specular (reflect the light around the normal, dot with the eye vector) -
			// NOT the Blinn half-angle approximation `PhongMaterial`/`PQMaterial` use elsewhere in
			// this port, since real source genuinely uses this formula here.
			var specularColor = specularMap.get(calculatedUV);
			var lightReflection = reflect(-lightNormal, bumpNormal);
			var cosAlpha = clamp(dot(eyeVec, lightReflection), 0, 1);
			var specular = specularColor.rgb * dirLight * pow(cosAlpha, shininess);

			outCol.rgb += specular.rgb;
			outCol.a = 1;

			pixelColor = outCol;
		}
	}

	public function new(diffuse, normal, specular, envMap, shininess, reflectivity, ambientLight, dirLight, dirLightDir, textureScale) {
		super();
		this.diffuseMap = diffuse;
		this.normalMap = normal;
		this.specularMap = specular;
		this.envMap = envMap;
		this.shininess = shininess;
		this.reflectivity = reflectivity;
		this.ambientLight = ambientLight.clone();
		this.dirLight = dirLight.clone();
		this.dirLightDir = dirLightDir.clone();
		this.textureScale = textureScale.clone();
	}
}
