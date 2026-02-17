extends Node

const BladeScene = preload("res://effects/player/player_assassin_blade.tscn")

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()

	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)

	var blade = BladeScene.instantiate()
	blade.direction = direction
	blade.damage = scaled_damage
	blade.max_range = data.range_distance
	blade.caster = caster
	caster.get_parent().add_child(blade)
	blade.global_position = caster.global_position
