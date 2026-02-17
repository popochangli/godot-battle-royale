class_name CharacterData
extends Resource

@export var character_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var max_health: int = 100
@export var speed: float = 300.0
@export var primary_ability: Resource
@export var secondary_ability: Resource
@export var hp_per_level: int = 8
@export var sprite_scale: float = 1.0

# 8-direction sprites: south, south-east, east, north-east, north, north-west, west, south-west
@export var direction_sprites: Array[Texture2D] = []
