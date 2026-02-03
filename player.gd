extends CharacterBody2D

var max_health = 100
var health = 100
var speed = 300

# Cooldowns
var melee_cooldown = 0.5
var melee_timer = 0.0
var projectile_cooldown = 1.0
var projectile_timer = 0.0

@onready var health_bar = $ProgressBar

func _ready():
	add_to_group("player")
	update_health_bar()

func _physics_process(delta):
	# Update cooldown timers
	if melee_timer > 0:
		melee_timer -= delta
	if projectile_timer > 0:
		projectile_timer -= delta
		
	look_at(get_global_mouse_position())
	
	# Movement
	var direction = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	
	if direction.length() > 0:
		direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	# Melee attack (Right Clink)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and melee_timer <= 0:
		melee_attack()
		melee_timer = melee_cooldown
	
	# Projectile attack (Left Click)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and projectile_timer <= 0:
		shoot_projectile()
		projectile_timer = projectile_cooldown
		

func take_damage(amount):
	health -= amount
	print("Took ", amount, " damage! Health: ", health)
	update_health_bar()
	
	if health <= 0:
		die()

func heal(amount):
	health += amount
	if health > max_health:
		health = max_health
	update_health_bar()

func die():
	print("Player died!")
	# Respawn after 2 seconds
	await get_tree().create_timer(2.0).timeout
	health = max_health
	position = Vector2.ZERO  # Respawn at origin
	update_health_bar()

func update_health_bar():
	if health_bar:
		health_bar.value = health

func melee_attack():
	print("MELEE ATTACK!")
	# Create melee hitbox
	var melee = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60
	collision.shape = shape
	melee.add_child(collision)
	add_child(melee)
	
	# Visual feedback - red circle
	var sprite = Sprite2D.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(120, 120)
	sprite.texture = texture
	sprite.modulate = Color(1, 0, 0, 0.5)  # Red semi-transparent
	melee.add_child(sprite)
	
	# Damage enemies in range
	melee.area_entered.connect(func(area):
		if area.get_parent() and area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(30)
			print("Melee hit enemy!")
	)
	
	melee.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != self:
			body.take_damage(30)
			print("Melee hit enemy!")
	)
	
	# Need to enable monitoring
	await get_tree().process_frame
	
	# Remove after 0.2 seconds
	await get_tree().create_timer(0.2).timeout
	melee.queue_free()

func shoot_projectile():
	print("SHOOT PROJECTILE!")
	var projectile = Area2D.new()
	projectile.add_to_group("projectile")
	
	var sprite = Sprite2D.new()
	var texture = PlaceholderTexture2D.new()
	texture.size = Vector2(20, 20)
	sprite.texture = texture
	sprite.modulate = Color(0, 0, 1)
	projectile.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 10
	collision.shape = shape
	projectile.add_child(collision)
	
	projectile.global_position = global_position
	get_parent().add_child(projectile)
	
	var shoot_direction = Vector2.RIGHT.rotated(rotation)
	
	# Connect area entered signal
	projectile.area_entered.connect(func(area):
		if area.get_parent() and area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(20)
			projectile.queue_free()
	)
	
	projectile.body_entered.connect(func(body):
		if body.has_method("take_damage") and body != self:
			body.take_damage(20)
			projectile.queue_free()
	)
	
	var tween = create_tween()
	tween.tween_property(projectile, "global_position", 
		projectile.global_position + shoot_direction * 1000, 2.0)
	tween.tween_callback(projectile.queue_free)
