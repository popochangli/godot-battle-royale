extends CharacterBody2D

@export var character_data: CharacterData

var max_health: int = 100
var health: int = 100
var speed: float = 300.0
var aim_direction: Vector2 = Vector2.RIGHT

var primary_timer: float = 0.0
var secondary_timer: float = 0.0

var is_invincible: bool = false
var iframe_duration: float = 0.5

@onready var health_bar = $CooldownUI/HealthBar
@onready var primary_indicator = $CooldownUI/HBoxContainer/PrimaryContainer/PrimaryIndicator
@onready var secondary_indicator = $CooldownUI/HBoxContainer/SecondaryContainer/SecondaryIndicator
@onready var primary_label = $CooldownUI/HBoxContainer/PrimaryContainer/PrimaryLabel
@onready var secondary_label = $CooldownUI/HBoxContainer/SecondaryContainer/SecondaryLabel
@onready var level_container = $CooldownUI/LevelContainer
@onready var level_label = $CooldownUI/LevelContainer/LevelLabel
@onready var xp_bar = $CooldownUI/LevelContainer/XPBar

func _ready():
	add_to_group("player")
	global_position = GameState.spawn_position

	if character_data == null:
		character_data = GameState.selected_character

	if character_data:
		speed = character_data.speed

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
	if primary_indicator and character_data.primary_ability:
		var ability = character_data.primary_ability
		var scaled_cooldown = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent)
		primary_indicator.cooldown_max = scaled_cooldown
		primary_indicator.indicator_color = ability.indicator_color
	if secondary_indicator and character_data.secondary_ability:
		var ability = character_data.secondary_ability
		var scaled_cooldown = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent)
		secondary_indicator.cooldown_max = scaled_cooldown
		secondary_indicator.indicator_color = ability.indicator_color

func _on_level_changed(_new_level: int):
	_apply_level_bonuses()
	_update_level_ui()
	_update_cooldown_indicators()
	_update_secondary_lock()

func _on_xp_gained(_amount: int, _total: int):
	_update_level_ui()

func _apply_level_bonuses():
	if character_data:
		max_health = GameState.get_scaled_max_health(character_data.max_health, character_data.hp_per_level)
		if health > max_health:
			health = max_health
		update_health_bar()

func _update_level_ui():
	if level_label:
		level_label.text = "Lv " + str(GameState.current_level)
	if xp_bar:
		var current_threshold = GameState.get_xp_for_current_level()
		var next_threshold = GameState.get_xp_for_next_level()
		xp_bar.min_value = current_threshold
		xp_bar.max_value = next_threshold
		xp_bar.value = GameState.current_xp

func _update_secondary_lock():
	var is_unlocked = GameState.is_secondary_unlocked()
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

	if primary_indicator:
		primary_indicator.cooldown_current = primary_timer
	if secondary_indicator:
		secondary_indicator.cooldown_current = secondary_timer

	var mouse_pos = get_global_mouse_position()
	$Sprite2D.look_at(mouse_pos)
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
		if ability.ability_script:
			ability.ability_script.execute(self, ability)
		primary_timer = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent)

func use_secondary_ability():
	if not GameState.is_secondary_unlocked():
		return
	if character_data and character_data.secondary_ability:
		var ability = character_data.secondary_ability
		if ability.ability_script:
			ability.ability_script.execute(self, ability)
		secondary_timer = GameState.get_scaled_cooldown(ability.cooldown, ability.cooldown_scale_percent)

func take_damage(amount):
	if is_invincible:
		return

	health -= amount
	update_health_bar()

	if health <= 0:
		die()
	else:
		_start_iframes()

func take_zone_damage(amount: float):
	health -= int(amount)
	if health < 0:
		health = 0
	update_health_bar()
	if health <= 0:
		die()

func _start_iframes():
	is_invincible = true
	_blink_effect()
	await get_tree().create_timer(iframe_duration).timeout
	if not is_instance_valid(self):
		return
	is_invincible = false
	$Sprite2D.modulate.a = 1.0

func _blink_effect():
	for i in range(5):
		if not is_instance_valid(self):
			return
		$Sprite2D.modulate.a = 0.3
		await get_tree().create_timer(iframe_duration / 10.0).timeout
		if not is_instance_valid(self):
			return
		$Sprite2D.modulate.a = 1.0
		await get_tree().create_timer(iframe_duration / 10.0).timeout

func heal(amount):
	health += amount
	if health > max_health:
		health = max_health
	update_health_bar()

func die():
	await get_tree().create_timer(2.0).timeout
	health = max_health
	position = Vector2.ZERO
	update_health_bar()

func update_health_bar():
	if health_bar:
		health_bar.value = health
		health_bar.max_value = max_health
