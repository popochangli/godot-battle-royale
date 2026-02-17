extends Node

const FIREBALL_SCENE_PATH := "res://effects/enemy/enemy_fireball.tscn"

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	var player = _find_nearest_player(caster)
	if not player:
		return

	var direction = (player.global_position - caster.global_position).normalized()
	_spawn_synced_effect(caster, {
		"scene": FIREBALL_SCENE_PATH,
		"pos": caster.global_position,
		"direction": direction,
		"damage": data.damage,
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
	var effect = effect_scene.instantiate()
	effect.global_position = effect_data.get("pos", caster.global_position)
	if effect_data.has("direction"):
		effect.direction = effect_data["direction"]
	if effect_data.has("damage"):
		effect.damage = effect_data["damage"]
	if effect_data.has("effect_color"):
		var c = effect_data["effect_color"]
		if c is Array and c.size() >= 4:
			effect.effect_color = Color(c[0], c[1], c[2], c[3])

	var effects = caster.get_tree().get_first_node_in_group("effects_container")
	if effects:
		effects.add_child(effect, true)
	elif caster.get_parent():
		caster.get_parent().add_child(effect, true)

static func _find_nearest_player(caster: Node2D) -> Node2D:
	var nearest = null
	var min_dist = INF
	for p in caster.get_tree().get_nodes_in_group("player"):
		if p.get("health") and p.health <= 0:
			continue
		var d = caster.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest
