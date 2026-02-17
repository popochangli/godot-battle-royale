extends Area2D

@export var rune_data: RuneData

var glow_particles: GPUParticles2D

func _ready():
	add_to_group("rune")
	collision_layer = 0
	collision_mask = 1

	body_entered.connect(_on_body_entered)

	if rune_data:
		_setup_visuals()

func _setup_visuals():
	var sprite = $Sprite2D
	if sprite:
		sprite.modulate = rune_data.glow_color

	glow_particles = _create_glow_particles()
	add_child(glow_particles)

func _create_glow_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 12
	particles.lifetime = 1.2
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 10.0
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.direction = Vector3(0, -1, 0)
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 4.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	var glow_color = rune_data.glow_color if rune_data else Color.GREEN
	grad.set_color(0, Color(glow_color.r, glow_color.g, glow_color.b, 0.8))
	grad.set_color(1, Color(glow_color.r, glow_color.g, glow_color.b, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = glow_color

	particles.process_material = material
	return particles

func _on_body_entered(body: Node2D):
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	if not body.is_in_group("player"):
		return

	if rune_data:
		_apply_effect(body)

	queue_free()

func _apply_effect(player: Node2D):
	match rune_data.effect_type:
		"heal":
			if player.has_method("heal"):
				var heal_amount = int(player.max_health * rune_data.effect_value)
				player.heal(heal_amount)
