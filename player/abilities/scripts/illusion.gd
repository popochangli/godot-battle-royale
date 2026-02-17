extends CharacterBody2D

var target: Node2D = null
var damage: float = 10.0
var incoming_damage_multiplier: float = 3.0
var duration: float = 5.0
var caster: Node2D = null

var speed = 280.0
var attack_range = 40.0
var attack_cooldown = 1.0
var attack_timer = 0.0

func setup(tgt: Node2D, dmg: float, dmg_mult: float, dur: float, owner_node: Node2D):
	target = tgt
	damage = dmg
	incoming_damage_multiplier = dmg_mult
	duration = dur
	caster = owner_node
	
	add_to_group("player_ally")
	add_to_group("player_illusion")
	
	get_tree().create_timer(duration).timeout.connect(queue_free)

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta
		
	if not is_instance_valid(target):
		return
		
	var dist = global_position.distance_to(target.global_position)
	
	if dist > attack_range:
		var dir = (target.global_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
	else:
		if attack_timer <= 0:
			attack()
			
func attack():
	attack_timer = attack_cooldown
	if multiplayer.multiplayer_peer == null or multiplayer.is_server():
		if target and target.has_method("take_damage"):
			target.take_damage(damage, caster)
		var tween = create_tween()
		tween.tween_property(self, "modulate:v", 2.0, 0.1) 
		tween.tween_property(self, "modulate:v", 1.0, 0.1)

func take_damage(amount, attacker=null):
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
	var actual_damage = amount * incoming_damage_multiplier
	if not "health" in self:
		self.set_meta("health", 100.0)
		
	var hp = self.get_meta("health") - actual_damage
	self.set_meta("health", hp)
	
	if hp <= 0:
		if is_instance_valid(caster) and caster.has_meta("active_illusion"):
			if caster.get_meta("active_illusion") == self:
				caster.remove_meta("active_illusion")
		queue_free()
