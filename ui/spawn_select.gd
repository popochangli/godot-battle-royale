extends Control

var selected_position: Vector2 = Vector2.ZERO
var has_selected: bool = false
var map_rect: Rect2

@onready var subviewport_container = $SubViewportContainer
@onready var subviewport = $SubViewportContainer/SubViewport
@onready var camera = $SubViewportContainer/SubViewport/Camera2D
@onready var tilemap = $SubViewportContainer/SubViewport/TileMapLayer
@onready var confirm_button = $ConfirmButton
@onready var spawn_marker = $SpawnMarker

func _ready():
	confirm_button.disabled = true
	spawn_marker.visible = false
	spawn_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	GameState.spawn_position = selected_position
	get_tree().change_scene_to_file("res://main.tscn")
