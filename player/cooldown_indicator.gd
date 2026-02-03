extends Control

@export var cooldown_max: float = 1.0
@export var cooldown_current: float = 0.0
@export var indicator_size: float = 40.0
@export var background_color: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var fill_color: Color = Color(1, 1, 1, 0.9)
@export var indicator_color: Color = Color.WHITE

func _ready():
	custom_minimum_size = Vector2(indicator_size, indicator_size)

func _process(_delta):
	queue_redraw()

func _draw():
	var center = size / 2
	var radius = min(size.x, size.y) / 2 - 2

	draw_circle(center, radius, background_color)

	if cooldown_current > 0 and cooldown_max > 0:
		var ratio = clamp(cooldown_current / cooldown_max, 0.0, 1.0)
		var angle = ratio * TAU
		var start_angle = -PI / 2

		var points = PackedVector2Array()
		points.append(center)

		var segments = 32
		for i in range(segments + 1):
			var t = float(i) / segments
			var current_angle = start_angle + t * angle
			points.append(center + Vector2(cos(current_angle), sin(current_angle)) * radius)

		if points.size() > 2:
			draw_polygon(points, PackedColorArray([fill_color]))

	draw_arc(center, radius, 0, TAU, 32, Color(0.5, 0.5, 0.5, 1), 2.0)
