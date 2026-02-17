extends Node

const IcePathScene = preload("res://effects/player/player_ice_path.tscn")

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	if mouse_pos == Vector2.ZERO:
		mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var distance = min(caster.global_position.distance_to(mouse_pos), data.range_distance)

	var ice_path = IcePathScene.instantiate()
	ice_path.path_direction = direction
	ice_path.path_length = distance
	ice_path.caster = caster

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()
	container.add_child(ice_path)
	ice_path.global_position = caster.global_position
