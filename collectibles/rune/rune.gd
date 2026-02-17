extends Area2D

@export var rune_data: RuneData = preload("res://collectibles/rune/data/health_rune.tres")

var glow_particles: GPUParticles2D

func _ready():
	add_to_group("rune")
	collision_layer = 0
	collision_mask = 1

	body_entered.connect(_on_body_entered)

	_setup_visuals()

func _setup_visuals():
	var sprite = $Sprite2D
	if sprite:
		var glow_color = rune_data.glow_color if rune_data else Color(0.2, 1.0, 0.3, 1.0)
		sprite.modulate = glow_color
		if sprite.scale.length() > 3.0:
			sprite.scale = Vector2.ONE
		if sprite.texture == null:
			sprite.texture = _create_fallback_texture(glow_color)
		elif sprite.texture is CanvasTexture:
			var canvas_tex := sprite.texture as CanvasTexture
			if canvas_tex.diffuse_texture == null:
				sprite.texture = _create_fallback_texture(glow_color)

	glow_particles = _create_glow_particles()
	add_child(glow_particles)

func _create_fallback_texture(tint: Color) -> Texture2D:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	var radius := size * 0.45
	for x in range(size):
		for y in range(size):
			var d = Vector2(x, y).distance_to(center)
			if d <= radius:
				var alpha = clamp(1.0 - (d / radius) * 0.8, 0.0, 1.0)
				img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)

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
