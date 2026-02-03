extends Node2D

@export var enemy_count: int = 3
@export var spawn_radius: float = 50.0
@export var patrol_radius: float = 80.0
@export var leash_range: float = 300.0
@export var aggro_timeout: float = 8.0
@export var enemy_scene: PackedScene

func _ready():
	add_to_group("enemy_camp")
	if enemy_scene == null:
		enemy_scene = preload("res://enemy/enemy.tscn")
	_spawn_enemies()

func _spawn_enemies():
	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate()
		var angle = randf() * TAU
		var dist = randf() * spawn_radius
		var spawn_offset = Vector2(cos(angle), sin(angle)) * dist
		enemy.position = spawn_offset
		add_child(enemy)
		enemy.set_camp(self, global_position, patrol_radius, leash_range, aggro_timeout)
