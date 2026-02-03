extends Node

static func _create_projectile_core(color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 10
	particles.lifetime = 0.15
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 2.0
	material.spread = 180.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3.ZERO
	material.scale_min = 8.0
	material.scale_max = 12.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.9))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.3))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_trail_particles(color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.4
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 4.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_impact_particles(caster: Node2D, position: Vector2, color: Color) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 15
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.spread = 180.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 5.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	particles.global_position = position
	caster.get_parent().add_child(particles)

	caster.get_tree().create_timer(0.6).timeout.connect(particles.queue_free)

static func execute(caster: Node2D, data: AbilityData) -> void:
	var base_direction = caster.aim_direction
	var half_spread = deg_to_rad(data.spread_angle / 2.0)
	var projectile_count = data.projectile_count + GameState.get_bonus_projectiles(data.projectile_bonus_levels)
	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)

	for i in range(projectile_count):
		var angle_offset: float
		if projectile_count == 1:
			angle_offset = 0.0
		else:
			angle_offset = lerp(-half_spread, half_spread, float(i) / float(projectile_count - 1))

		var shoot_direction = base_direction.rotated(angle_offset)
		_spawn_projectile(caster, data, shoot_direction, scaled_damage)

static func _spawn_projectile(caster: Node2D, data: AbilityData, direction: Vector2, scaled_damage: int) -> void:
	var projectile = Area2D.new()
	projectile.add_to_group("projectile")
	projectile.collision_layer = 0
	projectile.collision_mask = 2

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 7
	collision.shape = shape
	projectile.add_child(collision)

	projectile.global_position = caster.global_position
	caster.get_parent().add_child(projectile)

	var core = _create_projectile_core(data.indicator_color)
	projectile.add_child(core)

	var trail = _create_trail_particles(data.indicator_color)
	projectile.add_child(trail)

	projectile.area_entered.connect(func(area):
		var target = area.get_parent()
		if target and target != caster and target.has_method("take_damage"):
			target.take_damage(scaled_damage, caster)
			if target.has_method("apply_slow"):
				target.apply_slow("ice_blast", 5.0, 3.0)
			_create_impact_particles(caster, projectile.global_position, data.indicator_color)
			projectile.queue_free()
	)

	projectile.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != caster:
			body.take_damage(scaled_damage, caster)
			if body.has_method("apply_slow"):
				body.apply_slow("ice_blast", 5.0, 3.0)
			_create_impact_particles(caster, projectile.global_position, data.indicator_color)
			projectile.queue_free()
	)

	var travel_time = data.range_distance / 500.0

	var tween = caster.create_tween()
	tween.tween_property(projectile, "global_position",
		projectile.global_position + direction * data.range_distance, travel_time)
	tween.tween_callback(projectile.queue_free)
