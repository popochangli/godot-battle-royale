extends Control

var selected_position: Vector2 = Vector2.ZERO
var has_selected: bool = false
var map_rect: Rect2

@onready var subviewport_container = $SubViewportContainer
@onready var subviewport = $SubViewportContainer/SubViewport
@onready var camera = $SubViewportContainer/SubViewport/Camera2D
@onready var tilemap = $SubViewportContainer/SubViewport/TileMapLayer
@onready var confirm_button = $ConfirmButton
@onready var start_button = $StartButton
@onready var spawn_marker = $SpawnMarker

var _status_label: Label

func _ready():
	if multiplayer.multiplayer_peer != null:
		_status_label = Label.new()
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_status_label.add_theme_font_size_override("font_size", 16)
		_status_label.position = Vector2(20, 55)
		_status_label.size = Vector2(600, 24)
		_status_label.text = "Select your spawn location"
		add_child(_status_label)
	confirm_button.disabled = true
	spawn_marker.visible = false
	spawn_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if start_button:
		start_button.visible = false
		start_button.disabled = true
		start_button.pressed.connect(_on_start_pressed)

	var used_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	map_rect = Rect2(
		Vector2(used_rect.position) * Vector2(tile_size),
		Vector2(used_rect.size) * Vector2(tile_size)
	)

	var viewport_size = subviewport.size
	var zoom_x = float(viewport_size.x) / map_rect.size.x
	var zoom_y = float(viewport_size.y) / map_rect.size.y
	var zoom_level = min(zoom_x, zoom_y) * 0.95
	camera.zoom = Vector2(zoom_level, zoom_level)
	camera.position = map_rect.position + map_rect.size / 2

func _process(_delta):
	if multiplayer.multiplayer_peer == null:
		return
	if not multiplayer.is_server():
		return
	if start_button == null:
		return
	var total = NetworkManager.players_info.size()
	if total == 0:
		return
	var confirmed = 0
	for pid in NetworkManager.players_info:
		if GameState._ensure_player_data(pid).get("spawn_confirmed"):
			confirmed += 1
	var all_confirmed = confirmed >= total
	start_button.visible = all_confirmed
	start_button.disabled = not all_confirmed
	if all_confirmed and _status_label:
		_status_label.text = "All players confirmed. Host can start the game."

func _on_start_pressed():
	if multiplayer.is_server():
		_load_game.rpc()

func _on_sub_viewport_container_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = subviewport_container.get_local_mouse_position()
		var container_size = subviewport_container.size

		var normalized_x = local_pos.x / container_size.x
		var normalized_y = local_pos.y / container_size.y

		var view_size = Vector2(subviewport.size) / camera.zoom.x
		var view_top_left = camera.position - view_size / 2

		selected_position = view_top_left + Vector2(
			normalized_x * view_size.x,
			normalized_y * view_size.y
		)

		selected_position.x = clamp(selected_position.x, map_rect.position.x + 50, map_rect.end.x - 50)
		selected_position.y = clamp(selected_position.y, map_rect.position.y + 50, map_rect.end.y - 50)

		has_selected = true
		confirm_button.disabled = false
		_update_marker_position(local_pos)

func _update_marker_position(local_pos: Vector2):
	var container_global_pos = subviewport_container.global_position
	spawn_marker.position = container_global_pos + local_pos - spawn_marker.size / 2
	spawn_marker.visible = true

func _on_confirm_button_pressed():
	if multiplayer.multiplayer_peer != null:
		var my_id = multiplayer.get_unique_id()
		if multiplayer.is_server():
			_submit_spawn(my_id, selected_position)  # Host runs directly
		else:
			_submit_spawn.rpc_id(1, my_id, selected_position)
		confirm_button.disabled = true
		if _status_label:
			_status_label.text = "Waiting for other players..."
	else:
		GameState.spawn_position = selected_position
		var pd = GameState._ensure_player_data(1)
		pd["spawn_position"] = selected_position
		pd["spawn_confirmed"] = true
		get_tree().change_scene_to_file("res://main.tscn")

@rpc("any_peer", "reliable")
func _submit_spawn(peer_id: int, pos: Vector2):
	if not multiplayer.is_server():
		return
	var pd = GameState._ensure_player_data(peer_id)
	pd["spawn_position"] = pos
	pd["spawn_confirmed"] = true

@rpc("authority", "reliable", "call_local")
func _load_game():
	get_tree().change_scene_to_file("res://main.tscn")
