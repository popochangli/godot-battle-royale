extends Control

var connection_mode: String = "host"  # "host" or "join"

@onready var name_input = $CenterContainer/VBoxContainer/NameInput
@onready var action_button = $CenterContainer/VBoxContainer/ActionButton
@onready var back_button = $CenterContainer/VBoxContainer/BackButton
@onready var status_label = $CenterContainer/VBoxContainer/StatusLabel

func _ready():
	connection_mode = NetworkManager.connection_mode if NetworkManager.connection_mode else "host"
	
	if connection_mode == "join":
		action_button.text = "Join Game"
		status_label.text = "Enter your name to join"
	else:
		action_button.text = "Host Game"
		status_label.text = "Enter your name"
	
	action_button.pressed.connect(_on_action_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _on_action_pressed():
	var name_text = name_input.text.strip_edges()
	if name_text.is_empty():
		status_label.text = "Please enter your name"
		return
	
	NetworkManager.my_player_name = name_text
	action_button.disabled = true
	
	if connection_mode == "host":
		status_label.text = "Starting server..."
		NetworkManager.host_game()
	else:
		var ip = NetworkManager.pending_join_ip
		if ip.is_empty():
			status_label.text = "No server address"
			action_button.disabled = false
			return
		status_label.text = "Connecting..."
		NetworkManager.join_game(ip.strip_edges())

func _on_back_pressed():
	NetworkManager.connection_succeeded.disconnect(_on_connection_succeeded)
	NetworkManager.connection_failed.disconnect(_on_connection_failed)
	NetworkManager.reset()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_connection_succeeded():
	if NetworkManager.is_host():
		var my_id = multiplayer.get_unique_id()
		if NetworkManager.players_info.has(my_id):
			NetworkManager.players_info[my_id]["character_name"] = NetworkManager.my_player_name
	NetworkManager.connection_succeeded.disconnect(_on_connection_succeeded)
	NetworkManager.connection_failed.disconnect(_on_connection_failed)
	get_tree().change_scene_to_file("res://ui/lobby.tscn")

func _on_connection_failed():
	status_label.text = "Connection failed"
	action_button.disabled = false
