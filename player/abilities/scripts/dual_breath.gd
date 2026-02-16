extends Node

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	
	_spawn_breath_wave(caster, data, direction, "fire")
	
	caster.get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(caster):
			var new_mouse_pos = caster.get_global_mouse_position()
			var new_direction = (new_mouse_pos - caster.global_position).normalized()
			_spawn_breath_wave(caster, data, new_direction, "ice")
	)

static func _spawn_breath_wave(caster: Node2D, data: AbilityData, direction: Vector2, type: String) -> void:
	var projectile = Area2D.new()
	projectile.add_to_group("projectile")
	projectile.collision_layer = 0
	projectile.collision_mask = 2

	var sprite = Polygon2D.new()
	if type == "fire":
		sprite.color = Color(1.0, 0.4, 0.0, 0.8)
	else:
		sprite.color = Color(0.4, 0.8, 1.0, 0.8)
		
	sprite.polygon = PackedVector2Array([Vector2(0, -10), Vector2(20, 0), Vector2(0, 10), Vector2(-10, 0)])
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	collision.shape = shape
	projectile.add_child(collision)
	
	projectile.global_position = caster.global_position
	projectile.rotation = direction.angle()
	caster.get_parent().add_child(projectile)
	
	var speed = 400.0
	var range_dist = data.range_distance
	var travel_time = range_dist / speed
	var damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)
	
	var tween = caster.create_tween()
	tween.tween_property(projectile, "global_position", caster.global_position + direction * range_dist, travel_time)
	tween.tween_callback(projectile.queue_free)
	
	projectile.body_entered.connect(func(body):
		if body != caster and body.has_method("take_damage"):
			body.take_damage(damage, caster)
			
			if type == "fire":
				if body.has_method("apply_burn"):
					body.apply_burn("dual_breath", int(damage * 0.5), 3.0, caster)
			else:
				if body.has_method("apply_slow"):
					body.apply_slow("dual_breath", 30.0, 3.0)
	)
