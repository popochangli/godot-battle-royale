extends HomingProjectile

@export var hit_radius: float = 28.0

func _setup_visuals() -> void:
	collision_layer = 0
	collision_mask = 0

	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)

	var core = Sprite2D.new()
	core.texture = tex
	core.centered = true
	core.scale = Vector2(6, 10)
	core.modulate = Color(0.8, 1.0, 0.6, 1.0)
	add_child(core)

	var glow = Sprite2D.new()
	glow.texture = tex
	glow.centered = true
	glow.scale = Vector2(12, 12)
	glow.modulate = Color(effect_color.r, effect_color.g, effect_color.b, 0.4)
	add_child(glow)

	var particles = _create_poison_trail()
	add_child(particles)

func _check_hit(_delta: float) -> void:
	var target = _target_ref.get_ref() if _target_ref else null
	if not target:
		return

	var dist = global_position.distance_to(target.global_position)
	if dist < hit_radius:
		target.take_damage(damage)
		_hit = true
		_apply_poison_dot(target)
		_create_poison_cloud()
		queue_free()

func _apply_poison_dot(player: Node) -> void:
	var dot_damage_per_sec = 3
	var tick_interval = 1.0
	var state = { "ticks": 4, "tick_fn": Callable() }

	var tree = player.get_tree()
	if not tree:
		return

	var player_ref = weakref(player)
	state["tick_fn"] = func():
		var p = player_ref.get_ref()
		if not p or not is_instance_valid(p):
			return
		p.take_damage(dot_damage_per_sec)
		state["ticks"] -= 1
		if state["ticks"] > 0:
			var t = p.get_tree()
			if t:
				t.create_timer(tick_interval).timeout.connect(state["tick_fn"])

	tree.create_timer(tick_interval).timeout.connect(state["tick_fn"])

func _create_poison_trail() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.4
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
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 0.8))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_poison_cloud() -> void:
	var parent = get_parent()
	if not parent:
		return

	var particles = GPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 8.0
	material.spread = 180.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 30.0
	material.gravity = Vector3(0, -15, 0)
	material.scale_min = 2.0
	material.scale_max = 5.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 0.6))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	particles.global_position = global_position
	parent.add_child(particles)

	var p_ref = weakref(particles)
	get_tree().create_timer(0.8).timeout.connect(func():
		var p = p_ref.get_ref()
		if p:
			p.queue_free()
	)
