extends Node

const IceShardScene = preload("res://effects/player/player_ice_shard.tscn")

static func execute(caster: Node2D, data: AbilityData) -> void:
	var base_direction = caster.aim_direction
	var half_spread = deg_to_rad(data.spread_angle / 2.0)
	var projectile_count = data.projectile_count + GameState.get_bonus_projectiles(data.projectile_bonus_levels)
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)

	for i in range(projectile_count):
		var angle_offset: float
		if projectile_count == 1:
			angle_offset = 0.0
		else:
			angle_offset = lerp(-half_spread, half_spread, float(i) / float(projectile_count - 1))

		var shoot_direction = base_direction.rotated(angle_offset)

		var shard = IceShardScene.instantiate()
		shard.direction = shoot_direction
		shard.damage = scaled_damage
		shard.max_range = data.range_distance
		shard.effect_color = data.indicator_color
		shard.caster = caster
		caster.get_parent().add_child(shard)
		shard.global_position = caster.global_position
