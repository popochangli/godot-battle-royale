extends Control

const CHARACTER_PATHS = [
	"res://player/characters/data/crystal_maiden.tres",
	"res://player/characters/data/techies.tres",
	"res://player/characters/data/sniper.tres",
	"res://player/characters/data/jakiro.tres",
	"res://player/characters/data/spectre.tres",
]

@onready var player_list = $CenterContainer/VBoxContainer/PlayerListContainer
@onready var character_buttons = $CenterContainer/VBoxContainer/CharacterContainer
@onready var ready_button = $CenterContainer/VBoxContainer/ReadyButton
@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

func _ready():
	_build_character_buttons()
	_update_ui()

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

	if multiplayer.is_server():
		_sync_initial_state()
	else:
		# Client: connected_to_server already fired ก่อนโหลด Lobby จึงเรียก request เอง (defer ให้ scene tree พร้อม)
		await get_tree().process_frame
		_request_full_sync.rpc_id(1)

	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)

	multiplayer.connected_to_server.connect(_on_connection_succeeded)

	if not multiplayer.is_server():
		# Client: send our name to server
		await get_tree().process_frame
		_submit_player_name.rpc_id(1, multiplayer.get_unique_id(), NetworkManager.my_player_name)

func _build_character_buttons() -> void:
	for path in CHARACTER_PATHS:
		var character_data: CharacterData = load(path)
		if character_data:
			var btn = Button.new()
			btn.text = character_data.display_name
			btn.custom_minimum_size = Vector2(120, 40)
			btn.pressed.connect(_on_character_picked.bind(path))
			character_buttons.add_child(btn)

func _broadcast_state() -> void:
	if not multiplayer.is_server():
		return
	var peer_ids: Array = []
	var character_paths: Array = []
	var readys: Array = []
	var names: Array = []
	for pid in NetworkManager.players_info:
		var info = NetworkManager.players_info[pid]
		peer_ids.append(pid)
		character_paths.append(info["character_path"])
		readys.append(info["ready"])
		names.append(info["character_name"])
	_sync_lobby_state.rpc(peer_ids, character_paths, readys, names)
	_refresh_player_display()

func _sync_initial_state() -> void:
	var my_id = multiplayer.get_unique_id()
	var my_name = NetworkManager.my_player_name if NetworkManager.my_player_name else ""
	NetworkManager.players_info[my_id] = {
		"character_path": "",
		"spawn_pos": Vector2.ZERO,
		"ready": false,
		"character_name": my_name
	}
	_broadcast_state()

func _on_connection_succeeded() -> void:
	if not multiplayer.is_server():
		_request_full_sync.rpc_id(1)

@rpc("any_peer", "reliable")
func _submit_player_name(peer_id: int, name_text: String) -> void:
	if multiplayer.is_server() and NetworkManager.players_info.has(peer_id):
		NetworkManager.players_info[peer_id]["character_name"] = name_text if name_text else "Player " + str(peer_id)
		_broadcast_state()

@rpc("any_peer", "reliable")
func _request_full_sync() -> void:
	if multiplayer.is_server():
		# broadcast ให้ทุก client (รวมถึงคนที่เพิ่ง join) + server อัปเดต UI ด้วย
		_broadcast_state()

@rpc("authority", "reliable")
func _update_player_list() -> void:
	_refresh_player_display()

@rpc("authority", "reliable")
func _sync_lobby_state(peer_ids: Array, character_paths: Array, readys: Array, names: Array) -> void:
	NetworkManager.players_info.clear()
	for i in peer_ids.size():
		var pid = peer_ids[i]
		NetworkManager.players_info[pid] = {
			"character_path": character_paths[i] if i < character_paths.size() else "",
			"spawn_pos": Vector2.ZERO,
			"ready": readys[i] if i < readys.size() else false,
			"character_name": names[i] if i < names.size() else ""
		}
	_refresh_player_display()

