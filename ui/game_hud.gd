extends CanvasLayer

@onready var phase_label: Label = $TimerContainer/PhaseLabel
@onready var countdown_label: Label = $TimerContainer/CountdownLabel
@onready var elapsed_label: Label = $TimerContainer/ElapsedLabel
@onready var minimap: Control = $MinimapContainer/Minimap

var zone_manager: Node = null

func _ready():
	_find_zone_manager()

func _find_zone_manager():
	zone_manager = get_tree().get_first_node_in_group("zone_manager")
	if zone_manager == null:
		await get_tree().process_frame
		_search_for_zone_manager(get_tree().root)

	if zone_manager:
		zone_manager.timer_updated.connect(_on_timer_updated)
		zone_manager.phase_started.connect(_on_phase_started)

func _search_for_zone_manager(node: Node):
	if zone_manager != null:
		return
	if node.has_signal("timer_updated"):
		zone_manager = node
		return
	for child in node.get_children():
		_search_for_zone_manager(child)

func _on_timer_updated(time_remaining: float, total_elapsed: float):
	countdown_label.text = _format_time(time_remaining)
	elapsed_label.text = _format_time(total_elapsed)

func _on_phase_started(phase_index: int):
	if phase_index == 0:
		phase_label.text = "PHASE 1"
	else:
		phase_label.text = "PHASE " + str(phase_index + 1)

func _format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]
