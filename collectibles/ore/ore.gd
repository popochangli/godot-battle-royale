extends StaticBody2D

@export var ore_data: OreData

var health: int
var max_health: int
var last_attacker: Node = null

@onready var health_bar = $ProgressBar

func _ready():
	add_to_group("ore")
	collision_layer = 2
	collision_mask = 0

	if ore_data:
		max_health = ore_data.max_health
		health = max_health
		_setup_visuals()

	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func _setup_visuals():
	var sprite = $Sprite2D
	if sprite and ore_data:
		sprite.modulate = ore_data.ore_color

func take_damage(amount, attacker: Node = null):
	if attacker:
		last_attacker = attacker

	health -= amount
	update_health_bar()

	if health <= 0:
		die()

func update_health_bar():
	if health_bar:
		health_bar.value = health

func die():
	if last_attacker and last_attacker.is_in_group("player") and ore_data:
		GameState.add_xp(ore_data.xp_value)
	queue_free()
