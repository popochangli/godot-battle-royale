class_name EnemySkillData
extends Resource

@export var skill_id: String = ""
@export var skill_name: String = ""
@export var cooldown: float = 8.0
@export var damage: int = 20
@export var effect_color: Color = Color.WHITE
@export var skill_script: GDScript  # Points to static execute() script

# Skill-specific parameters
@export var radius: float = 100.0  # For AoE skills like ground_slam
@export var range: float = 200.0   # For projectile skills like fireball/poison_arrow
