extends Node

const BombScene = preload("res://effects/player/player_bomb.tscn")

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	if mouse_pos == Vector2.ZERO:
		mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var distance = caster.global_position.distance_to(mouse_pos)

	if distance > data.range_distance:
		distance = data.range_distance

	var target_pos = caster.global_position + direction * distance

	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent, peer_id)
	var scaled_radius = GameState.get_scaled_radius(data.radius, data.radius_scale_percent, peer_id)

	var bomb = BombScene.instantiate()
	bomb.target_position = target_pos
	bomb.damage = scaled_damage
	bomb.explosion_radius = scaled_radius
	bomb.effect_color = data.indicator_color
	bomb.caster = caster

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()
	container.add_child(bomb)
	bomb.global_position = caster.global_position
