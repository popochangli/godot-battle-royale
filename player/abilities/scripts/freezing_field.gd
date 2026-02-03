extends Node

static func _create_ground_frost(radius: float, color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 40
	particles.lifetime = 0.5
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = radius * 0.8
	material.spread = 180.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 10.0
	material.gravity = Vector3.ZERO
	material.scale_min = 6.0
	material.scale_max = 12.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(0.7, 0.9, 1.0, 0.6))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.2))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(0.8, 0.95, 1.0)

	particles.process_material = material
	return particles

static func _create_swirling_ice(radius: float, color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 60
	particles.lifetime = 1.0
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_radius = radius
	material.emission_ring_inner_radius = radius * 0.7
	material.emission_ring_height = 0.0
	material.spread = 10.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.orbit_velocity_min = 0.5
	material.orbit_velocity_max = 1.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 5.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 0.9))
	grad.add_point(0.5, Color(0.8, 0.95, 1.0, 0.7))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_inner_sparkles(radius: float) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.8
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = radius * 0.6
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3(0, 20, 0)
	material.scale_min = 1.0
	material.scale_max = 3.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.8))
	grad.set_color(1, Color(0.9, 0.95, 1.0, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(1.0, 1.0, 1.0)

	particles.process_material = material
	return particles

static func execute(caster: Node2D, data: AbilityData) -> void:
	const SLOW_PER_SECOND = 25.0

	var scaled_radius = GameState.get_scaled_radius(data.radius, data.radius_scale_percent)
	var scaled_duration = GameState.get_scaled_duration(data.freeze_duration, data.duration_scale_percent)
	var field_duration = 5.0 + scaled_duration
	var slow_duration = 1.5 + scaled_duration * 0.5

	var freeze_area = Area2D.new()
	freeze_area.collision_layer = 0
	freeze_area.collision_mask = 2
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = scaled_radius
	collision.shape = shape
	freeze_area.add_child(collision)
	caster.add_child(freeze_area)

	var frost = _create_ground_frost(scaled_radius, data.indicator_color)
	freeze_area.add_child(frost)

	var swirl = _create_swirling_ice(scaled_radius, data.indicator_color)
	freeze_area.add_child(swirl)

	var sparkles = _create_inner_sparkles(scaled_radius)
	freeze_area.add_child(sparkles)

	var enemies_in_field: Dictionary = {}

	freeze_area.area_entered.connect(func(area):
		var parent = area.get_parent()
		if parent and parent.has_method("add_slow") and parent != caster:
			enemies_in_field[parent] = true
	)

	freeze_area.area_exited.connect(func(area):
		var parent = area.get_parent()
		if parent in enemies_in_field:
			enemies_in_field.erase(parent)
	)

	freeze_area.body_entered.connect(func(body):
		if body.has_method("add_slow") and body != caster:
			enemies_in_field[body] = true
	)

	freeze_area.body_exited.connect(func(body):
		if body in enemies_in_field:
			enemies_in_field.erase(body)
	)

	var process_callback = func():
		if not is_instance_valid(caster):
			return
		var delta = caster.get_process_delta_time()
		var slow_amount = SLOW_PER_SECOND * delta
		for enemy in enemies_in_field.keys():
			if is_instance_valid(enemy):
				enemy.add_slow("freezing_field", slow_amount, slow_duration)

	caster.get_tree().process_frame.connect(process_callback)

	caster.get_tree().create_timer(field_duration).timeout.connect(func():
		if caster.get_tree().process_frame.is_connected(process_callback):
			caster.get_tree().process_frame.disconnect(process_callback)
		if is_instance_valid(freeze_area):
			freeze_area.queue_free()
	)