func _refresh_player_display() -> void:
	for child in player_list.get_children():
		child.queue_free()

	_update_ready_button()

	for peer_id in NetworkManager.players_info:
		var info = NetworkManager.players_info[peer_id]
		var label = Label.new()
		var is_me = peer_id == multiplayer.get_unique_id()
		var name_str = info["character_name"] if info["character_name"] else "Player " + str(peer_id)
		var char_str = ""
		if info["character_path"]:
			var cd: CharacterData = load(info["character_path"]) as CharacterData
			if cd:
				char_str = " - " + cd.display_name
		label.text = name_str + char_str + (" (You)" if is_me else "") + " - " + ("Ready" if info["ready"] else "Not ready")
		player_list.add_child(label)

func _on_player_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		NetworkManager.players_info[peer_id] = {
			"character_path": "",
			"spawn_pos": Vector2.ZERO,
			"ready": false,
			"character_name": ""
		}
		# อัปเดต UI ฝั่ง server เท่านั้น — ไม่ broadcast เพราะ client ใหม่ยังโหลด Lobby ไม่เสร็จ
		# client ใหม่จะเรียก _request_full_sync เองหลังโหลด Lobby เสร็จ ซึ่งจะ broadcast ให้ทุกคน
		_refresh_player_display()

func _on_player_disconnected(_peer_id: int) -> void:
	_broadcast_state()

func _on_character_picked(path: String) -> void:
	var my_id = multiplayer.get_unique_id()
	if multiplayer.is_server():
		_set_character(my_id, path)
	else:
		_set_character.rpc_id(1, my_id, path)

@rpc("any_peer", "reliable")
func _set_character(peer_id: int, path: String) -> void:
	if multiplayer.is_server():
		if NetworkManager.players_info.has(peer_id):
			NetworkManager.players_info[peer_id]["character_path"] = path
			# Keep character_name as player name, don't overwrite with character
			_broadcast_state()

func _on_ready_pressed() -> void:
	var my_id = multiplayer.get_unique_id()
	if multiplayer.is_server():
		_toggle_ready(my_id)
	else:
		_toggle_ready.rpc_id(1, my_id)

@rpc("any_peer", "reliable")
func _toggle_ready(peer_id: int) -> void:
	if multiplayer.is_server():
		if NetworkManager.players_info.has(peer_id):
			var info = NetworkManager.players_info[peer_id]
			info["ready"] = not info["ready"]
			_broadcast_state()
			_update_start_button()

func _update_start_button() -> void:
	if not multiplayer.is_server():
		start_button.visible = false
		return
	start_button.visible = true
	var all_ready = true
	for peer_id in NetworkManager.players_info:
		if not NetworkManager.players_info[peer_id]["ready"]:
			all_ready = false
			break
		if not NetworkManager.players_info[peer_id]["character_path"]:
			all_ready = false
			break
	start_button.disabled = not all_ready

func _update_ready_button() -> void:
	var my_id = multiplayer.get_unique_id()
	var has_character = false
	if NetworkManager.players_info.has(my_id):
		has_character = NetworkManager.players_info[my_id]["character_path"] != ""
	ready_button.disabled = not has_character

func _update_ui() -> void:
	_update_start_button()
	_update_ready_button()
	if multiplayer.is_server():
		_refresh_player_display()

func _on_start_pressed() -> void:
	if multiplayer.is_server():
		_start_game.rpc()
		_start_game()  # Server ต้องเปลี่ยน scene ด้วย (RPC ไม่ execute บน caller)

@rpc("authority", "reliable")
func _start_game() -> void:
	for pid in NetworkManager.players_info:
		var info = NetworkManager.players_info[pid]
		var pd = GameState._ensure_player_data(pid)
		pd["character_path"] = info["character_path"]
		pd["selected_character"] = load(info["character_path"]) as CharacterData if info["character_path"] else null
		pd["level"] = 1
		pd["xp"] = 0
		pd["spawn_position"] = Vector2(531, 182)
		pd["spawn_confirmed"] = false
	get_tree().change_scene_to_file("res://ui/spawn_select.tscn")
