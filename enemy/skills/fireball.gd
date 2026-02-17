extends Node

const FireballScene = preload("res://effects/enemy/enemy_fireball.tscn")

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	var player = _find_nearest_player(caster)
	if not player:
		return

	var direction = (player.global_position - caster.global_position).normalized()

	var fireball = FireballScene.instantiate()
	fireball.direction = direction
	fireball.damage = data.damage
	fireball.effect_color = data.effect_color
	var effects = caster.get_tree().get_first_node_in_group("effects_container")
	if effects:
		effects.add_child(fireball, true)
	else:
		caster.get_parent().add_child(fireball, true)
	fireball.global_position = caster.global_position

static func _find_nearest_player(caster: Node2D) -> Node2D:
	var nearest = null
	var min_dist = INF
	for p in caster.get_tree().get_nodes_in_group("player"):
		if p.get("health") and p.health <= 0:
			continue
		var d = caster.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	return nearest
