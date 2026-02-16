extends Node

static func _create_bomb_core(color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 10
	particles.lifetime = 0.2
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
	grad.set_color(0, Color(1.0, 0.9, 0.7, 0.9))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.3))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_shockwave_ring(radius: float, color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 30
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_radius = radius
	material.emission_ring_inner_radius = radius * 0.9
	material.emission_ring_height = 0.0
	material.spread = 30.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3.ZERO
	material.scale_min = 3.0
	material.scale_max = 6.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.7, 0.3, 0.9))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_smoke_trail() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 30
	particles.lifetime = 0.5
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0
	material.spread = 45.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 25.0
	material.gravity = Vector3(0, -30, 0)
	material.scale_min = 3.0
	material.scale_max = 6.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(0.5, 0.5, 0.5, 0.6))
	grad.set_color(1, Color(0.3, 0.3, 0.3, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(0.5, 0.5, 0.5)

	particles.process_material = material
	return particles

static func _create_explosion_particles(caster: Node2D, position: Vector2, radius: float, color: Color) -> void:
	var fire = GPUParticles2D.new()
	fire.amount = 40
	fire.lifetime = 0.5
	fire.one_shot = true
	fire.explosiveness = 1.0
	fire.emitting = true

	var fire_mat = ParticleProcessMaterial.new()
	fire_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fire_mat.emission_sphere_radius = radius * 0.3
	fire_mat.spread = 180.0
	fire_mat.initial_velocity_min = 80.0
	fire_mat.initial_velocity_max = 150.0
	fire_mat.gravity = Vector3(0, 50, 0)
	fire_mat.scale_min = 4.0
	fire_mat.scale_max = 10.0

	var fire_gradient = GradientTexture1D.new()
	var fire_grad = Gradient.new()
	fire_grad.set_color(0, Color(1.0, 0.9, 0.3, 1.0))
	fire_grad.add_point(0.3, Color(1.0, 0.5, 0.1, 0.9))
	fire_grad.set_color(1, Color(0.8, 0.2, 0.0, 0.0))
	fire_gradient.gradient = fire_grad
	fire_mat.color_ramp = fire_gradient
	fire_mat.color = Color(1.0, 0.6, 0.2)

	fire.process_material = fire_mat
	fire.global_position = position
	caster.get_parent().add_child(fire)

	var smoke = GPUParticles2D.new()
	smoke.amount = 25
	smoke.lifetime = 0.8
	smoke.one_shot = true
	smoke.explosiveness = 0.8
	smoke.emitting = true

	var smoke_mat = ParticleProcessMaterial.new()
	smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	smoke_mat.emission_ring_radius = radius * 0.5
	smoke_mat.emission_ring_inner_radius = radius * 0.2
	smoke_mat.emission_ring_height = 0.0
	smoke_mat.spread = 180.0
	smoke_mat.initial_velocity_min = 40.0
	smoke_mat.initial_velocity_max = 80.0
	smoke_mat.gravity = Vector3(0, -40, 0)
	smoke_mat.scale_min = 8.0
	smoke_mat.scale_max = 15.0

	var smoke_gradient = GradientTexture1D.new()
	var smoke_grad = Gradient.new()
	smoke_grad.set_color(0, Color(0.3, 0.3, 0.3, 0.7))
	smoke_grad.set_color(1, Color(0.2, 0.2, 0.2, 0.0))
	smoke_gradient.gradient = smoke_grad
	smoke_mat.color_ramp = smoke_gradient
	smoke_mat.color = Color(0.4, 0.4, 0.4)

	smoke.process_material = smoke_mat
	smoke.global_position = position
	caster.get_parent().add_child(smoke)

	caster.get_tree().create_timer(1.2).timeout.connect(fire.queue_free)
	caster.get_tree().create_timer(1.2).timeout.connect(smoke.queue_free)

static func execute(caster: Node2D, data: AbilityData) -> void:
	var mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var distance = caster.global_position.distance_to(mouse_pos)

	if distance > data.range_distance:
		distance = data.range_distance

	var target_pos = caster.global_position + direction * distance

	var projectile = Area2D.new()
	projectile.add_to_group("projectile")
	projectile.collision_layer = 0
	projectile.collision_mask = 2

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	projectile.add_child(collision)

	projectile.global_position = caster.global_position
	caster.get_parent().add_child(projectile)

	var core = _create_bomb_core(data.indicator_color)
	projectile.add_child(core)

	var trail = _create_smoke_trail()
	projectile.add_child(trail)

	var travel_time = distance / 400.0

	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)
	var scaled_radius = GameState.get_scaled_radius(data.radius, data.radius_scale_percent)

	var tween = caster.create_tween()
	tween.tween_property(projectile, "global_position", target_pos, travel_time)
	tween.tween_callback(_explode.bind(projectile, caster, data, scaled_damage, scaled_radius))

static func _explode(projectile: Area2D, caster: Node2D, data: AbilityData, scaled_damage: int, scaled_radius: float) -> void:
	var explosion_pos = projectile.global_position
	projectile.queue_free()

	_create_explosion_particles(caster, explosion_pos, scaled_radius, data.indicator_color)

	var shockwave = _create_shockwave_ring(scaled_radius, data.indicator_color)
	shockwave.global_position = explosion_pos
	caster.get_parent().add_child(shockwave)
	caster.get_tree().create_timer(0.6).timeout.connect(shockwave.queue_free)

	var explosion = Area2D.new()
	explosion.add_to_group("explosion")
	explosion.collision_layer = 0
	explosion.collision_mask = 2

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = scaled_radius
	collision.shape = shape
	explosion.add_child(collision)

	explosion.global_position = explosion_pos
	caster.get_parent().add_child(explosion)

	var damaged_targets = []

	explosion.area_entered.connect(func(area):
		var parent = area.get_parent()
		if parent and parent.has_method("take_damage") and parent != caster and parent not in damaged_targets:
			damaged_targets.append(parent)
			parent.take_damage(scaled_damage, caster)
	)

	explosion.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != caster and body not in damaged_targets:
			damaged_targets.append(body)
			body.take_damage(scaled_damage, caster)
	)

	await caster.get_tree().process_frame

	for area in explosion.get_overlapping_areas():
		var parent = area.get_parent()
		if parent and parent.has_method("take_damage") and parent != caster and parent not in damaged_targets:
			damaged_targets.append(parent)
			parent.take_damage(scaled_damage, caster)

	for body in explosion.get_overlapping_bodies():
		if body.has_method("take_damage") and body != caster and body not in damaged_targets:
			damaged_targets.append(body)
			body.take_damage(scaled_damage, caster)

	await caster.get_tree().create_timer(0.2).timeout
	explosion.queue_free()
