extends Node

signal level_changed(peer_id: int, new_level: int)
signal xp_gained(peer_id: int, amount: int, total: int)

# Single-player backward compatibility (used when player_data is empty for peer_id 1)
var selected_character: CharacterData = null
var current_level: int = 1
var current_xp: int = 0
var spawn_position: Vector2 = Vector2(531, 182)

# Per-player data for multiplayer: peer_id -> {character_path, selected_character, level, xp, spawn_position}
var player_data: Dictionary = {}

const XP_THRESHOLDS = [0, 50, 130, 240, 380]
const SECONDARY_UNLOCK_LEVEL = 5

func _ready():
	if selected_character == null:
		selected_character = load("res://player/characters/data/crystal_maiden.tres")

func _ensure_player_data(peer_id: int) -> Dictionary:
	if not player_data.has(peer_id):
		player_data[peer_id] = {
			"character_path": "",
			"selected_character": null,
			"level": 1,
			"xp": 0,
			"spawn_position": Vector2(531, 182)
		}
	return player_data[peer_id]

func get_selected_character(peer_id: int) -> CharacterData:
	var pd = _ensure_player_data(peer_id)
	if pd["selected_character"]:
		return pd["selected_character"]
	if peer_id == 1 and selected_character:
		return selected_character
	return load("res://player/characters/data/crystal_maiden.tres") as CharacterData

func get_spawn_position(peer_id: int) -> Vector2:
	var pd = _ensure_player_data(peer_id)
	# Prefer explicit spawn_position from spawn_select (single player) or lobby (multiplayer)
	if pd["spawn_position"] != Vector2(531, 182) or pd["spawn_confirmed"] == true:
		return pd["spawn_position"]
	if peer_id == 1:
		return spawn_position
	return Vector2(531, 182)

func _get_level(peer_id: int) -> int:
	var pd = _ensure_player_data(peer_id)
	if pd["level"] > 0 or pd["character_path"] != "":
		return pd["level"]
	if peer_id == 1:
		return current_level
	return 1

func _get_xp(peer_id: int) -> int:
	var pd = _ensure_player_data(peer_id)
	if pd["xp"] > 0 or pd["character_path"] != "":
		return pd["xp"]
	if peer_id == 1:
		return current_xp
	return 0

func reset_progression():
	current_level = 1
	current_xp = 0
	spawn_position = Vector2(531, 182)
	level_changed.emit(1, current_level)

func reset_all():
	player_data.clear()

func add_xp(peer_id: int, amount: int):
	var pd = _ensure_player_data(peer_id)
	pd["xp"] += amount
	_check_level_up(peer_id)
	level_changed.emit(peer_id, pd["level"])
	xp_gained.emit(peer_id, amount, pd["xp"])
	if multiplayer.multiplayer_peer != null:
		_sync_xp_level.rpc_id(peer_id, pd["xp"], pd["level"])

@rpc("any_peer", "reliable")
func _sync_xp_level(xp: int, level: int):
	var peer_id = multiplayer.get_unique_id()
	var pd = _ensure_player_data(peer_id)
	pd["xp"] = xp
	pd["level"] = level
	xp_gained.emit(peer_id, 0, xp)

func _check_level_up(peer_id: int):
	var pd = _ensure_player_data(peer_id)
	var lvl = pd["level"]
	var xp = pd["xp"]
	while lvl < XP_THRESHOLDS.size() and xp >= XP_THRESHOLDS[lvl]:
		lvl += 1
	pd["level"] = lvl

func get_level(peer_id: int = 1) -> int:
	return _get_level(peer_id)

func get_xp_for_next_level(peer_id: int = 1) -> int:
	var lvl = _get_level(peer_id)
	if lvl >= XP_THRESHOLDS.size():
		return XP_THRESHOLDS[XP_THRESHOLDS.size() - 1]
	return XP_THRESHOLDS[lvl]

func get_xp_for_current_level(peer_id: int = 1) -> int:
	var lvl = _get_level(peer_id)
	if lvl <= 1:
		return 0
	return XP_THRESHOLDS[lvl - 1]

func is_secondary_unlocked(peer_id: int = 1) -> bool:
	return _get_level(peer_id) >= SECONDARY_UNLOCK_LEVEL

func get_scaled_damage(base_damage: int, scale_percent: float, peer_id: int = 1) -> int:
	var lvl = _get_level(peer_id)
	var bonus = base_damage * scale_percent * (lvl - 1)
	return base_damage + int(bonus)

func get_scaled_cooldown(base_cooldown: float, scale_percent: float, peer_id: int = 1) -> float:
	var lvl = _get_level(peer_id)
	var reduction = base_cooldown * scale_percent * (lvl - 1)
	return max(base_cooldown - reduction, 0.1)

func get_scaled_radius(base_radius: float, scale_percent: float, peer_id: int = 1) -> float:
	var lvl = _get_level(peer_id)
	var bonus = base_radius * scale_percent * (lvl - 1)
	return base_radius + bonus

func get_scaled_duration(base_duration: float, scale_percent: float, peer_id: int = 1) -> float:
	var lvl = _get_level(peer_id)
	var bonus = base_duration * scale_percent * (lvl - 1)
	return base_duration + bonus

func get_bonus_projectiles(bonus_levels: Array[int], peer_id: int = 1) -> int:
	var lvl = _get_level(peer_id)
	var bonus = 0
	for level in bonus_levels:
		if lvl >= level:
			bonus += 1
	return bonus

func get_scaled_max_health(base_health: int, hp_per_level: int, peer_id: int = 1) -> int:
	var lvl = _get_level(peer_id)
	return base_health + hp_per_level * (lvl - 1)

func get_damage_reduction(peer_id: int = 1) -> float:
	var lvl = _get_level(peer_id)
	return clamp(0.05 * (lvl - 1), 0.0, 0.20)
