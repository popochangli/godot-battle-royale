extends Node2D

const ZONE_BORDER_COLOR: Color = Color(0.3, 0.5, 1.0, 0.8)
const ZONE_BORDER_WIDTH: float = 4.0
const NEXT_ZONE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)
const NEXT_ZONE_WIDTH: float = 2.0
const DASH_LENGTH: float = 20.0
const GAP_LENGTH: float = 10.0

var zone_manager: Node = null

func _ready():
	z_index = 100

func _process(_delta):
	if zone_manager == null:
		zone_manager = get_tree().get_first_node_in_group("zone_manager")
	queue_redraw()

func _draw():
	if zone_manager == null:
		return

	var info = zone_manager.get_zone_info()
	var center = info["current_center"]
	var radius = info["current_radius"]

	draw_arc(center, radius, 0, TAU, 128, ZONE_BORDER_COLOR, ZONE_BORDER_WIDTH)

	if info["next_visible"]:
		_draw_next_zone_preview(info["next_center"], info["next_radius"])

func _draw_next_zone_preview(center: Vector2, radius: float):
	var circumference = TAU * radius
	var total_pattern = DASH_LENGTH + GAP_LENGTH
	var num_dashes = int(circumference / total_pattern)

	for i in range(num_dashes):
		var start_angle = (float(i) * total_pattern) / radius
		var end_angle = start_angle + (DASH_LENGTH / radius)
		draw_arc(center, radius, start_angle, end_angle, 8, NEXT_ZONE_COLOR, NEXT_ZONE_WIDTH)
