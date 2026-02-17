class_name CampConfig
extends Resource

@export var camp_name: String = ""
@export var leader_skill: EnemySkillData
@export var leader_stats: EnemyStats
@export var minion_stats: EnemyStats
@export var camp_color: Color = Color.RED
@export var difficulty_tier: int = 1  # 1=Easy, 2=Medium, 3=Hard
