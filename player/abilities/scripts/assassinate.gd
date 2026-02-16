extends Node

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	
	var projectile = Area2D.new()
	projectile.add_to_group("projectile")
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision.shape = shape
	projectile.add_child(collision)
	
	var line = Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(-20, 0)])
	line.width = 4.0
	line.default_color = Color(1.0, 0.8, 0.2)
	projectile.add_child(line)
	
	projectile.global_position = caster.global_position
	projectile.rotation = direction.angle()
	caster.get_parent().add_child(projectile)
	
	var damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)
	var speed = 1500.0
	var range_dist = data.range_distance
	var duration = range_dist / speed
	
	var tween = caster.create_tween()
	var target_pos = caster.global_position + direction * range_dist
	
	tween.tween_property(projectile, "global_position", target_pos, duration)
	tween.tween_callback(projectile.queue_free)
	
	projectile.body_entered.connect(func(body):
		if body != caster and body.has_method("take_damage"):
			body.take_damage(damage * 3, caster)
			projectile.queue_free()
	)
