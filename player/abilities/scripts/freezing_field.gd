extends Node

const FreezingFieldScene = preload("res://effects/player/player_freezing_field.tscn")

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1
	var scaled_radius = GameState.get_scaled_radius(data.radius, data.radius_scale_percent, peer_id)
	var scaled_duration = GameState.get_scaled_duration(data.freeze_duration, data.duration_scale_percent, peer_id)
	var field_duration = 5.0 + scaled_duration
	var slow_duration = 1.5 + scaled_duration * 0.5

	var field = FreezingFieldScene.instantiate()
	field.field_radius = scaled_radius
	field.duration = field_duration
	field.slow_duration = slow_duration
	field.effect_color = data.indicator_color
	field.follow_target = caster

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()
	container.add_child(field)
	field.global_position = caster.global_position
