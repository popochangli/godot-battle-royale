extends Control

@onready var host_button = $CenterContainer/VBoxContainer/HostButton
@onready var join_container = $CenterContainer/VBoxContainer/JoinContainer
@onready var ip_input = $CenterContainer/VBoxContainer/JoinContainer/IPInput
@onready var join_button = $CenterContainer/VBoxContainer/JoinContainer/JoinButton
@onready var single_player_button = $CenterContainer/VBoxContainer/SinglePlayerButton
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	single_player_button.pressed.connect(_on_single_player_pressed)

	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.player_connected.connect(_on_player_connected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_set_status("")

func _on_server_disconnected() -> void:
	_set_status("Host disconnected")
	host_button.disabled = false
	join_button.disabled = false

func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

func _on_host_pressed() -> void:
	NetworkManager.reset()
	_set_status("Starting server...")
	host_button.disabled = true
	NetworkManager.host_game()

func _on_join_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	if ip.is_empty():
		_set_status("Enter IP address")
		return
	NetworkManager.reset()
	_set_status("Connecting...")
	join_button.disabled = true
	NetworkManager.join_game(ip)

func _on_single_player_pressed() -> void:
	NetworkManager.reset()
	get_tree().change_scene_to_file("res://ui/character_select.tscn")

func _on_connection_succeeded() -> void:
	if NetworkManager.is_host():
		_set_status("Waiting for players...")
		get_tree().change_scene_to_file("res://ui/lobby.tscn")
	else:
		_set_status("Connected! Waiting for host...")
		get_tree().change_scene_to_file("res://ui/lobby.tscn")

func _on_connection_failed() -> void:
	_set_status("Connection failed")
	host_button.disabled = false
	join_button.disabled = false

func _on_player_connected(_peer_id: int) -> void:
	if NetworkManager.is_host():
		_set_status("Player connected")
