extends Node

const ShrapnelScene = preload("res://effects/player/player_shrapnel.tscn")

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	if mouse_pos == Vector2.ZERO:
		mouse_pos = caster.get_global_mouse_position()
	var distance = caster.global_position.distance_to(mouse_pos)

	if distance > data.range_distance:
		distance = data.range_distance
		mouse_pos = caster.global_position + (mouse_pos - caster.global_position).normalized() * distance

	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent, peer_id)

	var shrapnel = ShrapnelScene.instantiate()
	shrapnel.target_position = mouse_pos
	shrapnel.damage = scaled_damage
	shrapnel.explosion_radius = data.radius if data.radius > 0 else 100.0
	shrapnel.caster = caster

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()
	container.add_child(shrapnel)
	shrapnel.global_position = caster.global_position
