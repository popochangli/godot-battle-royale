extends Node

static func execute(caster: Node2D, data: EnemySkillData) -> void:
	var player = caster.get_tree().get_first_node_in_group("player")
	if not player:
		return

	var direction = (player.global_position - caster.global_position).normalized()
	_spawn_arrow(caster, direction, data)

static func _spawn_arrow(caster: Node2D, direction: Vector2, data: EnemySkillData) -> void:
	# Phase 3: Lock target at spawn time — never re-acquire from group
	var locked_target = caster.get_tree().get_first_node_in_group("player")
	if not locked_target:
		return

	var projectile = Area2D.new()
	projectile.collision_layer = 0
	projectile.collision_mask = 0  # Use distance-based hit detection instead

	# Arrow core (bright green-white)
	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex = ImageTexture.create_from_image(img)

	var core = Sprite2D.new()
	core.texture = tex
	core.centered = true
	core.scale = Vector2(6, 10)
	core.modulate = Color(0.8, 1.0, 0.6, 1.0)
	projectile.add_child(core)

	# Poison glow (semi-transparent aura)
	var glow = Sprite2D.new()
	glow.texture = tex
	glow.centered = true
	glow.scale = Vector2(12, 12)
	glow.modulate = Color(data.effect_color.r, data.effect_color.g, data.effect_color.b, 0.4)
	projectile.add_child(glow)

	# Add poison trail particles
	var particles = _create_poison_trail(data.effect_color)
	projectile.add_child(particles)

	# HOMING PROJECTILE - locked target (like DOTA 2)
	var speed = 300.0
	var max_despawn_range = 800.0
	var max_lifetime = 5.0
	var hit_radius = 28.0
	var lifetime = 0.0
	var damage_dealt = false
	var current_direction = direction

	# ADD TO SCENE, THEN SET POSITION
	caster.get_parent().add_child(projectile)
	projectile.global_position = caster.global_position
	var spawn_position = caster.global_position

	# Use weakrefs for nodes that might die during flight
	var caster_ref = weakref(caster)
	var target_ref = weakref(locked_target)
	var effect_color = data.effect_color
	var dmg = data.damage

	# Homing behavior using Timer
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

		# If locked target is gone, despawn immediately
		var target = target_ref.get_ref()
		if not target:
			projectile.queue_free()
			return

		var dist_to_target = projectile.global_position.distance_to(target.global_position)

		# HIT CHECK - distance-based
		if dist_to_target < hit_radius:
			target.take_damage(dmg)
			damage_dealt = true
			_apply_poison_dot(target, data, caster_ref)
			var c = caster_ref.get_ref()
			if c:
				_create_poison_cloud(c, projectile.global_position, effect_color)
			projectile.queue_free()
			return

		# Always track locked target (no range limit — it's a homing projectile)
		current_direction = (target.global_position - projectile.global_position).normalized()

		# Move in current direction
		projectile.global_position += current_direction * speed * timer.wait_time
	)

	timer.start()

static func _apply_poison_dot(player: Node, data: EnemySkillData, caster_ref) -> void:
	# Apply damage over time (3 damage per second for 4 seconds = 12 total)
	var dot_duration = 4.0
	var dot_damage_per_sec = 3
	var tick_interval = 1.0
	var ticks = int(dot_duration / tick_interval)

	var tree = player.get_tree()
	if not tree:
		return

	var player_ref = weakref(player)
	for i in range(ticks):
		await tree.create_timer(tick_interval).timeout
		var p = player_ref.get_ref()
		if p and p.has_method("take_damage"):
			p.take_damage(dot_damage_per_sec)

static func _create_poison_trail(color: Color) -> GPUParticles2D:
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
	grad.set_color(0, Color(color.r, color.g, color.b, 0.8))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	return particles

static func _create_poison_cloud(source: Node2D, position: Vector2, color: Color) -> void:
	var parent = source.get_parent()
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
	grad.set_color(0, Color(color.r, color.g, color.b, 0.6))
	grad.set_color(1, Color(color.r, color.g, color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = color

	particles.process_material = material
	particles.global_position = position
	parent.add_child(particles)

	var p_ref = weakref(particles)
	source.get_tree().create_timer(0.8).timeout.connect(func():
		var p = p_ref.get_ref()
		if p:
			p.queue_free()
	)
