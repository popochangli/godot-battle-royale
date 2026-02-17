extends BaseProjectile

var caster: Node2D
var _hit_targets: Array = []

func _ready():
	collision_layer = 0
	collision_mask = 2
	add_to_group("projectile")
	speed = 500.0

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 7
	collision.shape = shape
	add_child(collision)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	_setup_visuals()

func _on_area_entered(area: Area2D) -> void:
	var target = area.get_parent()
	if target and target != caster and target.has_method("take_damage"):
		_do_hit(target)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and body != caster:
		_do_hit(body)

func _do_hit(target: Node2D) -> void:
	if target in _hit_targets:
		return
	_hit_targets.append(target)
	target.take_damage(damage, caster)
	if target.has_method("apply_slow"):
		target.apply_slow("ice_blast", 5.0, 3.0)
	_create_impact_particles()

func _setup_visuals() -> void:
	var core = _create_projectile_core()
	add_child(core)
	var trail = _create_trail_particles()
	add_child(trail)

func _create_projectile_core() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 10
	particles.lifetime = 0.15
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
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.9))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.3))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_trail_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.4
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 3.0
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 4.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 1.0))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_impact_particles() -> void:
	var particles = GPUParticles2D.new()
	particles.amount = 15
	particles.lifetime = 0.3
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 5.0
	material.spread = 180.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
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
	particles.global_position = global_position
	get_parent().add_child(particles)

	get_tree().create_timer(0.6).timeout.connect(particles.queue_free)
