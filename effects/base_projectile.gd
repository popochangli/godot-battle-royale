class_name BaseProjectile
extends Area2D

@export var speed: float = 300.0
@export var max_range: float = 800.0
@export var max_lifetime: float = 3.0
@export var damage: int = 20
@export var effect_color: Color = Color.WHITE

var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _spawn_position: Vector2
var _hit: bool = false
var _spawn_ready: bool = false

func _ready():
	_setup_visuals()

func _physics_process(delta):
	if not _spawn_ready:
		_spawn_ready = true
		_spawn_position = global_position
		_on_spawned()
		return

	if _hit:
		return

	_lifetime += delta
	if _lifetime > max_lifetime or global_position.distance_to(_spawn_position) > max_range:
		queue_free()
		return

	_check_hit(delta)

	if not _hit:
		global_position += direction * speed * delta

func _setup_visuals() -> void:
	pass

func _on_spawned() -> void:
	pass

func _check_hit(_delta: float) -> void:
	pass

func _on_hit(_target: Node2D) -> void:
	pass
