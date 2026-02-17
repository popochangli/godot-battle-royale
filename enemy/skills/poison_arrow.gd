extends Node

const PoisonArrowScene = preload("res://effects/enemy/enemy_poison_arrow.tscn")

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	var player = caster.get_tree().get_first_node_in_group("player")
	if not player:
		return

	var arrow = PoisonArrowScene.instantiate()
	arrow.direction = (player.global_position - caster.global_position).normalized()
	arrow.locked_target = player
	arrow.damage = data.damage
	arrow.effect_color = data.effect_color
	caster.get_parent().add_child(arrow)
	arrow.global_position = caster.global_position
