extends CanvasLayer

var winner_peer_id: int = 1

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var menu_button: Button = $CenterContainer/VBoxContainer/MenuButton

func _ready():
	var my_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer else 1
	if winner_peer_id == my_id:
		title_label.text = "YOU WIN!"
	else:
		title_label.text = "Player %d wins!" % winner_peer_id
	menu_button.pressed.connect(_on_menu_pressed)

func _on_menu_pressed():
	GameState.reset_all()
	NetworkManager.reset()
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
