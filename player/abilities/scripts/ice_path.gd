extends Node

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var distance = min(caster.global_position.distance_to(mouse_pos), data.range_distance)
	
	var area = Area2D.new()
	area.monitorable = false
	area.monitoring = true
	
	var line = Line2D.new()
	line.points = PackedVector2Array([Vector2.ZERO, Vector2(distance, 0)])
	line.width = 40.0
	line.default_color = Color(0.6, 0.9, 1.0, 0.5)
	area.add_child(line)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(distance, 40.0)
	collision.shape = shape
	collision.position = Vector2(distance / 2.0, 0)
	area.add_child(collision)
	
	area.global_position = caster.global_position
	area.rotation = direction.angle()
	caster.get_parent().add_child(area)
	
	var frozen_bodies = []
	
	var duration = 2.5
	var timer = 0.0
	
	var tween = caster.create_tween()
	tween.tween_method(func(val):
		_apply_effects(area, caster, frozen_bodies),
		0.0, 1.0, duration)
	tween.tween_callback(area.queue_free)

static func _apply_effects(area: Area2D, caster: Node2D, frozen_bodies: Array):
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		if body != caster:
			if not body in frozen_bodies:
				if body.has_method("apply_freeze"):
					body.apply_freeze(1.0)
				frozen_bodies.append(body)

			if body.has_method("apply_slow"):
				body.apply_slow("ice_path_slow", 50.0, 0.2)
