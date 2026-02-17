extends HomingProjectile

@export var hit_radius: float = 20.0

var trail_color: Color = Color.RED

func _setup_visuals() -> void:
	collision_layer = 0
	collision_mask = 0

	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)

	var sprite = Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	sprite.scale = Vector2(6, 8)
	sprite.modulate = trail_color
	add_child(sprite)

	var particles = _create_projectile_trail()
	add_child(particles)

func _check_hit(_delta: float) -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	var target = _get_target()
	if not target:
		return

	var dist = global_position.distance_to(target.global_position)
	if dist < hit_radius:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		_hit = true
		queue_free()

func _create_projectile_trail() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 0.3
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 2.0
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 4.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.8))
	grad.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = trail_color

	particles.process_material = material
	return particles
