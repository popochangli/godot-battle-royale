extends Node

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var distance = caster.global_position.distance_to(mouse_pos)

	if distance > data.range_distance:
		distance = data.range_distance
		mouse_pos = caster.global_position + (mouse_pos - caster.global_position).normalized() * distance

	var projectile = Area2D.new()
	projectile.add_to_group("projectile")
	
	var sprite = Polygon2D.new()
	sprite.polygon = PackedVector2Array([Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)])
	sprite.color = Color(0.3, 0.3, 0.3) 
	projectile.add_child(sprite)

	projectile.global_position = caster.global_position
	caster.get_parent().add_child(projectile)

	var tween = caster.create_tween()
	var travel_time = distance / 600.0
	
	tween.tween_property(projectile, "global_position", mouse_pos, travel_time)
	tween.tween_callback(func(): _detonate_shrapnel(caster, projectile, data))

static func _detonate_shrapnel(caster: Node2D, projectile: Area2D, data: AbilityData):
	var pos = projectile.global_position
	projectile.queue_free()
	
	var area = Area2D.new()
	area.monitorable = false
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2 
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	var radius = data.radius
	if radius <= 0: radius = 100.0
	
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
	caster.get_parent().add_child(area)
	
	var damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)
	
	area.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != caster:
			body.take_damage(damage, caster)
	)
	
	await caster.get_tree().physics_frame
	await caster.get_tree().physics_frame
	
	await caster.get_tree().create_timer(0.2).timeout
	area.queue_free()
