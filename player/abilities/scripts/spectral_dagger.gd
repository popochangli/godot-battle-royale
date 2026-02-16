extends Node

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var range_dist = data.range_distance
	
	var area = Area2D.new()
	area.monitorable = false
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2 
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(range_dist, range_dist) 
	collision.shape = shape
	collision.position = Vector2(range_dist / 2.0, 0)
	area.add_child(collision)
	
	var slash = Polygon2D.new()
	slash.polygon = PackedVector2Array([
		Vector2(0, -10), 
		Vector2(range_dist, -range_dist/2.0), 
		Vector2(range_dist, range_dist/2.0), 
		Vector2(0, 10)
	])
	slash.color = Color(0.8, 0.0, 0.8, 0.6) 
	area.add_child(slash)
	
	area.global_position = caster.global_position
	area.rotation = direction.angle()
	caster.get_parent().add_child(area)
	
	await caster.get_tree().physics_frame
	await caster.get_tree().physics_frame
	
	var damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body != caster and body.has_method("take_damage"):
			body.take_damage(damage, caster)
			
	var tween = caster.create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(area.queue_free)
