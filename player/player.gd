extends CharacterBody2D

@export var character_data: CharacterData

var peer_id: int = 1
var max_health: int = 100
var health: int = 100
var speed: float = 300.0
var aim_direction: Vector2 = Vector2.RIGHT

var primary_timer: float = 0.0
var secondary_timer: float = 0.0
var regen_timer: float = 0.0
var has_direction_sprites: bool = false


@onready var health_bar = $CooldownUI/HealthBar
@onready var primary_indicator = $CooldownUI/HBoxContainer/PrimaryContainer/PrimaryIndicator
@onready var secondary_indicator = $CooldownUI/HBoxContainer/SecondaryContainer/SecondaryIndicator
@onready var primary_label = $CooldownUI/HBoxContainer/PrimaryContainer/PrimaryLabel
@onready var secondary_label = $CooldownUI/HBoxContainer/SecondaryContainer/SecondaryLabel
@onready var level_container = $CooldownUI/LevelContainer
@onready var level_label = $CooldownUI/LevelContainer/LevelLabel
@onready var xp_bar = $CooldownUI/LevelContainer/XPBar

func _enter_tree():
	if multiplayer.multiplayer_peer != null and has_node("MultiplayerSynchronizer"):
		var sync = $MultiplayerSynchronizer
		var config = SceneReplicationConfig.new()
		config.add_property(NodePath(".:position"))
		config.add_property(NodePath(".:velocity"))
		config.add_property(NodePath(".:health"))
		config.add_property(NodePath(".:max_health"))
		config.add_property(NodePath(".:aim_direction"))
		config.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		config.property_set_replication_mode(NodePath(".:velocity"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		config.property_set_replication_mode(NodePath(".:aim_direction"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		config.property_set_replication_mode(NodePath(".:health"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		config.property_set_replication_mode(NodePath(".:max_health"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		sync.replication_config = config

func _ready():
	add_to_group("player")
	peer_id = get_multiplayer_authority()
	if peer_id == 0:
		peer_id = 1

	var is_local = multiplayer.multiplayer_peer == null or is_multiplayer_authority()
	if has_node("Camera2D"):
		var cam = $Camera2D
		cam.enabled = is_local
		if is_local:
			cam.make_current()
	if not is_local:
		if has_node("CooldownUI/HealthBar"):
			$CooldownUI/HealthBar.visible = false
		if has_node("CooldownUI/HBoxContainer"):
			$CooldownUI/HBoxContainer.visible = false
		if has_node("CooldownUI/LevelContainer"):
			$CooldownUI/LevelContainer.visible = false

	# Only set position from GameState in single-player; in multiplayer, position is correctly
	# set by main.gd _spawn_player (spawn_function) on both server and clients.
	if multiplayer.multiplayer_peer == null:
		global_position = GameState.get_spawn_position(peer_id)

	if character_data == null:
		character_data = GameState.get_selected_character(peer_id)

	if character_data:
		speed = character_data.speed

		if character_data.direction_sprites.size() == 8:
			has_direction_sprites = true
			$Sprite2D.texture = character_data.direction_sprites[0]
			$Sprite2D.scale = Vector2(character_data.sprite_scale, character_data.sprite_scale)
			$Sprite2D.rotation = 0

		if primary_label and character_data.primary_ability:
			primary_label.text = character_data.primary_ability.display_name
		if secondary_label and character_data.secondary_ability:
			secondary_label.text = character_data.secondary_ability.display_name

		_update_cooldown_indicators()

	_apply_level_bonuses()
	_update_level_ui()
	_update_secondary_lock()

	GameState.level_changed.connect(_on_level_changed)
	GameState.xp_gained.connect(_on_xp_gained)

func _update_cooldown_indicators():
	if primary_indicator and character_data and character_data.primary_ability:
		var ability = character_data.primary_ability
		var scaled_cooldown = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent, peer_id)
		primary_indicator.cooldown_max = scaled_cooldown
		primary_indicator.indicator_color = ability.indicator_color
	if secondary_indicator and character_data and character_data.secondary_ability:
		var ability = character_data.secondary_ability
		var scaled_cooldown = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent, peer_id)
		secondary_indicator.cooldown_max = scaled_cooldown
		secondary_indicator.indicator_color = ability.indicator_color

func _on_level_changed(pid: int, _new_level: int):
	if pid != peer_id:
		return
	_apply_level_bonuses()
	_update_level_ui()
	_update_cooldown_indicators()
	_update_secondary_lock()

func _on_xp_gained(pid: int, _amount: int, _total: int):
	if pid != peer_id:
		return
	_update_level_ui()

func _apply_level_bonuses():
	if character_data:
		max_health = GameState.get_scaled_max_health(character_data.max_health, character_data.hp_per_level, peer_id)
		if health > max_health:
			health = max_health
		update_health_bar()

func _update_level_ui():
	if level_label:
		level_label.text = "Lv " + str(GameState.get_level(peer_id))
	if xp_bar:
		var current_threshold = GameState.get_xp_for_current_level(peer_id)
		var next_threshold = GameState.get_xp_for_next_level(peer_id)
		xp_bar.min_value = current_threshold
		xp_bar.max_value = next_threshold
		xp_bar.value = GameState._ensure_player_data(peer_id)["xp"]

func _update_secondary_lock():
	var is_unlocked = GameState.is_secondary_unlocked(peer_id)
	if secondary_indicator:
		secondary_indicator.modulate.a = 1.0 if is_unlocked else 0.4
	if secondary_label:
		if is_unlocked:
			secondary_label.text = character_data.secondary_ability.display_name if character_data and character_data.secondary_ability else "Secondary"
		else:
			secondary_label.text = "Lv 5"

func _physics_process(delta):
	if primary_timer > 0:
		primary_timer -= delta
	if secondary_timer > 0:
		secondary_timer -= delta

	regen_timer += delta
	if regen_timer >= 1.0:
		regen_timer -= 1.0
		var regen_amount = GameState._get_level(peer_id) * 0.5
		if health < max_health and regen_amount >= 1.0:
			health = min(health + int(regen_amount), max_health)
			update_health_bar()

	if primary_indicator:
		primary_indicator.cooldown_current = primary_timer
	if secondary_indicator:
		secondary_indicator.cooldown_current = secondary_timer

	if multiplayer.multiplayer_peer != null and not is_multiplayer_authority():
		return

	var mouse_pos = get_global_mouse_position()
	_update_facing(mouse_pos)
	aim_direction = (mouse_pos - global_position).normalized()

	var direction = Vector2.ZERO

	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1

	if direction.length() > 0:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and primary_timer <= 0:
		use_primary_ability()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and secondary_timer <= 0:
		use_secondary_ability()

func use_primary_ability():
	if character_data and character_data.primary_ability:
		var ability = character_data.primary_ability
		var mouse_pos = get_global_mouse_position()
		primary_timer = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent, peer_id)
		if ability.ability_script:
			ability.ability_script.execute(self, ability, mouse_pos)
		if multiplayer.multiplayer_peer != null:
			if multiplayer.is_server():
				_show_ability_visual.rpc("primary", global_position, aim_direction, mouse_pos)
			else:
				_request_ability.rpc_id(1, "primary", aim_direction, mouse_pos)

func use_secondary_ability():
	if not GameState.is_secondary_unlocked(peer_id):
		return
	if character_data and character_data.secondary_ability:
		var ability = character_data.secondary_ability
		var mouse_pos = get_global_mouse_position()
		secondary_timer = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent, peer_id)
		if ability.ability_script:
			ability.ability_script.execute(self, ability, mouse_pos)
		if multiplayer.multiplayer_peer != null:
			if multiplayer.is_server():
				_show_ability_visual.rpc("secondary", global_position, aim_direction, mouse_pos)
			else:
				_request_ability.rpc_id(1, "secondary", aim_direction, mouse_pos)

@rpc("any_peer", "reliable")
func _request_ability(_type: String, _direction: Vector2, _mouse_pos: Vector2):
	if not multiplayer.is_server():
		return
	var ability = character_data.primary_ability if _type == "primary" else (character_data.secondary_ability if character_data else null)
	if ability and ability.ability_script:
		ability.ability_script.execute(self, ability, _mouse_pos)
	var sender = multiplayer.get_remote_sender_id()
	for pid in multiplayer.get_peers():
		if pid != sender:
			_show_ability_visual.rpc_id(pid, _type, global_position, _direction, _mouse_pos)

@rpc("any_peer", "reliable")
func _show_ability_visual(_type: String, _pos: Vector2, _direction: Vector2, _mouse_pos: Vector2):
	var ability = character_data.primary_ability if _type == "primary" else (character_data.secondary_ability if character_data else null)
	if ability and ability.ability_script:
		var old_pos = global_position
		var old_aim = aim_direction
		global_position = _pos
		aim_direction = _direction
		ability.ability_script.execute(self, ability, _mouse_pos)
		global_position = old_pos
		aim_direction = old_aim

@rpc("authority", "reliable")
func _broadcast_spectral_visual(pos: Vector2, angle: float, range_dist: float):
	var slash = Polygon2D.new()
	slash.polygon = PackedVector2Array([
		Vector2(0, -10),
		Vector2(range_dist, -range_dist / 2.0),
		Vector2(range_dist, range_dist / 2.0),
		Vector2(0, 10)
	])
	slash.color = Color(0.8, 0.0, 0.8, 0.6)
	var container = get_tree().get_first_node_in_group("effects_container")
	if container:
		container.add_child(slash)
	else:
		get_parent().add_child(slash)
	slash.global_position = pos
	slash.rotation = angle
	var tween = slash.create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(slash.queue_free)

func take_damage(amount, _attacker = null):
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	var reduced = max(int(amount * (1.0 - GameState.get_damage_reduction(peer_id))), 1)
	health -= reduced
	update_health_bar()

	if multiplayer.multiplayer_peer != null:
		var authority = get_multiplayer_authority()
		if authority != 1:
			_apply_damage.rpc_id(authority, reduced)

	if health <= 0:
		die()

@rpc("any_peer", "reliable")
func _apply_damage(amount: int):
	if multiplayer.get_remote_sender_id() != 1:
		return
	health = max(0, health - amount)
	update_health_bar()

@rpc("any_peer", "reliable")
func _apply_heal(amount: int):
	if multiplayer.get_remote_sender_id() != 1:
		return
	health = min(max_health, health + amount)
	update_health_bar()

func take_zone_damage(amount: float):
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	var dmg = int(amount)
	health -= dmg
	if health < 0:
		health = 0
	update_health_bar()
	if multiplayer.multiplayer_peer != null:
		var authority = get_multiplayer_authority()
		if authority != 1:
			_apply_damage.rpc_id(authority, dmg)
	if health <= 0:
		die()


func heal(amount):
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	var heal_amount = max(amount, 0)
	if heal_amount <= 0:
		return
	health += heal_amount
	if health > max_health:
		health = max_health
	update_health_bar()
	if multiplayer.multiplayer_peer != null:
		var authority = get_multiplayer_authority()
		if authority != 1:
			_apply_heal.rpc_id(authority, heal_amount)

func _set_dead_state():
	visible = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0

func die():
	if multiplayer.multiplayer_peer != null:
		if not multiplayer.is_server():
			return
		_broadcast_death.rpc()
		_set_dead_state()
		var main_node = get_tree().current_scene
		if main_node:
			if main_node.has_method("_on_player_died"):
				main_node._on_player_died(peer_id)
			if main_node.has_method("_announce_winner"):
				var alive = get_tree().get_nodes_in_group("player").filter(func(p): return p.health > 0 and not p.is_in_group("player_illusion"))
				if alive.size() == 1:
					main_node._announce_winner(alive[0].peer_id)
	else:
		_set_dead_state()
		var main_node = get_tree().current_scene
		if main_node and main_node.has_method("_display_death_overlay"):
			main_node._display_death_overlay("Rank: #1 / 1")

@rpc("any_peer", "reliable")
func _broadcast_death():
	if multiplayer.get_remote_sender_id() != 1:
		return
	_set_dead_state()

func update_health_bar():
	if health_bar:
		health_bar.value = health
		health_bar.max_value = max_health

func _update_facing(target_pos: Vector2) -> void:
	if has_direction_sprites and character_data:
		var dir = (target_pos - global_position).normalized()
		var angle = dir.angle()
		var idx = wrapi(roundi((angle - PI / 2) / (PI / 4)), 0, 8)
		var remap = [0, 7, 6, 5, 4, 3, 2, 1]
		var sprite_idx = remap[idx]
		$Sprite2D.texture = character_data.direction_sprites[sprite_idx]
		$Sprite2D.rotation = 0
	else:
		$Sprite2D.look_at(target_pos)
