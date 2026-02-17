extends Node

const GROUND_SLAM_SCENE_PATH := "res://effects/enemy/enemy_ground_slam.tscn"

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	_spawn_synced_effect(caster, {
		"scene": GROUND_SLAM_SCENE_PATH,
		"pos": caster.global_position,
		"damage": data.damage,
		"radius": data.radius,
		"effect_color": [data.effect_color.r, data.effect_color.g, data.effect_color.b, data.effect_color.a],
	})

static func _spawn_synced_effect(caster: Node2D, effect_data: Dictionary) -> void:
	var main = caster.get_tree().current_scene
	if main and main.has_method("spawn_effect_sync"):
		main.spawn_effect_sync(effect_data)
		return

	# Fallback for non-network/offline contexts.
	if not ResourceLoader.exists(effect_data.get("scene", "")):
		return
	var effect_scene = load(effect_data["scene"]) as PackedScene
	var slam = effect_scene.instantiate()
	slam.damage = effect_data.get("damage", 0)
	slam.radius = effect_data.get("radius", 100.0)
	if effect_data.has("effect_color"):
		var c = effect_data["effect_color"]
		if c is Array and c.size() >= 4:
			slam.effect_color = Color(c[0], c[1], c[2], c[3])
	slam.caster = caster
	slam.global_position = effect_data.get("pos", caster.global_position)
	var effects = caster.get_tree().get_first_node_in_group("effects_container")
	if effects:
		effects.add_child(slam, true)
	elif caster.get_parent():
		caster.get_parent().add_child(slam, true)
