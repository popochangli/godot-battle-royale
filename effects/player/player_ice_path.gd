extends Area2D

@export var path_duration: float = 2.5

var path_direction: Vector2 = Vector2.RIGHT
var path_length: float = 200.0
var caster: Node2D

var _elapsed: float = 0.0
var _frozen_bodies: Array = []

func _ready():
	monitorable = false
	monitoring = true
	collision_layer = 0
	collision_mask = 3  # Layer 1 (Player) + 2 (Enemy)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(path_length, 40.0)
	collision.shape = shape
	collision.position = Vector2(path_length / 2.0, 0)
	add_child(collision)

	var line = Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(path_length, 0)])
	line.width = 40.0
	line.default_color = Color(0.6, 0.9, 1.0, 0.5)
	add_child(line)

	rotation = path_direction.angle()

func _physics_process(delta):
	_elapsed += delta
	if _elapsed >= path_duration:
		queue_free()
		return

	_apply_effects()

func _apply_effects() -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body != caster:
			if not body in _frozen_bodies:
				if body.has_method("apply_freeze"):
					body.apply_freeze(1.0)
				_frozen_bodies.append(body)

			if body.has_method("apply_slow"):
				body.apply_slow("ice_path_slow", 50.0, 0.2)
