extends Node

const IcePathScene = preload("res://effects/player/player_ice_path.tscn")

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var distance = min(caster.global_position.distance_to(mouse_pos), data.range_distance)

	var ice_path = IcePathScene.instantiate()
	ice_path.path_direction = direction
	ice_path.path_length = distance
	ice_path.caster = caster
	caster.get_parent().add_child(ice_path)
	ice_path.global_position = caster.global_position
