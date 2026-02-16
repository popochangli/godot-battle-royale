extends Node

const MAX_MINES_PER_PLAYER = 3

static func _create_mine_core(color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 0.3
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.spread = 180.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 2.0
	material.gravity = Vector3.ZERO
	material.scale_min = 10.0
	material.scale_max = 15.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.9, 0.7, 0.8))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.4))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_explosion_ring(radius: float, color: Color) -> GPUParticles2D:
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
	grad.set_color(0, Color(1.0, 0.6, 0.2, 0.9))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_pulse_glow(color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 1.5
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.spread = 180.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 3.0
	material.gravity = Vector3.ZERO
	material.scale_min = 15.0
	material.scale_max = 25.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 0.0))
	grad.add_point(0.25, Color(color.r, color.g, color.b, 0.5))
	grad.add_point(0.5, Color(color.r, color.g, color.b, 0.5))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_spark_particles(color: Color) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 3
	particles.lifetime = 0.6
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.spread = 60.0
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 15.0
	material.initial_velocity_max = 30.0
	material.gravity = Vector3(0, 80, 0)
	material.scale_min = 1.0
	material.scale_max = 2.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.7, 0.2, 1.0))
	grad.set_color(1, Color(1.0, 0.4, 0.1, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(1.0, 0.6, 0.2)

	particles.process_material = material
	return particles

static func _create_mine_explosion(caster: Node2D, position: Vector2, radius: float) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 35
	particles.lifetime = 0.35
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = radius * 0.2
	material.spread = 180.0
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, 40, 0)
	material.scale_min = 3.0
	material.scale_max = 8.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
	grad.add_point(0.3, Color(1.0, 0.4, 0.1, 0.9))
	grad.set_color(1, Color(0.9, 0.2, 0.0, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(1.0, 0.5, 0.2)

	particles.process_material = material
	particles.global_position = position
	caster.get_parent().add_child(particles)

	caster.get_tree().create_timer(0.7).timeout.connect(particles.queue_free)

static func execute(caster: Node2D, data: AbilityData) -> void:
	var owner_id = caster.get_instance_id()

	var existing_mines = caster.get_tree().get_nodes_in_group("techies_mines")
	var player_mines = []
	for mine in existing_mines:
		if mine.has_meta("owner_id") and mine.get_meta("owner_id") == owner_id:
			player_mines.append(mine)

	while player_mines.size() >= MAX_MINES_PER_PLAYER:
		var oldest_mine = player_mines.pop_front()
		if is_instance_valid(oldest_mine):
			oldest_mine.queue_free()

	var scaled_damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent)

	var mine = Area2D.new()
	mine.add_to_group("techies_mines")
	mine.collision_layer = 0
	mine.collision_mask = 2
	mine.set_meta("owner_id", owner_id)
	mine.set_meta("scaled_damage", scaled_damage)

	var core = _create_mine_core(data.indicator_color)
	mine.add_child(core)

	var pulse = _create_pulse_glow(data.indicator_color)
	mine.add_child(pulse)

	var sparks = _create_spark_particles(data.indicator_color)
	mine.add_child(sparks)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = data.radius
	collision.shape = shape
	mine.add_child(collision)

	mine.global_position = caster.global_position
	caster.get_parent().add_child(mine)

	mine.area_entered.connect(func(area):
		var parent = area.get_parent()
		if parent and parent.has_method("take_damage") and parent != caster:
			_detonate_mine(mine, caster, data)
	)

	mine.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != caster:
			_detonate_mine(mine, caster, data)
	)

static func _detonate_mine(mine: Area2D, caster: Node2D, data: AbilityData) -> void:
	if not is_instance_valid(mine):
		return

	var explosion_pos = mine.global_position
	var scaled_damage = mine.get_meta("scaled_damage", data.damage)
	mine.queue_free()

	_do_explosion.call_deferred(caster, data, explosion_pos, scaled_damage)

static func _do_explosion(caster: Node2D, data: AbilityData, explosion_pos: Vector2, scaled_damage: int) -> void:
	if not is_instance_valid(caster):
		return

	var explosion_radius = data.radius * 1.5

	_create_mine_explosion(caster, explosion_pos, explosion_radius)

	var ring = _create_explosion_ring(explosion_radius, data.indicator_color)
	ring.global_position = explosion_pos
	caster.get_parent().add_child(ring)
	caster.get_tree().create_timer(0.6).timeout.connect(ring.queue_free)

	var explosion = Area2D.new()
	explosion.add_to_group("explosion")
	explosion.collision_layer = 0
	explosion.collision_mask = 2

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
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

	await caster.get_tree().create_timer(0.3).timeout
	explosion.queue_free()
