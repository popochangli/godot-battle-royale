extends Node

const GroundSlamScene = preload("res://effects/enemy/enemy_ground_slam.tscn")

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	var slam = GroundSlamScene.instantiate()
	slam.damage = data.damage
	slam.radius = data.radius
	slam.effect_color = data.effect_color
	slam.caster = caster
	caster.get_parent().add_child(slam)
	slam.global_position = caster.global_position
