extends CanvasLayer

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

func _ready():
	title_label.text = "Winner!"
	menu_button.pressed.connect(_on_menu_pressed)

func _on_menu_pressed():
	GameState.reset_all()
	NetworkManager.reset()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
