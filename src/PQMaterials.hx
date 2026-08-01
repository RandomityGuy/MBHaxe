package src;

import h3d.Vector;

using src.DifBuilder;

class PQMaterials {
	public static var shaderMaterialDict:Map<String, (hxsl.Shader->Void)->Void> = buildShaderMaterialDict();

	static function buildShaderMaterialDict():Map<String, (hxsl.Shader->Void)->Void> {
		var shaderMaterialDict:Map<String, (hxsl.Shader->Void)->Void> = [
			'interiors_mbu/plate_1' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'plate.randomize.png', 'plate.normal.png', 8,
				new Vector(1, 1, 0.8, 1), 0.5),
			'interiors_mbu/tile_beginner' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner.png', '', 40, new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_beginner_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_beginner_red' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_beginner_red_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_red_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_beginner_blue' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_beginner_blue_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner.png', '_blue_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_intermediate' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_intermediate_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_intermediate_red' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_intermediate_red_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_red_shadow',
				40, new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_intermediate_green' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate.png', '_green', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_intermediate_green_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate.png',
				'_green_shadow', 40, new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_advanced' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced.png', '', 40, new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_advanced_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_advanced_blue' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_advanced_blue_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_blue_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_advanced_green' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_advanced_green_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced.png', '_green_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_underside' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_underside.png', '', 40, new Vector(1, 1, 1, 1)),
			'interiors_mbu/wall_beginner' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'wall_beginner.png', 'wall_mbu.normal.png', 12,
				new Vector(0.8, 0.8, 0.6, 1)),
			'interiors_mbu/edge_white' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'edge_white.png', 'edge.normal.png', 50,
				new Vector(0.8, 0.8, 0.8, 1)),
			'interiors_mbu/edge_white_shadow' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'edge_white_shadow.png', 'edge.normal.png', 50,
				new Vector(0.2, 0.2, 0.2, 0.2)),
			'interiors_mbu/beam' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'beam.png', 'beam.normal.png', 12, new Vector(0.8, 0.8, 0.6, 1)),
			'interiors_mbu/beam_side' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'beam_side.png', 'beam_side.normal.png', 12,
				new Vector(0.8, 0.8, 0.6, 1)),
			'interiors_mbu/friction_low' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_low.png', 'friction_low.normal.png', 128,
				new Vector(1, 1, 1, 0.8)),
			'interiors_mbu/friction_low_shadow' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_low_shadow.png',
				'friction_low.normal.png', 128, new Vector(0.3, 0.3, 0.35, 1)),
			'interiors_mbu/friction_high' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_high.png', 'friction_high.normal.png', 10,
				new Vector(0.3, 0.3, 0.35, 1)),
			'interiors_mbu/friction_high_shadow' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_high_shadow.png',
				'friction_high.normal.png', 10, new Vector(0.15, 0.15, 0.16, 1.0)),
			'interiors_mbu/stripe_caution' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'stripe_caution.png', 'DefaultNormal.png', 12,
				new Vector(0.8, 0.8, 0.6, 1)),
			'multiplayer/interiors/platinumquest/pq_hot_1_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_hot_1_med.jpg', 'tile.normal.png',
				'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_hot_2_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_hot_2_light.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_hot_4_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_hot_4_med.jpg', 'tile.normal.png',
				'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_blue_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_blue_med.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_dark' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_dark.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_light.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_med.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_random' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_random.jpg',
				'tile.normal.png', 'tile.spec.png', 0.25),
			'multiplayer/interiors/platinumquest/pq_rays_red_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_red_light.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_purple_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_purple_light.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_purple_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_purple_med.jpg',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_friction_ice' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_friction_ice.jpg',
				'ice.normal.png', 'DefaultSpec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_1' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_1.png',
				'pq_ray_wall_1.normal.png', 'pq_ray_wall_1.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_2' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_2.png',
				'pq_ray_wall_2.normal.png', 'pq_ray_wall_2.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_3' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_3.png',
				'pq_ray_wall_3.normal.png', 'pq_ray_wall_3.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_4' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_4.png',
				'pq_ray_wall_4.normal.png', 'pq_ray_wall_4.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_5' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_5.png',
				'pq_ray_wall_5.normal.png', 'pq_ray_wall_5.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_6' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_6.png',
				'pq_ray_wall_6.normal.png', 'pq_ray_wall_6.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_7' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_7.png',
				'pq_ray_wall_7.normal.png', 'pq_ray_wall_7.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_8' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_8.png',
				'pq_ray_wall_8.normal.png', 'pq_ray_wall_8.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_combo.png',
				'pq_ray_wall_combo.normal.png', 'pq_ray_wall_combo.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_combo_2.png',
				'pq_ray_wall_combo_2.normal.png', 'pq_ray_wall_combo_2.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2_medium' => (onFinish) -> DifBuilder.createPQMaterial(onFinish,
				'pq_ray_wall_combo_2_medium.png', 'pq_ray_wall_combo_2.normal.png', 'pq_ray_wall_combo_2.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo_small' => (onFinish) -> DifBuilder.createPQMaterial(onFinish,
				'pq_ray_wall_combo_small.png', 'pq_ray_wall_combo.normal.png', 'pq_ray_wall_combo.spec.png'),
		];

		addPqInteriorMaterials(shaderMaterialDict);

		return shaderMaterialDict;
	}

	/** Ported from `texture_materials` in the real `pack.json` (`platinum/data/texture_packs/default/pack.json`)
		- covers every entry whose material definition has no `shader` field (plain diffuse/normal/
		specular via `PQMaterial`, same shader `createPQMaterial` above already uses), keyed to the
		real `interiors_pq/pq_*` assets already present in this repo's `data/interiors_pq/` folder
		(the `multiplayer/interiors/platinumquest/` entries above are for old MBG multiplayer maps
		reusing a handful of PQ textures - a different, much smaller set - not these).
		`lbinteriors_pq/`/`lbinteriors_custom/pq/` are pack.json aliases for the exact same assets
		(confirmed both folders are empty on disk, i.e. editor-only source paths with nothing
		actually shipped under them). `ResourceLoader.hx`/`Mission.hx` already normalize
		`lbinteriors* -> interiors*` at load time, so `lbinteriors_pq` needs no extra handling here;
		`lbinteriors_custom/pq` survives that normalization as `interiors_custom/pq`, which
		`DifBuilder.hx`'s `matDictName` resolution separately folds down to `interiors_pq` - so a
		single dict entry per basename still covers all three source forms.
		`PQRayWallMaterial`/`PQCirclesRandomMaterial`/`PQRaysRandomMaterial`/`PQHotRandomMaterial`/
		`PQNeutralRandomMaterial` are deliberately NOT ported as their own real shader
		(`Choice_Tile_Array`/`Choice_Tile_Diffuse_Array`, real per-quad runtime slice randomization)
		- same simplification this codebase's pre-existing `multiplayer/interiors/platinumquest/
		pq_rays_green_random` entry above already uses: real PQ's "random" variants are actually just
		ordinary, already-baked-to-look-varied square diffuse textures (confirmed: e.g.
		`pq_hot_1_random.jpg` is a plain 512x512 image, not a packed multi-tile strip), so they're
		wired below as plain `PQMaterial` entries exactly like the "dark"/"light"/"med" ones, just
		using the "random" asset as the diffuse. `secondaryFactor=0.25` compensates for these being
		4x the pixel size of the shared 128x128 `tile.normal.png`/`tile.spec.png` pair (same reason
		the pre-existing `pq_rays_green_random` entry uses that exact factor) - this is purely a
		texture-resolution compensation, unrelated to any "_2"/"_small" naming, so it applies equally
		to every "random"/"random_2" variant and their own "_small" counterparts (which are just
		lower-res versions of the exact same image, not a different real-world tile size).
		`MPTileMaterial` is out of scope here - it's a different, MP-only asset family
		(`multiplayer/interiors/mbu_neutralN_random*`) unrelated to `interiors_pq`.
		**Still NOT covered**: `PQAltNeutralMaterial` - defined in `pack.json` but not actually
		referenced by any `texture_materials` entry - dead in the default pack, skipped. */
	static function addPqInteriorMaterials(shaderMaterialDict:Map<String, (hxsl.Shader->Void)->Void>) {
		// Real pack.json paths, copied in from the actual PQ source tree
		// (`platinum/data/shaders/tex/pq_tile/`) into `data/shaders/tex/pq_tile/` in this repo.
		var tileNormal = 'shaders/tex/pq_tile/tile.normal.png';
		var tileSpec = 'shaders/tex/pq_tile/tile.spec.png';

		function addPqTile(basename:String) {
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}.jpg', tileNormal, tileSpec));
		}

		// PQCirclesMaterial
		for (color in ["blue", "gray", "green", "orange", "purple", "red", "yellow"])
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_circles_${color}_${shade}');

		// PQHotMaterial
		for (i in 1...7)
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_hot_${i}_${shade}');

		// PQNeutralMaterial
		for (i in 1...8)
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_neutral_${i}_${shade}');

		// PQRaysMaterial
		for (color in ["blue", "green", "purple", "red"])
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_rays_${color}_${shade}');

		// PQWaterShaderMaterial (mmg_water/pq_friction_water/water) - real pack.json normal/spec,
		// copied into `data/shaders/tex/pq_tile/water.normal.png` / `data/shaders/tex/DefaultSpec.png`.
		var waterNormal = 'shaders/tex/pq_tile/water.normal.png';
		var waterSpec = 'shaders/tex/DefaultSpec.png';
		for (basename in ["mmg_water", "pq_friction_water", "water"])
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}.jpg', waterNormal, waterSpec));

		// PQIceShaderMaterial (real shader `SkyboxIce`, reflectivity 0.3) - real pack.json normal/spec.
		// `pq_friction_ice_with_danger` is a THIRD material instance using this shader (per
		// pack.json) but has no backing diffuse asset anywhere in this repo (checked `interiors_pq/`
		// - only plain `pq_friction_ice.jpg`/`ice1.jpg` exist) - skipped, not approximated.
		var iceNormal = 'shaders/tex/pq_tile/ice.normal.png';
		var iceSpec = 'shaders/tex/DefaultSpec.png';
		for (basename in ["ice1", "pq_friction_ice"])
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createSkyboxIceMaterial(onFinish, 'interiors_pq/${basename}.jpg', iceNormal, iceSpec, 0.3, new Vector(1, 1)));

		// "Random" variants of circles/hot/neutral/rays - plain PQMaterial, secondaryFactor 0.25 (see
		// class doc comment above for why). Ported directly from the real, already-present
		// `data/interiors_pq/` assets - only entries with a real backing file are added, matching
		// exactly what's on disk (not every color/number has every suffix).
		function addRandomPqTile(basename:String) {
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}.jpg', tileNormal, tileSpec, 0.25));
		}
		for (color in ["blue", "gray", "green", "orange", "purple", "red", "yellow"])
			addRandomPqTile('pq_circles_${color}_random');
		addRandomPqTile('pq_circles_blue_random_2'); // the only circles color with a second variant
		for (i in 1...7) {
			addRandomPqTile('pq_hot_${i}_random');
			addRandomPqTile('pq_hot_${i}_random_small');
		}
		for (i in 1...8) {
			addRandomPqTile('pq_neutral_${i}_random');
			addRandomPqTile('pq_neutral_${i}_random_small');
		}
		for (color in ["blue", "green", "purple", "red"])
			for (suffix in ["random", "random_2", "random_small", "random_2_small"])
				addRandomPqTile('pq_rays_${color}_${suffix}');

		// "_small" (lower-res) variants of the plain dark/light/med tiles - same material as their
		// full-res counterpart (same real-world tile, just a smaller downloaded/rendered texture),
		// again only where a real file actually backs it (circles has none).
		for (i in 1...7)
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_hot_${i}_${shade}_small');
		for (i in 1...8)
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_neutral_${i}_${shade}_small');
		for (color in ["blue", "green", "purple", "red"])
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_rays_${color}_${shade}_small');

		// PQRayWallMaterial - same "plain PQMaterial per numbered variant" treatment as the
		// pre-existing `multiplayer/interiors/platinumquest/pq_ray_wall_N` entries above, just
		// pointed at the real `interiors_pq/` assets (which include their own per-variant
		// normal/specular maps, unlike the multiplayer set).
		for (i in 1...9)
			shaderMaterialDict.set('interiors_pq/pq_ray_wall_${i}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/pq_ray_wall_${i}.png', 'interiors_pq/pq_ray_wall_${i}.normal.png',
					'interiors_pq/pq_ray_wall_${i}.spec.png'));

		// The "combo" ray-wall variants have no per-variant normal/spec of their own in
		// `interiors_pq/` - reusing the shared substitute pairs the pre-existing multiplayer combo
		// entries above already rely on (`combo`/`combo_2`'s own normal/spec, matching which "family"
		// each belongs to).
		var comboNormal = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo.normal.png';
		var comboSpec = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo.spec.png';
		var combo2Normal = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2.normal.png';
		var combo2Spec = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2.spec.png';
		function addRayWallCombo(basename:String, normal:String, spec:String) {
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}.png', normal, spec));
		}
		for (basename in ["pq_ray_wall_combo", "pq_ray_wall_combo_small", "pq_ray_wall_combo_repul"])
			addRayWallCombo(basename, comboNormal, comboSpec);
		for (basename in ["pq_ray_wall_combo_2", "pq_ray_wall_combo_2_medium", "pq_ray_wall_combo_2_small"])
			addRayWallCombo(basename, combo2Normal, combo2Spec);
		addRayWallCombo("pq_ray_wall_combo_medium", comboNormal, comboSpec);
		addRayWallCombo("pattern_cool2", comboNormal, comboSpec);
	}
}
