extends CharacterBody2D

enum State { IDLE, PURSUING, RETURNING }

@export var xp_value: int = 25

var base_speed = 150
var speed = 150
var max_health = 100
var health
var damage = 10
var attack_range = 50
var attack_cooldown = 1.0
var attack_timer = 0.0

var is_invincible: bool = false
var iframe_duration: float = 0.3

var player = null
var is_frozen = false
var original_modulate: Color
var last_attacker: Node = null

var slow_sources: Dictionary = {}
var current_visual_state: String = "normal"
var slow_effect_node: GPUParticles2D = null
var freeze_effect_node: GPUParticles2D = null

var burn_sources: Dictionary = {}
var burn_tick_timer: float = 0.0


var current_state: State = State.IDLE
var camp: Node2D = null
var camp_center: Vector2 = Vector2.ZERO
var leash_range: float = 300.0
var aggro_timeout: float = 8.0
var time_in_pursuit: float = 0.0
var aggro_range: float = 150.0
var idle_target: Vector2 = Vector2.ZERO
var idle_wait_timer: float = 0.0
var patrol_radius: float = 80.0

@onready var health_bar = $ProgressBar

func _ready():
	add_to_group("enemy")
	original_modulate = $Sprite2D.modulate
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = max_health
	update_health_bar()
	if camp_center == Vector2.ZERO:
		camp_center = global_position
	_pick_new_idle_target()

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta

	_process_slow_timers(delta)
	_process_burn_timers(delta)

	if player == null:
		player = get_tree().get_first_node_in_group("player")

	match current_state:
		State.IDLE:
			_process_idle_state(delta)
		State.PURSUING:
			_process_pursuing_state(delta)
		State.RETURNING:
			_process_returning_state(delta)

func _process_idle_state(delta):
	if player:
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player < aggro_range:
			current_state = State.PURSUING
			time_in_pursuit = 0.0
			return

	idle_wait_timer -= delta
	if idle_wait_timer <= 0:
		var dist_to_target = global_position.distance_to(idle_target)
		if dist_to_target < 10.0:
			_pick_new_idle_target()
			idle_wait_timer = randf_range(1.0, 3.0)
		else:
			var direction = (idle_target - global_position).normalized()
			velocity = direction * speed * 0.5
			move_and_slide()
			$Sprite2D.look_at(idle_target)
	else:
		velocity = Vector2.ZERO

func _process_pursuing_state(delta):
	if not player:
		current_state = State.RETURNING
		return

	time_in_pursuit += delta
	var dist_from_camp = global_position.distance_to(camp_center)

	if dist_from_camp > leash_range or time_in_pursuit > aggro_timeout:
		current_state = State.RETURNING
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	$Sprite2D.look_at(player.global_position)

	var distance = global_position.distance_to(player.global_position)
	if distance < attack_range and attack_timer <= 0:
		attack_player()
		attack_timer = attack_cooldown

