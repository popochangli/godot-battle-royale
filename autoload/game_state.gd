extends Node

signal level_changed(new_level: int)
signal xp_gained(amount: int, total: int)

var selected_character: CharacterData = null
var current_level: int = 1
var current_xp: int = 0
var spawn_position: Vector2 = Vector2(531, 182)

const XP_THRESHOLDS = [0, 50, 130, 240, 380]
const SECONDARY_UNLOCK_LEVEL = 5

func _ready():
	if selected_character == null:
		selected_character = load("res://player/characters/data/crystal_maiden.tres")

func reset_progression():
	current_level = 1
	current_xp = 0
	spawn_position = Vector2(531, 182)
	level_changed.emit(current_level)

func add_xp(amount: int):
	current_xp += amount
	xp_gained.emit(amount, current_xp)
	_check_level_up()

func _check_level_up():
	while current_level < XP_THRESHOLDS.size() and current_xp >= XP_THRESHOLDS[current_level]:
		current_level += 1
		level_changed.emit(current_level)

func get_xp_for_next_level() -> int:
	if current_level >= XP_THRESHOLDS.size():
		return XP_THRESHOLDS[XP_THRESHOLDS.size() - 1]
	return XP_THRESHOLDS[current_level]

func get_xp_for_current_level() -> int:
	if current_level <= 1:
		return 0
	return XP_THRESHOLDS[current_level - 1]

func is_secondary_unlocked() -> bool:
	return current_level >= SECONDARY_UNLOCK_LEVEL

func get_scaled_damage(base_damage: int, scale_percent: float) -> int:
	var bonus = base_damage * scale_percent * (current_level - 1)
	return base_damage + int(bonus)

func get_scaled_cooldown(base_cooldown: float, scale_percent: float) -> float:
	var reduction = base_cooldown * scale_percent * (current_level - 1)
	return max(base_cooldown - reduction, 0.1)

func get_scaled_radius(base_radius: float, scale_percent: float) -> float:
	var bonus = base_radius * scale_percent * (current_level - 1)
	return base_radius + bonus

func get_scaled_duration(base_duration: float, scale_percent: float) -> float:
	var bonus = base_duration * scale_percent * (current_level - 1)
	return base_duration + bonus

func get_bonus_projectiles(bonus_levels: Array[int]) -> int:
	var bonus = 0
	for level in bonus_levels:
		if current_level >= level:
			bonus += 1
	return bonus

func get_scaled_max_health(base_health: int, hp_per_level: int) -> int:
	return base_health + hp_per_level * (current_level - 1)
