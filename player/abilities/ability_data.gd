class_name AbilityData
extends Resource

@export var ability_id: String = ""
@export var display_name: String = ""
@export var cooldown: float = 1.0
@export var damage: int = 10
@export var indicator_color: Color = Color.WHITE
@export var ability_script: GDScript

@export var radius: float = 60.0
@export var range_distance: float = 1000.0
@export var projectile_count: int = 1
@export var spread_angle: float = 0.0
@export var freeze_duration: float = 0.0

@export_group("Level Scaling")
@export var damage_scale_percent: float = 0.0
@export var cooldown_scale_percent: float = 0.0
@export var radius_scale_percent: float = 0.0
@export var duration_scale_percent: float = 0.0
@export var projectile_bonus_levels: Array[int] = []
