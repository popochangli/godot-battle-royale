extends Node

const BreathWaveScene = preload("res://effects/player/player_breath_wave.tscn")

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	if mouse_pos == Vector2.ZERO:
		mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent, peer_id)
	var captured_pos = mouse_pos

	_spawn_wave(caster, data, direction, "fire", scaled_damage)

	caster.get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(caster):
			var new_direction = (captured_pos - caster.global_position).normalized()
			_spawn_wave(caster, data, new_direction, "ice", scaled_damage)
	)

static func _spawn_wave(caster: Node2D, data: AbilityData, direction: Vector2, type: String, scaled_damage: int) -> void:
	var wave = BreathWaveScene.instantiate()
	wave.direction = direction
	wave.damage = scaled_damage
	wave.max_range = data.range_distance
	wave.breath_type = type
	wave.caster = caster

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()
	container.add_child(wave, true)
	wave.global_position = caster.global_position
