extends Node

signal timer_updated(time_remaining: float, total_elapsed: float)
signal phase_started(phase_index: int)
signal shrink_started()
signal shrink_completed()
signal next_zone_revealed(center: Vector2, radius: float)

const BASE_DAMAGE_PER_SECOND: float = 5.0
const NEXT_ZONE_REVEAL_TIME: float = 30.0

var map_rect: Rect2
var map_center: Vector2
var map_diagonal: float

var current_phase: int = 0
var game_elapsed_time: float = 0.0
var phase_elapsed_time: float = 0.0

var current_zone_center: Vector2
var current_zone_radius: float
var next_zone_center: Vector2
var next_zone_radius: float

var is_shrinking: bool = false
var shrink_progress: float = 0.0
var next_zone_visible: bool = false

var shrink_start_center: Vector2
var shrink_start_radius: float

var phase_config: Array = [
	{"wait_time": 0.0, "size_percent": 1.0, "shrink_duration": 0.0},
	{"wait_time": 180.0, "size_percent": 0.8, "shrink_duration": 15.0},
	{"wait_time": 120.0, "size_percent": 0.5, "shrink_duration": 10.0},
	{"wait_time": 120.0, "size_percent": 0.2, "shrink_duration": 5.0},
	{"wait_time": 60.0, "size_percent": 0.1, "shrink_duration": 3.0},
]

var accumulated_damage: Dictionary = {}
var _last_synced_phase: int = -1

func _ready():
	_calculate_map_bounds()
	current_zone_center = map_center
	current_zone_radius = map_diagonal / 2.0
	_prepare_next_zone()
	phase_started.emit(0)
	_last_synced_phase = current_phase

	if multiplayer.multiplayer_peer != null:
		var sync = MultiplayerSynchronizer.new()
		sync.name = "ZoneSync"
		sync.set_multiplayer_authority(1)
		var config = SceneReplicationConfig.new()
		config.add_property(NodePath(".:current_zone_center"))
		config.add_property(NodePath(".:current_zone_radius"))
		config.add_property(NodePath(".:next_zone_center"))
		config.add_property(NodePath(".:next_zone_radius"))
		config.add_property(NodePath(".:current_phase"))
		config.add_property(NodePath(".:is_shrinking"))
		config.add_property(NodePath(".:shrink_progress"))
		config.add_property(NodePath(".:next_zone_visible"))
		config.add_property(NodePath(".:game_elapsed_time"))
		config.add_property(NodePath(".:phase_elapsed_time"))
		sync.replication_config = config
		add_child(sync, true)

func _calculate_map_bounds():
	var tilemap = get_tree().get_first_node_in_group("tilemap")
	if tilemap == null:
		var tilemaps = []
		_find_tilemaps(get_tree().root, tilemaps)
		if tilemaps.size() > 0:
			tilemap = tilemaps[0]

	if tilemap and tilemap.has_method("get_used_rect"):
		var used_rect = tilemap.get_used_rect()
		var tile_size = tilemap.tile_set.tile_size if tilemap.tile_set else Vector2i(16, 16)
		map_rect = Rect2(
			Vector2(used_rect.position) * Vector2(tile_size),
			Vector2(used_rect.size) * Vector2(tile_size)
		)
		if tilemap.global_position != Vector2.ZERO:
			map_rect.position += tilemap.global_position
	else:
		map_rect = Rect2(-1000, -1000, 4000, 4000)

	map_center = map_rect.position + map_rect.size / 2.0
	map_diagonal = map_rect.size.length()

func _find_tilemaps(node: Node, result: Array):
	if node is TileMapLayer:
		result.append(node)
	for child in node.get_children():
		_find_tilemaps(child, result)

func _physics_process(delta):
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		if current_phase != _last_synced_phase:
			_last_synced_phase = current_phase
			phase_started.emit(current_phase)
		var time_remaining = _get_time_remaining()
		timer_updated.emit(time_remaining, game_elapsed_time)
		return

	game_elapsed_time += delta
	phase_elapsed_time += delta

	if is_shrinking:
		_process_shrinking(delta)
	else:
		_process_waiting(delta)

	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		_apply_zone_damage(delta)

	var time_remaining = _get_time_remaining()
	timer_updated.emit(time_remaining, game_elapsed_time)

