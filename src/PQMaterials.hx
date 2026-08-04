package src;

import h3d.Vector;

using src.DifBuilder;

class PQMaterials {
	public static var shaderMaterialDict:Map<String, (hxsl.Shader->Void)->Void> = buildShaderMaterialDict();

	static function buildShaderMaterialDict():Map<String, (hxsl.Shader->Void)->Void> {
		var shaderMaterialDict:Map<String, (hxsl.Shader->Void)->Void> = [
			'interiors_mbu/plate_1' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'plate.randomize', 'plate.normal.png', 8,
				new Vector(1, 1, 0.8, 1), 0.5),
			'interiors_mbu/tile_beginner' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner', '', 40, new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_beginner_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner', '_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_beginner_red' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner', '_red', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_beginner_red_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner', '_red_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_beginner_blue' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner', '_blue', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_beginner_blue_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_beginner', '_blue_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_intermediate' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate', '', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_intermediate_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate', '_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_intermediate_red' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate', '_red', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_intermediate_red_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate', '_red_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_intermediate_green' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate', '_green', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_intermediate_green_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_intermediate', '_green_shadow',
				40, new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_advanced' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced', '', 40, new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_advanced_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced', '_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_advanced_blue' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced', '_blue', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_advanced_blue_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced', '_blue_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_advanced_green' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced', '_green', 40,
				new Vector(1, 1, 1, 1)),
			'interiors_mbu/tile_advanced_green_shadow' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_advanced', '_green_shadow', 40,
				new Vector(0.2, 0.2, 0.2, 0.2), 1 / 4),
			'interiors_mbu/tile_underside' => (onFinish) -> DifBuilder.createNoiseTileMaterial(onFinish, 'tile_underside', '', 40, new Vector(1, 1, 1, 1)),
			'interiors_mbu/wall_beginner' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'wall_beginner', 'wall_mbu.normal.png', 12,
				new Vector(0.8, 0.8, 0.6, 1)),
			'interiors_mbu/edge_white' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'edge_white', 'edge.normal.png', 50,
				new Vector(0.8, 0.8, 0.8, 1)),
			'interiors_mbu/edge_white_shadow' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'edge_white_shadow', 'edge.normal.png', 50,
				new Vector(0.2, 0.2, 0.2, 0.2)),
			'interiors_mbu/beam' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'beam', 'beam.normal.png', 12, new Vector(0.8, 0.8, 0.6, 1)),
			'interiors_mbu/beam_side' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'beam_side', 'beam_side.normal.png', 12,
				new Vector(0.8, 0.8, 0.6, 1)),
			'interiors_mbu/friction_low' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_low', 'friction_low.normal.png', 128,
				new Vector(1, 1, 1, 0.8)),
			'interiors_mbu/friction_low_shadow' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_low_shadow', 'friction_low.normal.png',
				128, new Vector(0.3, 0.3, 0.35, 1)),
			'interiors_mbu/friction_high' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_high', 'friction_high.normal.png', 10,
				new Vector(0.3, 0.3, 0.35, 1)),
			'interiors_mbu/friction_high_shadow' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'friction_high_shadow', 'friction_high.normal.png',
				10, new Vector(0.15, 0.15, 0.16, 1.0)),
			'interiors_mbu/stripe_caution' => (onFinish) -> DifBuilder.createPhongMaterial(onFinish, 'stripe_caution', 'DefaultNormal.png', 12,
				new Vector(0.8, 0.8, 0.6, 1)),
			'multiplayer/interiors/platinumquest/pq_hot_1_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_hot_1_med', 'tile.normal.png',
				'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_hot_2_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_hot_2_light', 'tile.normal.png',
				'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_hot_4_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_hot_4_med', 'tile.normal.png',
				'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_blue_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_blue_med',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_dark' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_dark',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_light',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_med',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_green_random' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_green_random',
				'tile.normal.png', 'tile.spec.png', 4),
			'multiplayer/interiors/platinumquest/pq_rays_red_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_red_light',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_purple_light' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_purple_light',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_rays_purple_med' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_rays_purple_med',
				'tile.normal.png', 'tile.spec.png'),
			'multiplayer/interiors/platinumquest/pq_friction_ice' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_friction_ice', 'ice.normal.png',
				'DefaultSpec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_1' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_1',
				'pq_ray_wall_1.normal.png', 'pq_ray_wall_1.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_2' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_2',
				'pq_ray_wall_2.normal.png', 'pq_ray_wall_2.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_3' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_3',
				'pq_ray_wall_3.normal.png', 'pq_ray_wall_3.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_4' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_4',
				'pq_ray_wall_4.normal.png', 'pq_ray_wall_4.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_5' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_5',
				'pq_ray_wall_5.normal.png', 'pq_ray_wall_5.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_6' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_6',
				'pq_ray_wall_6.normal.png', 'pq_ray_wall_6.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_7' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_7',
				'pq_ray_wall_7.normal.png', 'pq_ray_wall_7.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_8' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_8',
				'pq_ray_wall_8.normal.png', 'pq_ray_wall_8.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_combo',
				'pq_ray_wall_combo.normal.png', 'pq_ray_wall_combo.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_combo_2',
				'pq_ray_wall_combo_2.normal.png', 'pq_ray_wall_combo_2.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2_medium' => (onFinish) -> DifBuilder.createPQMaterial(onFinish,
				'pq_ray_wall_combo_2_medium', 'pq_ray_wall_combo_2.normal.png', 'pq_ray_wall_combo_2.spec.png'),
			'multiplayer/interiors/platinumquest/pq_ray_wall_combo_small' => (onFinish) -> DifBuilder.createPQMaterial(onFinish, 'pq_ray_wall_combo_small',
				'pq_ray_wall_combo.normal.png', 'pq_ray_wall_combo.spec.png'),
		];

		addPqInteriorMaterials(shaderMaterialDict);

		return shaderMaterialDict;
	}

	static function addPqInteriorMaterials(shaderMaterialDict:Map<String, (hxsl.Shader->Void)->Void>) {
		var tileNormal = 'shaders/tex/pq_tile/tile.normal.png';
		var tileSpec = 'shaders/tex/pq_tile/tile.spec.png';

		function addPqTile(basename:String) {
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}', tileNormal, tileSpec));
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

		// PQWaterShaderMaterial (mmg_water/pq_friction_water/water)
		var waterNormal = 'shaders/tex/pq_tile/water.normal.png';
		var waterSpec = 'shaders/tex/DefaultSpec.png';
		for (basename in ["mmg_water", "pq_friction_water", "water"])
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}', waterNormal, waterSpec));

		// PQIceShaderMaterial
		var iceNormal = 'shaders/tex/pq_tile/ice.normal.png';
		var iceSpec = 'shaders/tex/DefaultSpec.png';
		for (basename in ["ice1", "pq_friction_ice"])
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createSkyboxIceMaterial(onFinish, 'interiors_pq/${basename}', iceNormal, iceSpec, 0.3, new Vector(1, 1)));

		// "Random" variants of circles/hot/neutral/rays
		function addRandomPqTile(basename:String) {
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}', tileNormal, tileSpec, 4));
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

		// "_small" (lower-res) variants of the plain dark/light/med tiles
		for (i in 1...7)
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_hot_${i}_${shade}_small');
		for (i in 1...8)
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_neutral_${i}_${shade}_small');
		for (color in ["blue", "green", "purple", "red"])
			for (shade in ["dark", "light", "med"])
				addPqTile('pq_rays_${color}_${shade}_small');

		// PQRayWallMaterial
		for (i in 1...9)
			shaderMaterialDict.set('interiors_pq/pq_ray_wall_${i}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/pq_ray_wall_${i}', 'interiors_pq/pq_ray_wall_${i}.normal.png',
					'interiors_pq/pq_ray_wall_${i}.spec.png'));

		var comboNormal = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo.normal.png';
		var comboSpec = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo.spec.png';
		var combo2Normal = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2.normal.png';
		var combo2Spec = 'multiplayer/interiors/platinumquest/pq_ray_wall_combo_2.spec.png';
		function addRayWallCombo(basename:String, normal:String, spec:String) {
			shaderMaterialDict.set('interiors_pq/${basename}',
				(onFinish) -> DifBuilder.createPQMaterialPaths(onFinish, 'interiors_pq/${basename}', normal, spec));
		}
		for (basename in ["pq_ray_wall_combo", "pq_ray_wall_combo_small", "pq_ray_wall_combo_repul"])
			addRayWallCombo(basename, comboNormal, comboSpec);
		for (basename in ["pq_ray_wall_combo_2", "pq_ray_wall_combo_2_medium", "pq_ray_wall_combo_2_small"])
			addRayWallCombo(basename, combo2Normal, combo2Spec);
		addRayWallCombo("pq_ray_wall_combo_medium", comboNormal, comboSpec);
		addRayWallCombo("pattern_cool2", comboNormal, comboSpec);
	}
}
