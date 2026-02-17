extends BaseProjectile

var breath_type: String = "fire"
var caster: Node2D

func _ready():
	collision_layer = 0
	collision_mask = 2
	add_to_group("projectile")
	speed = 400.0

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	collision.shape = shape
	add_child(collision)

	var sprite = Polygon2D.new()
	if breath_type == "fire":
		sprite.color = Color(1.0, 0.4, 0.0, 0.8)
	else:
		sprite.color = Color(0.4, 0.8, 1.0, 0.8)
	sprite.polygon = PackedVector2Array([Vector2(0, -10), Vector2(20, 0), Vector2(0, 10), Vector2(-10, 0)])
	add_child(sprite)

	body_entered.connect(_on_body_entered)

func _on_spawned():
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body != caster and body.has_method("take_damage"):
		body.take_damage(damage, caster)

		if breath_type == "fire":
			if body.has_method("apply_burn"):
				body.apply_burn("dual_breath", int(damage * 0.5), 3.0, caster)
		else:
			if body.has_method("apply_slow"):
				body.apply_slow("dual_breath", 30.0, 3.0)
