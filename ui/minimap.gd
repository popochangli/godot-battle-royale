extends Control

const MINIMAP_SIZE: float = 90
const WORLD_VIEW_RADIUS: float = 800.0

const BACKGROUND_COLOR: Color = Color(0.1, 0.1, 0.15, 0.8)
const BORDER_COLOR: Color = Color(0.4, 0.4, 0.5, 1.0)
const PLAYER_COLOR: Color = Color(0.2, 1.0, 0.3, 1.0)
const ENEMY_COLOR: Color = Color(1.0, 0.3, 0.2, 1.0)
const CAMP_COLOR: Color = Color(1.0, 0.6, 0.2, 1.0)
const ZONE_COLOR: Color = Color(0.3, 0.5, 1.0, 0.6)
const NEXT_ZONE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.4)
const DANGER_ZONE_COLOR: Color = Color(1.0, 0.2, 0.1, 0.35)
const ZONE_BORDER_COLOR: Color = Color(0.3, 0.5, 1.0, 0.8)

const PLAYER_DOT_SIZE: float = 5.0
const ENEMY_DOT_SIZE: float = 3.0
const CAMP_SIZE: float = 6.0

var player: Node2D = null
var zone_manager: Node = null

func _ready():
	custom_minimum_size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE)
	clip_contents = true

func _process(_delta):
	if player == null:
		if multiplayer.multiplayer_peer == null:
			player = get_tree().get_first_node_in_group("player")
		else:
			for p in get_tree().get_nodes_in_group("player"):
				if p.is_multiplayer_authority():
					player = p
					break
			if player == null:
				player = get_tree().get_first_node_in_group("player")
	if zone_manager == null:
		zone_manager = get_tree().get_first_node_in_group("zone_manager")
		if zone_manager == null:
			for node in get_tree().root.get_children():
				_find_zone_manager(node)
	queue_redraw()

func _find_zone_manager(node: Node):
	if zone_manager != null:
		return
	if node.has_method("get_zone_info"):
		zone_manager = node
		return
	for child in node.get_children():
		_find_zone_manager(child)

func _draw():
	var center = Vector2(MINIMAP_SIZE / 2.0, MINIMAP_SIZE / 2.0)
	var radius = MINIMAP_SIZE / 2.0

	draw_circle(center, radius, BACKGROUND_COLOR)

	if player == null:
		draw_arc(center, radius - 1, 0, TAU, 64, BORDER_COLOR, 2.0)
		return

	var player_world_pos = player.global_position

	if zone_manager != null:
		var info = zone_manager.get_zone_info()
		_draw_danger_zone(player_world_pos, info["current_center"], info["current_radius"])
		if info["next_visible"]:
			_draw_next_zone_outline(player_world_pos, info["next_center"], info["next_radius"])

	var camps = get_tree().get_nodes_in_group("enemy_camp")
	for camp in camps:
		var minimap_pos = world_to_minimap(camp.global_position, player_world_pos)
		if _is_in_minimap(minimap_pos):
			var half = CAMP_SIZE / 2.0
			var camp_rect = Rect2(minimap_pos.x - half, minimap_pos.y - half, CAMP_SIZE, CAMP_SIZE)
			draw_rect(camp_rect, CAMP_COLOR)

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var minimap_pos = world_to_minimap(enemy.global_position, player_world_pos)
		if _is_in_minimap(minimap_pos):
			draw_circle(minimap_pos, ENEMY_DOT_SIZE, ENEMY_COLOR)

	draw_circle(center, PLAYER_DOT_SIZE, PLAYER_COLOR)

func world_to_minimap(world_pos: Vector2, player_pos: Vector2) -> Vector2:
	var offset = world_pos - player_pos
	var normalized = offset / WORLD_VIEW_RADIUS
	var center = Vector2(MINIMAP_SIZE / 2.0, MINIMAP_SIZE / 2.0)
	return center + normalized * (MINIMAP_SIZE / 2.0)

func _is_in_minimap(pos: Vector2) -> bool:
	var center = Vector2(MINIMAP_SIZE / 2.0, MINIMAP_SIZE / 2.0)
	return pos.distance_to(center) < (MINIMAP_SIZE / 2.0 - 2.0)

func _draw_danger_zone(player_pos: Vector2, zone_center: Vector2, zone_radius: float):
	var center = Vector2(MINIMAP_SIZE / 2.0, MINIMAP_SIZE / 2.0)
	var minimap_zone_center = world_to_minimap(zone_center, player_pos)
	var minimap_zone_radius = (zone_radius / WORLD_VIEW_RADIUS) * (MINIMAP_SIZE / 2.0)

	draw_circle(center, MINIMAP_SIZE / 2.0, DANGER_ZONE_COLOR)

	if minimap_zone_radius > 0:
		draw_circle(minimap_zone_center, minimap_zone_radius, BACKGROUND_COLOR)

	draw_arc(minimap_zone_center, minimap_zone_radius, 0, TAU, 64, ZONE_BORDER_COLOR, 2.0)

func _draw_next_zone_outline(player_pos: Vector2, zone_center: Vector2, zone_radius: float):
	var minimap_center = world_to_minimap(zone_center, player_pos)
	var minimap_radius = (zone_radius / WORLD_VIEW_RADIUS) * (MINIMAP_SIZE / 2.0)

	if minimap_radius < 1.0:
		return

	draw_arc(minimap_center, minimap_radius, 0, TAU, 64, NEXT_ZONE_COLOR, 2.0)
