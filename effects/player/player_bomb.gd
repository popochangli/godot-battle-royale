extends BaseProjectile

var target_position: Vector2
var explosion_radius: float = 100.0
var caster: Node2D

func _ready():
	collision_layer = 0
	collision_mask = 2
	add_to_group("projectile")

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	add_child(collision)

	speed = 400.0
	_setup_visuals()

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
		_explode()
		return

	global_position += direction * speed * delta

func _setup_visuals() -> void:
	var core = _create_bomb_core()
	add_child(core)
	var trail = _create_smoke_trail()
	add_child(trail)

func _explode() -> void:
	var explosion_pos = global_position
	var scaled_damage = damage
	var scaled_radius = explosion_radius

	_create_explosion_particles(explosion_pos, scaled_radius)

	var shockwave = _create_shockwave_ring(scaled_radius)
	shockwave.global_position = explosion_pos
	get_parent().add_child(shockwave)
	get_tree().create_timer(0.6).timeout.connect(shockwave.queue_free)

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
	get_parent().add_child(explosion)

	var damaged_targets = []
	var caster_ref = weakref(caster)

	explosion.area_entered.connect(func(area):
		var parent = area.get_parent()
		var c = caster_ref.get_ref()
		if parent and parent.has_method("take_damage") and parent != c and parent not in damaged_targets:
			damaged_targets.append(parent)
			if multiplayer.multiplayer_peer == null or multiplayer.is_server():
				parent.take_damage(scaled_damage, c)
	)

	explosion.body_entered.connect(func(body):
		var c = caster_ref.get_ref()
		if body.has_method("take_damage") and body != c and body not in damaged_targets:
			damaged_targets.append(body)
			if multiplayer.multiplayer_peer == null or multiplayer.is_server():
				body.take_damage(scaled_damage, c)
	)

	await get_tree().physics_frame
	await get_tree().physics_frame

	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		for area in explosion.get_overlapping_areas():
			var parent = area.get_parent()
			var c = caster_ref.get_ref()
			if parent and parent.has_method("take_damage") and parent != c and parent not in damaged_targets:
				damaged_targets.append(parent)
				parent.take_damage(scaled_damage, c)

		for body in explosion.get_overlapping_bodies():
			var c = caster_ref.get_ref()
			if body.has_method("take_damage") and body != c and body not in damaged_targets:
				damaged_targets.append(body)
				body.take_damage(scaled_damage, c)

	explosion.monitoring = false
	await get_tree().create_timer(0.2).timeout
	explosion.queue_free()
	queue_free()

func _create_bomb_core() -> GPUParticles2D:
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
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.3))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_smoke_trail() -> GPUParticles2D:
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

func _create_shockwave_ring(radius: float) -> GPUParticles2D:
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
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_explosion_particles(position: Vector2, radius: float) -> void:
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
	get_parent().add_child(fire)

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
	get_parent().add_child(smoke)

	get_tree().create_timer(1.2).timeout.connect(fire.queue_free)
	get_tree().create_timer(1.2).timeout.connect(smoke.queue_free)
