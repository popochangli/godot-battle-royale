extends Node

static func execute(caster: Node2D, data: AbilityData) -> void:
	if caster.has_meta("active_illusion"):
		var illusion = caster.get_meta("active_illusion")
		
		if is_instance_valid(illusion):
			var pos = illusion.global_position
			caster.global_position = pos
			illusion.queue_free()
			caster.remove_meta("active_illusion")
			return
		else:
			caster.remove_meta("active_illusion")
	
	var mouse_pos = caster.get_global_mouse_position()
	var max_search_dist = 600.0
	
	var enemies = caster.get_tree().get_nodes_in_group("enemy")
	var target = null
	var closest_dist = INF
	
	for enemy in enemies:
		var dist = enemy.global_position.distance_to(mouse_pos)
		if dist < closest_dist and dist < max_search_dist:
			closest_dist = dist
			target = enemy
			
	if target:
		var spawn_pos = target.global_position - (target.global_position - caster.global_position).normalized() * 50.0
		
		var illusion = CharacterBody2D.new()
		illusion.set_script(preload("res://player/abilities/scripts/illusion.gd"))
		
		var sprite = Sprite2D.new()
		sprite.texture = caster.get_node("Sprite2D").texture
		sprite.scale = caster.get_node("Sprite2D").scale
		sprite.modulate = Color(0.3, 0.0, 0.6, 0.8)
		illusion.add_child(sprite)
		
		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 15.0
		collision.shape = shape
		illusion.add_child(collision)
		
		illusion.global_position = spawn_pos
		caster.get_parent().add_child(illusion)
		

		var player_damage = 10.0
		illusion.setup(target, player_damage * 0.3, 3.0, 5.0, caster)
		
		caster.set_meta("active_illusion", illusion)
