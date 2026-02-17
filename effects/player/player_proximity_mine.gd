extends Area2D

@export var damage: int = 20
@export var mine_radius: float = 50.0
@export var effect_color: Color = Color(1.0, 0.5, 0.2)

var owner_id: int = 0
var caster: Node2D
var _detonated: bool = false

func _ready():
	add_to_group("techies_mines")
	collision_layer = 0
	collision_mask = 3  # Layer 1 (Player) + 2 (Enemy)
	set_meta("owner_id", owner_id)
	set_meta("scaled_damage", damage)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = mine_radius
	collision.shape = shape
	add_child(collision)

	_setup_visuals()

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("take_damage") and parent != caster:
		_detonate()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != caster:
		_detonate()

func _detonate() -> void:
	if _detonated:
		return
	_detonated = true

	monitoring = false
	visible = false

	var explosion_pos = global_position
	_do_explosion(explosion_pos)

func _do_explosion(explosion_pos: Vector2) -> void:
	if not is_instance_valid(caster):
		queue_free()
		return

	var explosion_radius = mine_radius * 1.5

	_create_mine_explosion(explosion_pos, explosion_radius)

	var ring = _create_explosion_ring(explosion_radius)
	ring.global_position = explosion_pos
	caster.get_parent().add_child(ring)
	caster.get_tree().create_timer(0.6).timeout.connect(ring.queue_free)

	var explosion = Area2D.new()
	explosion.add_to_group("explosion")
	explosion.collision_layer = 0
	explosion.collision_mask = 3  # Layer 1 (Player) + 2 (Enemy)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = explosion_radius
	collision.shape = shape
	explosion.add_child(collision)

	explosion.global_position = explosion_pos
	caster.get_parent().add_child(explosion)

	var damaged_targets = []
	var caster_ref = weakref(caster)
	var scaled_damage = damage

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

	await caster.get_tree().physics_frame
	await caster.get_tree().physics_frame

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
	await caster.get_tree().create_timer(0.3).timeout
	explosion.queue_free()
	queue_free()

func _setup_visuals() -> void:
	add_child(_create_mine_core())
	add_child(_create_pulse_glow())
	add_child(_create_spark_particles())

func _create_mine_core() -> GPUParticles2D:
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
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.4))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_pulse_glow() -> GPUParticles2D:
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
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	grad.add_point(0.25, Color(effect_color.r, effect_color.g, effect_color.b, 0.5))
	grad.add_point(0.5, Color(effect_color.r, effect_color.g, effect_color.b, 0.5))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_spark_particles() -> GPUParticles2D:
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

func _create_explosion_ring(radius: float) -> GPUParticles2D:
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
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_mine_explosion(position: Vector2, radius: float) -> void:
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