func _process_returning_state(_delta):
	var dist_to_camp = global_position.distance_to(camp_center)
	if dist_to_camp < 20.0:
		update_health_bar()
		current_state = State.IDLE
		_pick_new_idle_target()
		idle_wait_timer = randf_range(0.5, 1.5)
		return

	var direction = (camp_center - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	$Sprite2D.look_at(camp_center)

func _pick_new_idle_target():
	var angle = randf() * TAU
	var dist = randf() * patrol_radius
	idle_target = camp_center + Vector2(cos(angle), sin(angle)) * dist

func set_camp(camp_node: Node2D, center: Vector2, patrol_rad: float, leash: float, aggro_time: float):
	camp = camp_node
	camp_center = center
	patrol_radius = patrol_rad
	leash_range = leash
	aggro_timeout = aggro_time
	_pick_new_idle_target()

func attack_player():
	if player and player.has_method("take_damage"):
		var direction = (player.global_position - global_position).normalized()
		var slash = _create_slash_particles(direction)
		add_child(slash)
		get_tree().create_timer(0.5).timeout.connect(func():
			if is_instance_valid(slash):
				slash.queue_free()
		)
		player.take_damage(damage)

func take_damage(amount, attacker: Node = null):
	if is_invincible:
		return

	if attacker:
		last_attacker = attacker

	health -= amount
	update_health_bar()

	if player and current_state != State.PURSUING:
		current_state = State.PURSUING
		time_in_pursuit = 0.0

	if health <= 0:
		die()
	else:
		_start_iframes()

func _start_iframes():
	is_invincible = true
	_blink_effect()
	await get_tree().create_timer(iframe_duration).timeout
	if not is_instance_valid(self):
		return
	is_invincible = false
	_restore_visual_color()

func _blink_effect():
	for i in range(3):
		if not is_instance_valid(self):
			return
		$Sprite2D.modulate = Color.WHITE
		await get_tree().create_timer(iframe_duration / 6.0).timeout
		if not is_instance_valid(self):
			return
		_restore_visual_color()
		await get_tree().create_timer(iframe_duration / 6.0).timeout

func _restore_visual_color() -> void:
	match current_visual_state:
		"normal":
			$Sprite2D.modulate = Color.RED
		"slowed":
			$Sprite2D.modulate = Color(0.6, 0.85, 1.0)
		"frozen":
			$Sprite2D.modulate = Color(0.4, 0.8, 1.0)

func die():
	if last_attacker and last_attacker.is_in_group("player"):
		GameState.add_xp(xp_value)
	queue_free()

func update_health_bar():
	if health_bar:
		health_bar.value = health

func apply_freeze(duration: float) -> void:
	apply_slow("legacy_freeze", 100.0, duration)

func apply_slow(source_id: String, percent: float, duration: float) -> void:
	slow_sources[source_id] = {"percent": percent, "timer": duration}
	_recalculate_speed()

func add_slow(source_id: String, amount: float, duration: float) -> void:
	if slow_sources.has(source_id):
		slow_sources[source_id]["percent"] += amount
		slow_sources[source_id]["timer"] = duration
	else:
		slow_sources[source_id] = {"percent": amount, "timer": duration}
	_recalculate_speed()

func _process_slow_timers(delta: float) -> void:
	var sources_to_remove = []
	for source_id in slow_sources:
		slow_sources[source_id]["timer"] -= delta
		if slow_sources[source_id]["timer"] <= 0:
			sources_to_remove.append(source_id)

	if sources_to_remove.size() > 0:
		for source_id in sources_to_remove:
			slow_sources.erase(source_id)
		_recalculate_speed()

func _recalculate_speed() -> void:
	var total_slow = 0.0
	for source_id in slow_sources:
		total_slow += slow_sources[source_id]["percent"]

	total_slow = clamp(total_slow, 0.0, 100.0)
	speed = base_speed * (1.0 - total_slow / 100.0)
	is_frozen = total_slow >= 100.0
	_update_visual_state(total_slow)

func _update_visual_state(total_slow: float) -> void:
	var new_state: String
	if total_slow >= 100.0:
		new_state = "frozen"
	elif total_slow > 0.0:
		new_state = "slowed"
	else:
		new_state = "normal"

	if new_state == current_visual_state:
		return

	current_visual_state = new_state

	if slow_effect_node:
		slow_effect_node.queue_free()
		slow_effect_node = null
	if freeze_effect_node:
		freeze_effect_node.queue_free()
		freeze_effect_node = null

	match current_visual_state:
		"normal":
			$Sprite2D.modulate = Color.RED
		"slowed":
			$Sprite2D.modulate = Color(0.6, 0.85, 1.0)
			slow_effect_node = _create_slow_particles()
			add_child(slow_effect_node)
		"frozen":
			$Sprite2D.modulate = Color(0.4, 0.8, 1.0)
			freeze_effect_node = _create_freeze_particles()
			add_child(freeze_effect_node)

func _create_slow_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 8
	particles.lifetime = 0.8
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 15.0
	material.spread = 30.0
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 20.0
	material.direction = Vector3(0, -1, 0)
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 4.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(0.7, 0.9, 1.0, 0.6))
	grad.set_color(1, Color(0.6, 0.85, 1.0, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(0.6, 0.85, 1.0)

	particles.process_material = material
	return particles

func _create_freeze_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 15
	particles.lifetime = 0.6
	particles.one_shot = false
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 20.0
	material.spread = 60.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.direction = Vector3(0, -1, 0)
	material.gravity = Vector3.ZERO
	material.scale_min = 3.0
	material.scale_max = 6.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(0.5, 0.9, 1.0, 0.8))
	grad.set_color(1, Color(0.4, 0.8, 1.0, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(0.4, 0.8, 1.0)

	particles.process_material = material
	return particles

func _create_slash_particles(direction: Vector2) -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.amount = 20
	particles.lifetime = 0.25
	particles.one_shot = true
	particles.emitting = true

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_axis = Vector3(0, 0, 1)
	material.emission_ring_radius = 30.0
	material.emission_ring_inner_radius = 10.0
	material.emission_ring_height = 0.0
	material.spread = 45.0
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 120.0
	material.direction = Vector3(direction.x, direction.y, 0)
	material.gravity = Vector3.ZERO
	material.scale_min = 2.0
	material.scale_max = 4.0

	var gradient = GradientTexture1D.new()
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.6, 0.2, 1.0))
	grad.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
	gradient.gradient = grad
	material.color_ramp = gradient
	material.color = Color(1.0, 0.5, 0.2)

	particles.process_material = material
	return particles

func apply_burn(source_id: String, damage: int, duration: float, attacker: Node) -> void:
	if burn_sources.has(source_id):
		burn_sources[source_id]["duration"] = duration
		burn_sources[source_id]["damage"] = damage
		burn_sources[source_id]["attacker"] = attacker
	else:
		burn_sources[source_id] = {
			"damage": damage,
			"duration": duration,
			"attacker": attacker
		}
	_update_visual_state(0.0)

func _process_burn_timers(delta: float) -> void:
	# 1. Handle Duration
	var sources_to_remove = []
	for source_id in burn_sources:
		burn_sources[source_id]["duration"] -= delta
		if burn_sources[source_id]["duration"] <= 0:
			sources_to_remove.append(source_id)
			
	for source_id in sources_to_remove:
		burn_sources.erase(source_id)
		
	burn_tick_timer -= delta
	if burn_tick_timer <= 0:
		burn_tick_timer = 0.5
		var total_damage = 0
		var main_attacker = null
		for source_id in burn_sources:
			total_damage += burn_sources[source_id]["damage"]
			main_attacker = burn_sources[source_id]["attacker"]
			
		if total_damage > 0:
			take_damage(total_damage, main_attacker)

	if burn_sources.size() > 0 and current_visual_state != "frozen":
		$Sprite2D.modulate = Color(1.0, 0.5, 0.0)
	elif burn_sources.size() == 0 and current_visual_state == "normal":
		$Sprite2D.modulate = Color.RED

	
