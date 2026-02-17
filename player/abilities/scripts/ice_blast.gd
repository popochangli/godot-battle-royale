extends Node

const IceShardScene = preload("res://effects/player/player_ice_shard.tscn")
const ICE_SHARD_PATH = "res://effects/player/player_ice_shard.tscn"

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1
	var base_direction = caster.aim_direction
	var half_spread = deg_to_rad(data.spread_angle / 2.0)
	var projectile_count = data.projectile_count + GameState.get_bonus_projectiles(data.projectile_bonus_levels, peer_id)
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent, peer_id)
	var caster_peer_id = caster.get_multiplayer_authority() if caster.has_method("get_multiplayer_authority") else 1

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()

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
		shard.caster_peer_id = caster_peer_id
		container.add_child(shard, true)
		shard.global_position = caster.global_position
