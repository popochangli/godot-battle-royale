extends Node

const BombScene = preload("res://effects/player/player_bomb.tscn")

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var distance = caster.global_position.distance_to(mouse_pos)

	if distance > data.range_distance:
		distance = data.range_distance

	var target_pos = caster.global_position + direction * distance

	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)
	var scaled_radius = GameState.get_scaled_radius(data.radius, data.radius_scale_percent)

	var bomb = BombScene.instantiate()
	bomb.target_position = target_pos
	bomb.damage = scaled_damage
	bomb.explosion_radius = scaled_radius
	bomb.effect_color = data.indicator_color
	bomb.caster = caster
	caster.get_parent().add_child(bomb)
	bomb.global_position = caster.global_position
