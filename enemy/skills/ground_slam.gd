extends Node

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	# Create impact particles at caster position
	_create_impact_particles(caster, data.effect_color)

	# Spawn traveling wave
	_spawn_wave(caster, data)

static func _get_body_radius(body: Node2D) -> float:
	for child in body.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			return child.shape.radius
	return 16.0  # fallback

static func _spawn_wave(caster: Node2D, data: EnemySkillData) -> void:
	var wave = Node2D.new()

	# Create circular texture
	var circle_size = 64
	var img = Image.create(circle_size, circle_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(circle_size / 2.0, circle_size / 2.0)
	var tex_radius = circle_size / 2.0
	for x in range(circle_size):
		for y in range(circle_size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= tex_radius:
				var alpha = 1.0 - (dist / tex_radius) * 0.5
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	var sprite = Sprite2D.new()
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.centered = true
	var initial_visual_scale = 20.0 / circle_size
	sprite.scale = Vector2(initial_visual_scale, initial_visual_scale)
	sprite.modulate = Color(data.effect_color.r, data.effect_color.g, data.effect_color.b, 0.7)
	wave.add_child(sprite)

	# Shared mutable state via Dictionary
	var state = {"current_radius": 10.0, "hit_bodies": []}

	# ADD TO SCENE, THEN SET POSITION
	caster.get_parent().add_child(wave)
	wave.global_position = caster.global_position
	var wave_center = caster.global_position

	# Use weakrefs to avoid "Lambda capture was freed" errors
	var caster_ref = weakref(caster)
	var wave_ref = weakref(wave)

	# Clean up wave if caster dies
	caster.tree_exiting.connect(func():
		var w = wave_ref.get_ref()
		if w:
			w.queue_free()
	)

	# Casting state - enemy stops moving
	var expand_time = data.radius / 120.0  # Slower expansion
	var prev_state = -1
	if "current_state" in caster:
		prev_state = caster.current_state
		caster.current_state = caster.State.CASTING

	# Hit detection via physics_frame signal
	var tree = wave.get_tree()
	var on_physics_frame: Callable

	on_physics_frame = func():
		var w = wave_ref.get_ref()
		if not w:
			if tree:
				tree.physics_frame.disconnect(on_physics_frame)
			return

		# Check ALL players in the group
		var players = tree.get_nodes_in_group("player")
		for player in players:
			if not is_instance_valid(player):
				continue
			if player in state.hit_bodies:
				continue

			var body_radius = _get_body_radius(player)
			var dist_to_player = wave_center.distance_to(player.global_position)

			if dist_to_player < state.current_radius + body_radius:
				if player.has_method("take_damage"):
					player.take_damage(data.damage)
				state.hit_bodies.append(player)

	tree.physics_frame.connect(on_physics_frame)

	# Disconnect when wave is freed
	wave.tree_exiting.connect(func():
		if tree and on_physics_frame.is_valid():
			tree.physics_frame.disconnect(on_physics_frame)
	)

	# Expand wave over time
	var tween = wave.create_tween()
	tween.set_parallel(true)

	# Expand radius tracking
	tween.tween_method(func(value: float): state.current_radius = value, 10.0, data.radius, expand_time)

	# Expand visual sprite to match radius
	var final_visual_scale = (data.radius * 2.0) / circle_size
	tween.tween_property(sprite, "scale", Vector2(final_visual_scale, final_visual_scale), expand_time)

	# Fade out
	tween.tween_property(sprite, "modulate:a", 0.0, expand_time)

	# Cleanup - restore previous state and free wave
	tween.chain().tween_callback(func():
		var c = caster_ref.get_ref()
		if c and "current_state" in c:
			c.current_state = c.State.PURSUING if prev_state == c.State.PURSUING else c.State.IDLE
		var w = wave_ref.get_ref()
		if w:
			w.queue_free()
	)

static func _create_shockwave(caster: Node2D, radius: float, color: Color) -> void:
	# Create expanding ring effect
	var particles = GPUParticles2D.new()
	particles.amount = 30
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_radius = radius * 0.5
	material.emission_ring_inner_radius = radius * 0.3
	material.emission_ring_height = 0.0
	material.spread = 30.0
	material.initial_velocity_min = radius * 0.5
	material.initial_velocity_max = radius * 1.0
	material.gravity = Vector3.ZERO
	material.scale_min = 4.0
	material.scale_max = 8.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 0.8))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	particles.global_position = caster.global_position
	caster.get_parent().add_child(particles)

	var p_ref = weakref(particles)
	caster.get_tree().create_timer(0.7).timeout.connect(func():
		var p = p_ref.get_ref()
		if p:
			p.queue_free()
	)

static func _create_impact_particles(caster: Node2D, color: Color) -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 25
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 15.0
	material.spread = 180.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 3.0
	material.scale_max = 6.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	particles.global_position = caster.global_position
	caster.get_parent().add_child(particles)

	var p_ref = weakref(particles)
	caster.get_tree().create_timer(0.6).timeout.connect(func():
		var p = p_ref.get_ref()
		if p:
			p.queue_free()
	)
