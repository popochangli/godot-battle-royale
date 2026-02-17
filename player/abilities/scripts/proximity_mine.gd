extends Node

const MAX_MINES_PER_PLAYER = 3
const MineScene = preload("res://effects/player/player_proximity_mine.tscn")

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1
	var owner_id = peer_id

	var existing_mines = caster.get_tree().get_nodes_in_group("techies_mines")
	var player_mines = []
	for mine_node in existing_mines:
		if mine_node.has_meta("owner_id") and mine_node.get_meta("owner_id") == owner_id:
			player_mines.append(mine_node)

	while player_mines.size() >= MAX_MINES_PER_PLAYER:
		var oldest_mine = player_mines.pop_front()
		if is_instance_valid(oldest_mine):
			oldest_mine.queue_free()

	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent, peer_id)

	var mine = MineScene.instantiate()
	mine.damage = scaled_damage
	mine.mine_radius = data.radius
	mine.effect_color = data.indicator_color
	mine.owner_id = owner_id
	mine.caster = caster

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container == null:
		container = caster.get_parent()
	container.add_child(mine, true)
	mine.global_position = caster.global_position
