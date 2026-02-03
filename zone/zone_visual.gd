extends CanvasLayer

const NEXT_ZONE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.6)
const NEXT_ZONE_WIDTH: float = 2.0
const ZONE_BORDER_COLOR: Color = Color(0.3, 0.5, 1.0, 0.8)
const ZONE_BORDER_WIDTH: float = 4.0
const DASH_LENGTH: float = 20.0
const GAP_LENGTH: float = 10.0

var zone_manager: Node = null
var color_rect: ColorRect
var shader_material: ShaderMaterial
var border_node: Node2D

func _ready():
	layer = 10

	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

	var shader = load("res://zone/zone_overlay.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	color_rect.material = shader_material

	call_deferred("_add_border_to_scene")

func _process(_delta):
	if zone_manager == null:
		zone_manager = get_tree().get_first_node_in_group("zone_manager")
		if zone_manager == null:
			var root = get_tree().root
			for child in root.get_children():
				_find_zone_manager(child)

	if zone_manager == null:
		return

	_update_shader_uniforms()

func _find_zone_manager(node: Node):
	if zone_manager != null:
		return
	if node.has_method("get_zone_info"):
		zone_manager = node
		return
	for child in node.get_children():
		_find_zone_manager(child)

func _update_shader_uniforms():
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return

	var info = zone_manager.get_zone_info()
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera.zoom

	shader_material.set_shader_parameter("zone_center", info["current_center"])
	shader_material.set_shader_parameter("zone_radius", info["current_radius"])
	shader_material.set_shader_parameter("camera_position", camera.global_position)
	shader_material.set_shader_parameter("viewport_size", viewport_size)
	shader_material.set_shader_parameter("camera_zoom", 1.0 / zoom.x)

func _add_border_to_scene():
	border_node = Node2D.new()
	border_node.z_index = 100
	border_node.set_script(load("res://zone/zone_border.gd"))
	get_parent().add_child(border_node)
