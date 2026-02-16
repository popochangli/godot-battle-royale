extends Control

const CHARACTER_PATHS = [
	"res://player/characters/data/crystal_maiden.tres",
	"res://player/characters/data/techies.tres",
	"res://player/characters/data/sniper.tres",
	"res://player/characters/data/jakiro.tres"
]

@onready var button_container = $CenterContainer/VBoxContainer/ButtonContainer

func _ready():
	for path in CHARACTER_PATHS:
		var character_data: CharacterData = load(path)
		if character_data:
			var button = Button.new()
			button.text = character_data.display_name
			button.custom_minimum_size = Vector2(200, 50)
			button.pressed.connect(_on_character_selected.bind(character_data))
			button_container.add_child(button)

func _on_character_selected(character_data: CharacterData):
	GameState.selected_character = character_data
	GameState.reset_progression()
	get_tree().change_scene_to_file("res://ui/spawn_select.tscn")
