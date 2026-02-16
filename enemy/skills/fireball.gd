extends Node

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	var player = caster.get_tree().get_first_node_in_group("player")
	if not player:
		return

	var direction = (player.global_position - caster.global_position).normalized()
	_spawn_fireball(caster, direction, data)

static func _spawn_fireball(caster: Node2D, direction: Vector2, data: EnemySkillData) -> void:
	var projectile = Area2D.new()
	projectile.collision_layer = 0
	projectile.collision_mask = 0  # Use distance-based hit detection instead

	# Inner core glow (bright yellow-white)
	var core = Sprite2D.new()
	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	core.texture = tex
	core.centered = true
	core.scale = Vector2(8, 8)
	core.modulate = Color(1.0, 0.9, 0.5, 1.0)
	projectile.add_child(core)

	# Outer fire glow (larger, semi-transparent)
	var glow = Sprite2D.new()
	glow.texture = tex
	glow.centered = true
	glow.scale = Vector2(14, 14)
	glow.modulate = Color(data.effect_color.r, data.effect_color.g, data.effect_color.b, 0.5)
	projectile.add_child(glow)

	# Add fire particles
	var particles = _create_fire_particles(data.effect_color)
	projectile.add_child(particles)

	# Phase 2: DIRECTIONAL SKILLSHOT — fires in a straight line, no homing
	var speed = 300.0
	var max_despawn_range = 800.0
	var max_lifetime = 3.0
	var hit_radius = 30.0
	var lifetime = 0.0
	var damage_dealt = false

	# Rotate sprites to face the direction
	core.rotation = direction.angle()
	glow.rotation = direction.angle()

	# ADD TO SCENE, THEN SET POSITION
	caster.get_parent().add_child(projectile)
	projectile.global_position = caster.global_position
	var spawn_position = caster.global_position

	# Use weakref for caster (may die while projectile is in flight)
	var caster_ref = weakref(caster)
	var effect_color = data.effect_color
	var dmg = data.damage

	# Straight-line movement using Timer
	var timer = Timer.new()
	timer.wait_time = 0.016  # ~60 FPS
	timer.one_shot = false
	projectile.add_child(timer)

	timer.timeout.connect(func():
		if damage_dealt or not is_instance_valid(projectile):
			return

		lifetime += timer.wait_time
		if lifetime > max_lifetime:
			projectile.queue_free()
			return

		# Despawn if too far from spawn point
		if projectile.global_position.distance_to(spawn_position) > max_despawn_range:
			projectile.queue_free()
			return

		# Check hit against all players (distance-based)
		var tree = projectile.get_tree()
		if not tree:
			return

		for p in tree.get_nodes_in_group("player"):
			if not is_instance_valid(p):
				continue
			var dist = projectile.global_position.distance_to(p.global_position)
			if dist < hit_radius:
				p.take_damage(dmg)
				damage_dealt = true
				var c = caster_ref.get_ref()
				if c:
					_create_explosion(c, projectile.global_position, effect_color)
				projectile.queue_free()
				return

		# Move in fixed direction (no tracking)
		projectile.global_position += direction * speed * timer.wait_time
	)

	timer.start()

static func _create_fire_particles(color: Color) -> GPUParticles2D:
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
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_explosion(source: Node2D, position: Vector2, color: Color) -> void:
	var parent = source.get_parent()
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
	grad.set_color(0, Color(color.r, color.g, color.b, 1.0))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	particles.global_position = position
	parent.add_child(particles)

	var p_ref = weakref(particles)
	source.get_tree().create_timer(0.6).timeout.connect(func():
		if p_ref.get_ref():
			p_ref.get_ref().queue_free()
	)
