extends Node

const FreezingFieldScene = preload("res://effects/player/player_freezing_field.tscn")

static func execute(caster: Node2D, data: AbilityData) -> void:
	var scaled_radius = GameState.get_scaled_radius(data.radius, data.radius_scale_percent)
	var scaled_duration = GameState.get_scaled_duration(data.freeze_duration, data.duration_scale_percent)
	var field_duration = 5.0 + scaled_duration
	var slow_duration = 1.5 + scaled_duration * 0.5

	var field = FreezingFieldScene.instantiate()
	field.field_radius = scaled_radius
	field.duration = field_duration
	field.slow_duration = slow_duration
	field.effect_color = data.indicator_color
	caster.add_child(field)
