extends Node

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)
signal connection_succeeded()
signal connection_failed()
signal game_over(winner_peer_id: int)

const PORT = 9999
const MAX_PLAYERS = 4

## peer_id -> {character_path: String, spawn_pos: Vector2, ready: bool, character_name: String}
var players_info: Dictionary = {}

## Set before Host/Join, used by player_name_entry
var my_player_name: String = ""
var connection_mode: String = "host"
var pending_join_ip: String = ""

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connection_succeeded)
	multiplayer.connection_failed.connect(_on_connection_failed)

func host_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		push_error("Failed to create server: " + str(err))
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	var my_id = multiplayer.get_unique_id()
	players_info[my_id] = {"character_path": "", "spawn_pos": Vector2.ZERO, "ready": false, "character_name": ""}
	connection_succeeded.emit()

func join_game(address: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(address, PORT)
	if err != OK:
		push_error("Failed to join game: " + str(err))
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer

func _on_peer_connected(peer_id: int) -> void:
	player_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	players_info.erase(peer_id)
	player_disconnected.emit(peer_id)

func _on_connection_succeeded() -> void:
	connection_succeeded.emit()

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func is_host() -> bool:
	return multiplayer.is_server()

func get_my_id() -> int:
	return multiplayer.get_unique_id()

func reset() -> void:
	multiplayer.multiplayer_peer = null
	players_info.clear()
	my_player_name = ""
	pending_join_ip = ""
	GameState.reset_all()
