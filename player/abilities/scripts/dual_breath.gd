extends Node

const BreathWaveScene = preload("res://effects/player/player_breath_wave.tscn")

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)

	_spawn_wave(caster, data, direction, "fire", scaled_damage)

	caster.get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(caster):
			var new_mouse_pos = caster.get_global_mouse_position()
			var new_direction = (new_mouse_pos - caster.global_position).normalized()
			_spawn_wave(caster, data, new_direction, "ice", scaled_damage)
	)

static func _spawn_wave(caster: Node2D, data: AbilityData, direction: Vector2, type: String, scaled_damage: int) -> void:
	var wave = BreathWaveScene.instantiate()
	wave.direction = direction
	wave.damage = scaled_damage
	wave.max_range = data.range_distance
	wave.breath_type = type
	wave.caster = caster
	caster.get_parent().add_child(wave)
	wave.global_position = caster.global_position
