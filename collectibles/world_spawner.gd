extends Node

@export var rune_spawn_interval: float = 15.0
@export var ore_spawn_interval: float = 20.0
@export var max_runes: int = 5
@export var max_ores: int = 8

var rune_scene = preload("res://collectibles/rune/rune.tscn")
var ore_scene = preload("res://collectibles/ore/ore.tscn")
var health_rune_data = preload("res://collectibles/rune/data/health_rune.tres")
var iron_ore_data = preload("res://collectibles/ore/data/iron_ore.tres")

var rune_timer: float = 0.0
var ore_timer: float = 0.0
var zone_manager: Node = null

func _ready():
	zone_manager = get_tree().get_first_node_in_group("zone_manager")

func _physics_process(delta):
	if zone_manager == null:
		zone_manager = get_tree().get_first_node_in_group("zone_manager")
		if zone_manager == null:
			return

	rune_timer += delta
	ore_timer += delta

	if rune_timer >= rune_spawn_interval:
		rune_timer = 0.0
		_try_spawn_rune()

	if ore_timer >= ore_spawn_interval:
		ore_timer = 0.0
		_try_spawn_ore()

func _try_spawn_rune():
	var current_runes = get_tree().get_nodes_in_group("rune").size()
	if current_runes >= max_runes:
		return

	var spawn_pos = _get_random_zone_position()
	if spawn_pos == Vector2.ZERO:
		return

	var rune = rune_scene.instantiate()
	rune.rune_data = health_rune_data
	rune.global_position = spawn_pos
	get_parent().add_child(rune)

func _try_spawn_ore():
	var current_ores = get_tree().get_nodes_in_group("ore").size()
	if current_ores >= max_ores:
		return

	var spawn_pos = _get_random_zone_position()
	if spawn_pos == Vector2.ZERO:
		return

	var ore = ore_scene.instantiate()
	ore.ore_data = iron_ore_data
	ore.global_position = spawn_pos
	get_parent().add_child(ore)

func _get_random_zone_position() -> Vector2:
	if zone_manager == null or not zone_manager.has_method("get_zone_info"):
		return Vector2.ZERO

	var zone_info = zone_manager.get_zone_info()
	var center = zone_info["current_center"]
	var radius = zone_info["current_radius"]

	var angle = randf() * TAU
	var dist = randf() * radius * 0.8
	return center + Vector2(cos(angle), sin(angle)) * dist
