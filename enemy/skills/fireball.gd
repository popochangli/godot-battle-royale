extends Node

const FireballScene = preload("res://effects/enemy/enemy_fireball.tscn")

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	var player = caster.get_tree().get_first_node_in_group("player")
	if not player:
		return

	var direction = (player.global_position - caster.global_position).normalized()

	var fireball = FireballScene.instantiate()
	fireball.direction = direction
	fireball.damage = data.damage
	fireball.effect_color = data.effect_color
	caster.get_parent().add_child(fireball)
	fireball.global_position = caster.global_position
