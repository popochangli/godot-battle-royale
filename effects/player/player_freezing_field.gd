extends Area2D

@export var duration: float = 5.0
@export var slow_per_second: float = 25.0
@export var slow_duration: float = 1.5
@export var effect_color: Color = Color(0.4, 0.7, 1.0)

var field_radius: float = 100.0
var follow_target: Node2D = null

var _elapsed: float = 0.0
var _enemies_in_field: Dictionary = {}

func _ready():
	collision_layer = 0
	collision_mask = 3  # Layer 1 (Player) + 2 (Enemy)

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = field_radius
	collision.shape = shape
	add_child(collision)

	_setup_visuals()

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	if follow_target and is_instance_valid(follow_target):
		global_position = follow_target.global_position

	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return

	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		var slow_amount = slow_per_second * delta
		for enemy in _enemies_in_field.keys():
			if is_instance_valid(enemy):
				enemy.add_slow("freezing_field", slow_amount, slow_duration)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("add_slow") and parent != get_parent():
		_enemies_in_field[parent] = true

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent in _enemies_in_field:
		_enemies_in_field.erase(parent)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_slow") and body != get_parent():
		_enemies_in_field[body] = true

func _on_body_exited(body: Node2D) -> void:
	if body in _enemies_in_field:
		_enemies_in_field.erase(body)

func _setup_visuals() -> void:
	add_child(_create_ground_frost())
	add_child(_create_swirling_ice())
	add_child(_create_inner_sparkles())

func _create_ground_frost() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 40
	particles.lifetime = 0.5
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = field_radius * 0.8
	material.spread = 180.0
	material.initial_velocity_min = 0.0
	material.initial_velocity_max = 10.0
	material.gravity = Vector3.ZERO
	material.scale_min = 6.0
	material.scale_max = 12.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(0.7, 0.9, 1.0, 0.6))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.2))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(0.8, 0.95, 1.0)

	particles.process_material = material
	return particles

func _create_swirling_ice() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 60
	particles.lifetime = 1.0
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_radius = field_radius
	material.emission_ring_inner_radius = field_radius * 0.7
	material.emission_ring_height = 0.0
	material.spread = 10.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.orbit_velocity_min = 0.5
	material.orbit_velocity_max = 1.0
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 5.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 0.9))
	grad.add_point(0.5, Color(0.8, 0.95, 1.0, 0.7))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	return particles

func _create_inner_sparkles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.8
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = field_radius * 0.6
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3(0, 20, 0)
	material.scale_min = 1.0
	material.scale_max = 3.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 0.8))
	grad.set_color(1, Color(0.9, 0.95, 1.0, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(1.0, 1.0, 1.0)

	particles.process_material = material
	return particles
