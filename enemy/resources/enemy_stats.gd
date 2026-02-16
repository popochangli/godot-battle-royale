class_name EnemyStats
extends Resource

@export var max_health: int = 100
@export var speed: float = 150.0
@export var damage: int = 10
@export var attack_range: float = 50.0  # 50 = melee, 150+ = ranged
@export var attack_cooldown: float = 1.0
@export var xp_value: int = 25
@export var sprite_scale: float = 1.0
@export var color_tint: Color = Color.RED

# 8-direction sprites: south, south-east, east, north-east, north, north-west, west, south-west
@export var direction_sprites: Array[Texture2D] = []
