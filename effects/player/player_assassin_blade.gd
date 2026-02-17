extends BaseProjectile

var caster: Node2D
var damage_multiplier: int = 3

func _ready():
	collision_layer = 0
	collision_mask = 3  # Layer 1 (Player) + 2 (Enemy)
	add_to_group("projectile")
	speed = 1500.0

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	add_child(collision)

	var line = Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(-20, 0)])
	line.width = 4.0
	line.default_color = Color(1.0, 0.8, 0.2)
	add_child(line)

	body_entered.connect(_on_body_entered)

func _on_spawned():
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body != caster and body.has_method("take_damage"):
		_hit = true
		monitoring = false
		if multiplayer.multiplayer_peer == null or multiplayer.is_server():
			body.take_damage(damage * damage_multiplier, caster)
		queue_free()
