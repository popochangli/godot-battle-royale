extends Node

const BladeScene = preload("res://effects/player/player_assassin_blade.tscn")

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	if mouse_pos == Vector2.ZERO:
		mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()

	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent, peer_id)

	var blade = BladeScene.instantiate()
	blade.direction = direction
	blade.damage = scaled_damage
	blade.max_range = data.range_distance
	blade.caster = caster

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()
	container.add_child(blade, true)
	blade.global_position = caster.global_position
