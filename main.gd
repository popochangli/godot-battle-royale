extends Node2D

const PLAYER_SCENE = preload("res://player/player.tscn")
const ENEMY_SCENE = preload("res://enemy/enemy.tscn")

const EFFECT_SCENES = [
	"res://effects/player/player_ice_shard.tscn",
	"res://effects/player/player_bomb.tscn",
	"res://effects/player/player_breath_wave.tscn",
	"res://effects/player/player_freezing_field.tscn",
	"res://effects/player/player_ice_path.tscn",
	"res://effects/player/player_proximity_mine.tscn",
	"res://effects/player/player_shrapnel.tscn",
	"res://effects/player/player_assassin_blade.tscn",
	"res://effects/enemy/enemy_fireball.tscn",
	"res://effects/enemy/enemy_ground_slam.tscn",
	"res://effects/enemy/enemy_poison_arrow.tscn",
	"res://effects/enemy/enemy_ranged_attack.tscn",
]

@onready var players_container = $PlayersContainer
@onready var player_spawner = $PlayersContainer/PlayerSpawner

var _total_players: int = 0
var _death_count: int = 0
var _reported_deaths: Dictionary = {}  # peer_id -> true, ป้องกันนับซ้ำเมื่อ die() ถูกเรียกซ้ำ
@onready var effect_spawner = $EffectsContainer/EffectSpawner
@onready var rpc_effects_container = $RPCEffectsContainer
@onready var enemy_spawner = $EnemiesContainer/EnemySpawner
@onready var collectible_spawner = $CollectiblesContainer/CollectibleSpawner

func _ready():
	collectible_spawner.add_spawnable_scene("res://collectibles/rune/rune.tscn")
	collectible_spawner.add_spawnable_scene("res://collectibles/ore/ore.tscn")

	# ไม่ลงทะเบียน scene กับ EffectSpawner เพื่อป้องกัน auto-replicate/despawn conflict
	# ใช้ RPC (spawn_effect_sync) แทนสำหรับ sync effects ไป clients

	if multiplayer.multiplayer_peer != null:
		player_spawner.spawn_function = _spawn_player
		enemy_spawner.spawn_function = _spawn_enemy
		enemy_spawner.add_spawnable_scene("res://enemy/enemy.tscn")
		if multiplayer.is_server():
			_spawn_all_players()
			_trigger_enemy_camp_spawns()
		NetworkManager.player_disconnected.connect(_on_player_disconnected)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	else:
		_spawn_single_player()
		_trigger_enemy_camp_spawns()

func _on_player_disconnected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.get_multiplayer_authority() == peer_id:
			p.queue_free()
			break
	GameState.player_data.erase(peer_id)
	_check_win_condition()

