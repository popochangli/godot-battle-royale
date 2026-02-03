extends CharacterBody2D

var speed = 150
var max_health = 50
var health = 50
var damage = 10
var attack_range = 100
var attack_cooldown = 1.0
var attack_timer = 0.0

var player = null

@onready var health_bar = $ProgressBar

func _ready():
	update_health_bar()

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta
	
	# Find player if we don't have reference
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Move toward player
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# Face player
		look_at(player.global_position)
		
		# Attack if close enough
		var distance = global_position.distance_to(player.global_position)
		if distance < attack_range and attack_timer <= 0:
			attack_player()
			attack_timer = attack_cooldown

func attack_player():
	if player and player.has_method("take_damage"):
		player.take_damage(damage)
		print("Enemy attacked player!")

func take_damage(amount):
	health -= amount
	print("Enemy took ", amount, " damage! Health: ", health)
	update_health_bar()
	
	# Flash white when hit
	$Sprite2D.modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.modulate = Color.RED
	
	if health <= 0:
		die()

func die():
	print("Enemy died!")
	queue_free()

func update_health_bar():
	if health_bar:
		health_bar.value = health