func _process_waiting(delta):
	if current_phase >= phase_config.size() - 1:
		return

	var next_phase = current_phase + 1
	var wait_time = phase_config[next_phase]["wait_time"]
	var time_until_shrink = wait_time - phase_elapsed_time

	if not next_zone_visible and time_until_shrink <= NEXT_ZONE_REVEAL_TIME:
		next_zone_visible = true
		next_zone_revealed.emit(next_zone_center, next_zone_radius)

	if phase_elapsed_time >= wait_time:
		_start_shrinking()

func _process_shrinking(delta):
	var shrink_duration = phase_config[current_phase + 1]["shrink_duration"]
	shrink_progress += delta / shrink_duration

	if shrink_progress >= 1.0:
		shrink_progress = 1.0
		current_zone_center = next_zone_center
		current_zone_radius = next_zone_radius
		is_shrinking = false
		current_phase += 1
		_last_synced_phase = current_phase
		phase_elapsed_time = 0.0
		next_zone_visible = false
		shrink_completed.emit()
		phase_started.emit(current_phase)
		_prepare_next_zone()
	else:
		current_zone_center = shrink_start_center.lerp(next_zone_center, shrink_progress)
		current_zone_radius = lerpf(shrink_start_radius, next_zone_radius, shrink_progress)

func _start_shrinking():
	is_shrinking = true
	shrink_progress = 0.0
	shrink_start_center = current_zone_center
	shrink_start_radius = current_zone_radius
	shrink_started.emit()

func _prepare_next_zone():
	if current_phase >= phase_config.size() - 1:
		next_zone_center = current_zone_center
		next_zone_radius = current_zone_radius
		return

	var next_phase = current_phase + 1
	var next_size_percent = phase_config[next_phase]["size_percent"]
	next_zone_radius = (map_diagonal / 2.0) * next_size_percent

	var max_offset = current_zone_radius - next_zone_radius
	if max_offset <= 0:
		next_zone_center = current_zone_center
	else:
		var angle = randf() * TAU
		var distance = randf() * max_offset
		next_zone_center = current_zone_center + Vector2(cos(angle), sin(angle)) * distance

func _apply_zone_damage(delta):
	var dmg_mult = 1.0 + current_phase * 0.5
	for p in get_tree().get_nodes_in_group("player"):
		if p.get("health") and p.health <= 0:
			continue
		var pid = p.get_multiplayer_authority() if p.has_method("get_multiplayer_authority") else 1
		if not accumulated_damage.has(pid):
			accumulated_damage[pid] = 0.0
		var distance = p.global_position.distance_to(current_zone_center)
		if distance > current_zone_radius:
			accumulated_damage[pid] += BASE_DAMAGE_PER_SECOND * dmg_mult * delta
			if accumulated_damage[pid] >= 1.0:
				var dmg = int(accumulated_damage[pid])
				accumulated_damage[pid] -= dmg
				if p.has_method("take_zone_damage"):
					p.take_zone_damage(float(dmg))
		else:
			accumulated_damage[pid] = 0.0

func _get_time_remaining() -> float:
	if current_phase >= phase_config.size() - 1:
		return 0.0

	if is_shrinking:
		var shrink_duration = phase_config[current_phase + 1]["shrink_duration"]
		return shrink_duration * (1.0 - shrink_progress)
	else:
		var next_phase = current_phase + 1
		var wait_time = phase_config[next_phase]["wait_time"]
		return max(0.0, wait_time - phase_elapsed_time)

func is_inside_zone(pos: Vector2) -> bool:
	return pos.distance_to(current_zone_center) <= current_zone_radius

func get_current_phase() -> int:
	return current_phase

func get_zone_info() -> Dictionary:
	return {
		"current_center": current_zone_center,
		"current_radius": current_zone_radius,
		"next_center": next_zone_center,
		"next_radius": next_zone_radius,
		"next_visible": next_zone_visible
	}
