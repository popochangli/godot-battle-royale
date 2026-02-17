extends Area2D

@export var damage: int = 20
@export var radius: float = 100.0
@export var effect_color: Color = Color.WHITE
@export var expand_speed: float = 120.0

var caster: Node2D

var _current_radius: float = 10.0
var _target_radius: float = 100.0
var _expand_time: float = 0.0
var _elapsed: float = 0.0
var _hit_bodies: Array = []
var _done: bool = false
var _wave_center: Vector2
var _caster_ref: WeakRef
var _sprite: Sprite2D
var _circle_size: int = 64
var _prev_state: int = -1
var _spawn_ready: bool = false

func _ready():
	_target_radius = radius
	_expand_time = radius / expand_speed
	_caster_ref = weakref(caster)

	if caster and "current_state" in caster:
		_prev_state = caster.current_state
		caster.current_state = caster.State.CASTING

	_setup_visuals()

	if caster:
		caster.tree_exiting.connect(_on_caster_exiting)

func _physics_process(delta):
	if not _spawn_ready:
		_spawn_ready = true
		_wave_center = global_position
		_create_impact_particles()
		return

	if _done:
		return

	_elapsed += delta

	if _elapsed >= _expand_time:
		_done = true
		_restore_caster_state()
		queue_free()
		return

	var progress = _elapsed / _expand_time
	_current_radius = lerp(10.0, _target_radius, progress)

	if _sprite:
		var visual_scale = (_current_radius * 2.0) / _circle_size
		_sprite.scale = Vector2(visual_scale, visual_scale)
		_sprite.modulate.a = 0.7 * (1.0 - progress)

	for player in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(player):
			continue
		if player in _hit_bodies:
			continue

		var body_radius = _get_body_radius(player)
		var dist = _wave_center.distance_to(player.global_position)

		# Hit if player is within the entire expanded area (filled circle, not just wave front)
		# This prevents fast players from jumping through the wave
		if dist < _current_radius + body_radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)
			_hit_bodies.append(player)

func _setup_visuals() -> void:
	var img = Image.create(_circle_size, _circle_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(_circle_size / 2.0, _circle_size / 2.0)
	var tex_radius = _circle_size / 2.0
	for x in range(_circle_size):
		for y in range(_circle_size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= tex_radius:
				var alpha = 1.0 - (dist / tex_radius) * 0.5
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	_sprite = Sprite2D.new()
	var tex = ImageTexture.create_from_image(img)
	_sprite.texture = tex
	_sprite.centered = true
	var initial_visual_scale = 20.0 / _circle_size
	_sprite.scale = Vector2(initial_visual_scale, initial_visual_scale)
	_sprite.modulate = Color(effect_color.r, effect_color.g, effect_color.b, 0.7)
	add_child(_sprite)

func _restore_caster_state() -> void:
	var c = _caster_ref.get_ref() if _caster_ref else null
	if c and "current_state" in c:
		c.current_state = c.State.PURSUING if _prev_state == c.State.PURSUING else c.State.IDLE

func _on_caster_exiting() -> void:
	queue_free()

func _get_body_radius(body: Node2D) -> float:
	for child in body.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			return child.shape.radius
	return 16.0

func _create_impact_particles() -> void:
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
	grad.set_color(0, Color(effect_color.r, effect_color.g, effect_color.b, 1.0))
	grad.set_color(1, Color(effect_color.r, effect_color.g, effect_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = effect_color

	particles.process_material = material
	particles.global_position = global_position
	get_parent().add_child(particles)

	var p_ref = weakref(particles)
	get_tree().create_timer(0.6).timeout.connect(func():
		var p = p_ref.get_ref()
		if p:
			p.queue_free()
	)
