extends Control

@onready var player_list = $CenterContainer/VBoxContainer/PlayerListContainer
@onready var ready_button = $CenterContainer/VBoxContainer/ReadyButton
@onready var start_button = $CenterContainer/VBoxContainer/StartButton
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

func _ready():
	_update_ui()
	NetworkManager.lobby_state_synced.connect(_on_lobby_state_synced)

	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

	if multiplayer.is_server():
		_sync_initial_state()
	else:
		await get_tree().process_frame
		NetworkManager.request_full_sync_rpc.rpc_id(1)

	ready_button.pressed.connect(_on_ready_pressed)
	start_button.pressed.connect(_on_start_pressed)

	multiplayer.connected_to_server.connect(_on_connection_succeeded)

	if not multiplayer.is_server():
		await get_tree().process_frame
		NetworkManager.submit_player_name_rpc.rpc_id(1, multiplayer.get_unique_id(), NetworkManager.my_player_name)

func _on_lobby_state_synced() -> void:
	_refresh_player_display()
	_update_start_button()

func _broadcast_state() -> void:
	NetworkManager._broadcast_lobby_state()

func _sync_initial_state() -> void:
	var my_id = multiplayer.get_unique_id()
	var my_name = NetworkManager.my_player_name if NetworkManager.my_player_name else ""
	if not NetworkManager.players_info.has(my_id):
		NetworkManager.players_info[my_id] = {
			"character_path": "",
			"spawn_pos": Vector2.ZERO,
			"ready": false,
			"character_name": my_name
		}
	else:
		NetworkManager.players_info[my_id]["ready"] = false
		NetworkManager.players_info[my_id]["character_name"] = my_name
	_broadcast_state()

func _on_connection_succeeded() -> void:
	if not multiplayer.is_server():
		NetworkManager.request_full_sync_rpc.rpc_id(1)

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
		_refresh_player_display()

func _on_player_disconnected(_peer_id: int) -> void:
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
	ready_button.disabled = false

func _update_ui() -> void:
	_update_start_button()
	_update_ready_button()
	if multiplayer.is_server():
		_refresh_player_display()

func _on_start_pressed() -> void:
	if multiplayer.is_server():
		_start_game.rpc()
		_start_game()

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
