extends Control

const CHARACTER_PATHS = [
	"res://player/characters/data/crystal_maiden.tres",
	"res://player/characters/data/techies.tres",
	"res://player/characters/data/sniper.tres",
	"res://player/characters/data/jakiro.tres",
	"res://player/characters/data/spectre.tres",
]

var characters: Array[CharacterData] = []
var current_index: int = 0

@onready var character_texture = $MarginContainer/MainVBox/ContentHBox/LeftVBox/CarouselRow/CharacterDisplay
@onready var name_label = $MarginContainer/MainVBox/ContentHBox/LeftVBox/NameLabel
@onready var stats_label = $MarginContainer/MainVBox/ContentHBox/LeftVBox/StatsLabel

@onready var desc_label = $MarginContainer/MainVBox/ContentHBox/RightVBox/DescLabel

@onready var ab1_icon = $MarginContainer/MainVBox/ContentHBox/RightVBox/AbilitiesHBox/Ability1/Icon
@onready var ab1_name = $MarginContainer/MainVBox/ContentHBox/RightVBox/AbilitiesHBox/Ability1/Name
@onready var ab1_desc = $MarginContainer/MainVBox/ContentHBox/RightVBox/AbilitiesHBox/Ability1/Desc

@onready var ab2_icon = $MarginContainer/MainVBox/ContentHBox/RightVBox/AbilitiesHBox/Ability2/Icon
@onready var ab2_name = $MarginContainer/MainVBox/ContentHBox/RightVBox/AbilitiesHBox/Ability2/Name
@onready var ab2_desc = $MarginContainer/MainVBox/ContentHBox/RightVBox/AbilitiesHBox/Ability2/Desc

func _ready():
	for path in CHARACTER_PATHS:
		var data = load(path)
		if data:
			characters.append(data)
			
	$MarginContainer/MainVBox/ContentHBox/LeftVBox/CarouselRow/BtnPrev.pressed.connect(_on_prev_pressed)
	$MarginContainer/MainVBox/ContentHBox/LeftVBox/CarouselRow/BtnNext.pressed.connect(_on_next_pressed)
	$MarginContainer/MainVBox/PlayButton.pressed.connect(_on_play_pressed)
	
	_update_ui()

func _update_ui():
	if characters.is_empty():
		return
		
	var data = characters[current_index]
	
	name_label.text = data.display_name
	desc_label.text = data.description
	stats_label.text = "HP: %d | Speed: %d" % [data.max_health, data.speed]
	
	if data.icon:
		character_texture.texture = data.icon
	else:
		character_texture.texture = null
		
	if data.primary_ability:
		ab1_name.text = data.primary_ability.display_name
		ab1_desc.text = data.primary_ability.description
		if data.primary_ability.icon:
			ab1_icon.texture = data.primary_ability.icon
		else:
			ab1_icon.texture = null
	else:
		ab1_name.text = "None"
		ab1_desc.text = ""
		ab1_icon.texture = null
		
	if data.secondary_ability:
		ab2_name.text = data.secondary_ability.display_name
		ab2_desc.text = data.secondary_ability.description
		if data.secondary_ability.icon:
			ab2_icon.texture = data.secondary_ability.icon
		else:
			ab2_icon.texture = null
	else:
		ab2_name.text = "None"
		ab2_desc.text = ""
		ab2_icon.texture = null

func _on_next_pressed():
	current_index = (current_index + 1) % characters.size()
	_update_ui()

func _on_prev_pressed():
	current_index = (current_index - 1 + characters.size()) % characters.size()
	_update_ui()

func _on_play_pressed():
	var data = characters[current_index]
	GameState.selected_character = data
	GameState.reset_progression()
	get_tree().change_scene_to_file("res://ui/spawn_select.tscn")
