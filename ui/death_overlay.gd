extends CanvasLayer

var rank: int = 1
var total_players: int = 1

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var rank_label: Label = $CenterContainer/VBoxContainer/RankLabel
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

func _ready():
	title_label.text = "You were eliminated"
	rank_label.text = "Rank: #%d / %d" % [rank, total_players]
	menu_button.pressed.connect(_on_menu_pressed)

func _on_menu_pressed():
	GameState.reset_all()
	NetworkManager.reset()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
