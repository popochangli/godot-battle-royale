extends BaseProjectile

@export var hit_radius: float = 30.0

func _setup_visuals() -> void:
	collision_layer = 0
	collision_mask = 0

	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)

	var core = Sprite2D.new()
	core.texture = tex
	core.centered = true
	core.scale = Vector2(8, 8)
	core.modulate = Color(1.0, 0.9, 0.5, 1.0)
	core.rotation = direction.angle()
	add_child(core)

	var glow = Sprite2D.new()
	glow.texture = tex
	glow.centered = true
	glow.scale = Vector2(14, 14)
	glow.modulate = Color(effect_color.r, effect_color.g, effect_color.b, 0.5)
	glow.rotation = direction.angle()
	add_child(glow)

	var particles = _create_fire_particles()
	add_child(particles)

func _check_hit(_delta: float) -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and global_position.distance_to(p.global_position) < hit_radius:
			p.take_damage(damage)
			_hit = true
			_spawn_explosion()
			queue_free()
			return

func _create_fire_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 15
	particles.lifetime = 0.3
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0
	material.spread = 180.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 25.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 5.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 1.0))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _spawn_explosion() -> void:
	var parent = get_parent()
	if not parent:
		return

	var particles = GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0
	material.spread = 180.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3.ZERO
	material.scale_min = 4.0
	material.scale_max = 8.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 1.0))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	particles.global_position = global_position
	parent.add_child(particles)

	var p_ref = weakref(particles)
	get_tree().create_timer(0.6).timeout.connect(func():
		if p_ref.get_ref():
			p_ref.get_ref().queue_free()
	)
