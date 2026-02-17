extends BaseProjectile

var target_position: Vector2
var explosion_radius: float = 100.0
var caster: Node2D

func _ready():
	add_to_group("projectile")
	speed = 600.0

	var sprite = Polygon2D.new()
	sprite.polygon = PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)])
	sprite.color = Color(0.3, 0.3, 0.3)
	add_child(sprite)

func _on_spawned():
	direction = (target_position - global_position).normalized()
	max_range = global_position.distance_to(target_position) + 10.0

func _physics_process(delta):
	if not _spawn_ready:
		_spawn_ready = true
		_spawn_position = global_position
		_on_spawned()
		return

	if _hit:
		return

	_lifetime += delta
	if _lifetime > max_lifetime:
		queue_free()
		return

	var dist_to_target = global_position.distance_to(target_position)
	if dist_to_target < speed * delta:
		global_position = target_position
		_hit = true
		_detonate()
		return

	global_position += direction * speed * delta

func _detonate() -> void:
	var pos = global_position

	var area = Area2D.new()
	area.monitorable = false
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 3  # Layer 1 (Player) + 2 (Enemy)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	var radius = explosion_radius
	if radius <= 0:
		radius = 100.0
	shape.radius = radius
	collision.shape = shape
	area.add_child(collision)

	var polys = Polygon2D.new()
	var points = []
	for i in range(16):
		var angle = i * TAU / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	polys.polygon = PackedVector2Array(points)
	polys.color = Color(0.8, 0.2, 0.2, 0.4)
	area.add_child(polys)

	area.global_position = pos
	get_parent().add_child(area)

	var caster_ref = weakref(caster)

	area.body_entered.connect(func(body):
		var c = caster_ref.get_ref()
		if body.has_method("take_damage") and body != c:
			if multiplayer.multiplayer_peer == null or multiplayer.is_server():
				body.take_damage(damage, c)
	)

	await get_tree().physics_frame
	await get_tree().physics_frame

	await get_tree().create_timer(0.2).timeout
	area.queue_free()
	queue_free()
