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
	_apply_layout_fixes()
	for path in CHARACTER_PATHS:
		var data = load(path)
		if data:
			characters.append(data)
			
	$MarginContainer/MainVBox/ContentHBox/LeftVBox/CarouselRow/BtnPrev.pressed.connect(_on_prev_pressed)
	$MarginContainer/MainVBox/ContentHBox/LeftVBox/CarouselRow/BtnNext.pressed.connect(_on_next_pressed)
	$MarginContainer/MainVBox/PlayButton.pressed.connect(_on_play_pressed)
	
	if multiplayer.multiplayer_peer != null:
		_setup_multiplayer()
	else:
		var btn = $MarginContainer/MainVBox/PlayButton
		if btn:
			btn.text = "PLAY"
	
	if ab1_icon:
		ab1_icon.mouse_filter = Control.MOUSE_FILTER_STOP 
		ab1_icon.mouse_entered.connect(func(): _show_ability_desc(1, true))
		ab1_icon.mouse_exited.connect(func(): _show_ability_desc(1, false))
		
	if ab2_icon:
		ab2_icon.mouse_filter = Control.MOUSE_FILTER_STOP
		ab2_icon.mouse_entered.connect(func(): _show_ability_desc(2, true))
		ab2_icon.mouse_exited.connect(func(): _show_ability_desc(2, false))
	
	_update_ui()

func _apply_layout_fixes():
	var title = $MarginContainer/MainVBox/Title
	if title:
		title.add_theme_font_size_override("font_size", 16)
	
	if name_label: name_label.add_theme_font_size_override("font_size", 14)
	if stats_label: stats_label.add_theme_font_size_override("font_size", 10)
	
	var bio_title = $MarginContainer/MainVBox/ContentHBox/RightVBox/BioTitle
	if bio_title: bio_title.add_theme_font_size_override("font_size", 10)
	var abilities_title = $MarginContainer/MainVBox/ContentHBox/RightVBox/AbilitiesTitle
	if abilities_title: abilities_title.add_theme_font_size_override("font_size", 10)
	
	if ab1_name: ab1_name.add_theme_font_size_override("font_size", 9)
	if ab2_name: ab2_name.add_theme_font_size_override("font_size", 9)
	
	var tooltip_bg = StyleBoxFlat.new()
	tooltip_bg.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	tooltip_bg.border_color = Color(0.3, 0.3, 0.5, 0.8)
	tooltip_bg.set_border_width_all(1)
	tooltip_bg.set_corner_radius_all(4)
	tooltip_bg.set_content_margin_all(8)
	
	for desc in [ab1_desc, ab2_desc]:
		if desc:
			desc.add_theme_font_size_override("font_size", 9)
			desc.add_theme_stylebox_override("normal", tooltip_bg)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc.top_level = true
			desc.z_index = 100
			desc.custom_minimum_size = Vector2(180, 0)
			desc.visible = false
	
	var btn_play = $MarginContainer/MainVBox/PlayButton
	if btn_play:
		btn_play.add_theme_font_size_override("font_size", 12)

func _setup_multiplayer() -> void:
	var btn = $MarginContainer/MainVBox/PlayButton
	if btn:
		btn.text = "CONFIRM"
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	if multiplayer.is_server():
		_sync_initial_state()
		# เติม peers ที่เชื่อมต่อก่อนโหลด scene
		for pid in multiplayer.get_peers():
			if not NetworkManager.players_info.has(pid):
				NetworkManager.players_info[pid] = {
					"character_path": "",
					"spawn_pos": Vector2.ZERO,
					"ready": false,
					"character_name": ""
				}
	else:
		await get_tree().process_frame
		NetworkManager.request_full_sync_rpc.rpc_id(1)
		NetworkManager.submit_player_name_rpc.rpc_id(1, multiplayer.get_unique_id(), NetworkManager.my_player_name)

func _sync_initial_state() -> void:
	var my_id = multiplayer.get_unique_id()
	var my_name = NetworkManager.my_player_name if NetworkManager.my_player_name else ""
	if not NetworkManager.players_info.has(my_id):
		NetworkManager.players_info[my_id] = {
			"character_path": "",
			"spawn_pos": Vector2.ZERO,
			"ready": false,
			"character_name": my_name
		}
	else:
		NetworkManager.players_info[my_id]["character_name"] = my_name
	NetworkManager._broadcast_lobby_state()

func _on_player_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		NetworkManager.players_info[peer_id] = {
			"character_path": "",
			"spawn_pos": Vector2.ZERO,
			"ready": false,
			"character_name": ""
		}
		NetworkManager._broadcast_lobby_state()

func _on_player_disconnected(_peer_id: int) -> void:
	if multiplayer.is_server():
		NetworkManager._broadcast_lobby_state()

func _show_ability_desc(index: int, show: bool):
	var target_alpha = 1.0 if show else 0.0
	var label = ab1_desc if index == 1 else ab2_desc
	
	if label:
		if show:
			label.visible = true
			label.global_position = get_global_mouse_position() + Vector2(20, 20)
			
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", target_alpha, 0.2)
		if not show:
			tween.tween_callback(func(): label.visible = false)

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
		ab1_desc.modulate.a = 0.0 
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
		ab2_desc.modulate.a = 0.0 
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
	var char_path = CHARACTER_PATHS[current_index]
	if multiplayer.multiplayer_peer != null:
		var my_id = multiplayer.get_unique_id()
		if multiplayer.is_server():
			NetworkManager.set_character_rpc(my_id, char_path)
		else:
			NetworkManager.set_character_rpc.rpc_id(1, my_id, char_path)
		await get_tree().process_frame
		get_tree().change_scene_to_file("res://ui/lobby.tscn")
	else:
		GameState.selected_character = data
		GameState.reset_progression()
		get_tree().change_scene_to_file("res://ui/spawn_select.tscn")