func _on_server_disconnected() -> void:
	GameState.reset_all()
	NetworkManager.reset()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_player_died(dead_peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if _reported_deaths.get(dead_peer_id, false):
		return  # นับเฉพาะครั้งแรก ป้องกัน die() ถูกเรียกซ้ำจาก poison/zone/etc
	_reported_deaths[dead_peer_id] = true
	_death_count += 1
	var rank = _total_players - _death_count + 1
	var rank_text = "Rank: #%d / %d" % [rank, _total_players]
	var my_id = multiplayer.get_unique_id()
	if dead_peer_id == my_id:
		_display_death_overlay(rank_text)
	else:
		_show_death_rank.rpc_id(dead_peer_id, rank_text)

@rpc("authority", "reliable")
func _show_death_rank(rank_text: String) -> void:
	_display_death_overlay(rank_text)

func _display_death_overlay(rank_text: String) -> void:
	var overlay = preload("res://ui/death_overlay.tscn").instantiate()
	overlay.rank_text = rank_text
	add_child(overlay)

func _announce_winner(winner_peer_id: int) -> void:
	var my_id = multiplayer.get_unique_id()
	if winner_peer_id == my_id:
		_display_winner_overlay()
	else:
		_game_over.rpc_id(winner_peer_id, winner_peer_id)

func _display_winner_overlay() -> void:
	var overlay = preload("res://ui/game_over.tscn").instantiate()
	add_child(overlay)

@rpc("authority", "reliable")
func _game_over(_winner_peer_id: int) -> void:
	_display_winner_overlay()

func _check_win_condition() -> void:
	if not multiplayer.is_server():
		return
	var alive = get_tree().get_nodes_in_group("player").filter(func(p): return p.get("health") and p.health > 0 and not p.is_in_group("player_illusion"))
	if alive.size() == 1:
		_announce_winner(alive[0].get_multiplayer_authority())

const MIN_SPAWN_DISTANCE: float = 60.0  # ระยะห่างขั้นต่ำระหว่างจุดเกิด (ป้องกันตัวซ้อนกัน)

func _get_map_rect() -> Rect2:
	var zm = get_node_or_null("ZoneManager")
	if zm and zm.get("map_rect"):
		return zm.map_rect
	return Rect2(-1000, -1000, 4000, 4000)

func _resolve_spawn_overlaps(peer_ids: Array, positions: Dictionary) -> Dictionary:
	## เลื่อนจุดเกิดที่ใกล้กันให้ห่างออกไปอัตโนมัติ
	var map_rect = _get_map_rect()
	var margin = 32.0
	var valid_rect = Rect2(map_rect.position + Vector2(margin, margin), map_rect.size - Vector2(margin * 2, margin * 2))
	var result: Dictionary = {}

	for pid in peer_ids:
		var pos = positions.get(pid, Vector2(531, 182))
		var pushed = true
		var max_iter = 24
		while pushed and max_iter > 0:
			pushed = false
			max_iter -= 1
			for other_pid in result:
				var other = result[other_pid]
				var dist = pos.distance_to(other)
				if dist < MIN_SPAWN_DISTANCE:
					if dist < 1.0:
						var angle = randf() * TAU
						pos = other + Vector2(cos(angle), sin(angle)) * MIN_SPAWN_DISTANCE
					else:
						pos = other + (pos - other).normalized() * MIN_SPAWN_DISTANCE
					pushed = true
					break
		pos.x = clamp(pos.x, valid_rect.position.x, valid_rect.end.x)
		pos.y = clamp(pos.y, valid_rect.position.y, valid_rect.end.y)
		result[pid] = pos
	return result

func _spawn_all_players() -> void:
	var peers: Array = []
	peers.append(multiplayer.get_unique_id())
	for pid in multiplayer.get_peers():
		peers.append(pid)
	_total_players = peers.size()

	var raw_positions: Dictionary = {}
	for pid in peers:
		raw_positions[pid] = GameState.get_spawn_position(pid)
	var resolved = _resolve_spawn_overlaps(peers, raw_positions)

	for peer_id in peers:
		var spawn_pos = resolved[peer_id]
		var pd = GameState._ensure_player_data(peer_id)
		pd["spawn_position"] = spawn_pos

		var char_path = ""
		if NetworkManager.players_info.has(peer_id):
			char_path = NetworkManager.players_info[peer_id]["character_path"]
		else:
			if pd.has("character_path"):
				char_path = pd["character_path"]
		var data = {"peer_id": peer_id, "spawn_pos": spawn_pos, "character_path": char_path}
		player_spawner.spawn(data)

func _spawn_player(data: Variant) -> Node:
	var dict = data as Dictionary
	var peer_id = dict.get("peer_id", 1)
	var spawn_pos = dict.get("spawn_pos", Vector2(531, 182))
	var char_path = dict.get("character_path", "")

	var player = PLAYER_SCENE.instantiate()
	player.position = spawn_pos
	if char_path:
		var char_data: CharacterData = load(char_path) as CharacterData
		if char_data:
			player.character_data = char_data
	else:
		player.character_data = GameState.get_selected_character(peer_id)

	player.set_multiplayer_authority(peer_id)
	return player

func _spawn_enemy(data: Variant) -> Node:
	var dict = data as Dictionary
	var pos = dict.get("pos", Vector2.ZERO)
	var camp_center = dict.get("camp_center", Vector2.ZERO)
	var patrol_radius = dict.get("patrol_radius", 80.0)
	var leash_range = dict.get("leash_range", 300.0)
	var aggro_timeout = dict.get("aggro_timeout", 8.0)
	var camp_path = dict.get("camp_path", "")
	var is_leader = dict.get("is_leader", false)
	var xp_value = dict.get("xp_value", 25)
	var leader_stats_path = dict.get("leader_stats_path", "")
	var minion_stats_path = dict.get("minion_stats_path", "")
	var leader_skill_path = dict.get("leader_skill_path", "")

	var enemy = ENEMY_SCENE.instantiate()
	enemy.global_position = pos
	enemy.xp_value = xp_value
	if camp_path:
		enemy.set_meta("camp_path", camp_path)
	if leader_stats_path or minion_stats_path:
		if is_leader and leader_stats_path:
			enemy.enemy_stats = load(leader_stats_path) as EnemyStats
			enemy.leader_skill = load(leader_skill_path) as EnemySkillData if leader_skill_path else null
		elif minion_stats_path:
			enemy.enemy_stats = load(minion_stats_path) as EnemyStats
			enemy.leader_skill = null
	enemy.set_camp(null, camp_center, patrol_radius, leash_range, aggro_timeout)
	return enemy

var _effect_spawn_id: int = 0

func get_next_effect_id() -> int:
	_effect_spawn_id += 1
	return _effect_spawn_id

func _spawn_effect(data: Variant) -> Node:
	var dict = data as Dictionary
	var effect = _create_effect_from_data(dict)
	var sid = dict.get("spawn_id", 0)
	effect.name = "Effect_%d" % sid if sid > 0 else "Effect_%d_%d" % [Time.get_ticks_msec(), randi()]
	return effect

func _create_effect_from_data(data: Dictionary) -> Node:
	var scene_path = data.get("scene", "")
	var pos = data.get("pos", Vector2.ZERO)
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return Node.new()
	var scene = load(scene_path) as PackedScene
	var effect = scene.instantiate()
	effect.global_position = pos
	var prop_names = ["direction", "damage", "max_range", "effect_color", "caster_peer_id", "target_position", "explosion_radius", "breath_type"]
	for p in prop_names:
		if data.has(p):
			var val = data[p]
			if p == "effect_color" and val is Array:
				val = Color(val[0], val[1], val[2], val[3]) if val.size() >= 4 else Color.WHITE
			effect.set(p, val)
	return effect

## สร้าง effect บน server และ sync ไป clients ผ่าน RPC
## ใช้ RPCEffectsContainer (ไม่ใช่ EffectsContainer) เพื่อไม่ให้ EffectSpawner track และส่ง despawn ที่ client ไม่มี
func spawn_effect_sync(effect_data: Dictionary) -> Node:
	var effect = _create_effect_from_data(effect_data)
	if effect is Node and effect.get_parent() == null:
		rpc_effects_container.add_child(effect, true)
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		_sync_effect_to_clients.rpc(effect_data)
	return effect

@rpc("any_peer", "reliable")
func _sync_effect_to_clients(effect_data: Dictionary) -> void:
	if multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != 1:
		return
	var effect = _create_effect_from_data(effect_data)
	if effect is Node and effect.get_parent() == null:
		rpc_effects_container.add_child(effect, true)

func _trigger_enemy_camp_spawns() -> void:
	for camp in get_tree().get_nodes_in_group("enemy_camp"):
		if camp.has_method("_spawn_enemies"):
			camp._spawn_enemies()

func _spawn_single_player() -> void:
	_total_players = 1
	var spawn_pos = GameState.get_spawn_position(1)
	var player = PLAYER_SCENE.instantiate()
	player.position = spawn_pos
	player.character_data = GameState.get_selected_character(1)
	player.set_multiplayer_authority(1)
	players_container.add_child(player)
