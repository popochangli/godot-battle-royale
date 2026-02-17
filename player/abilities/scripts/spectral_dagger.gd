extends Node

static func execute(caster: Node2D, data: AbilityData, mouse_pos: Vector2 = Vector2.ZERO) -> void:
	if mouse_pos == Vector2.ZERO:
		mouse_pos = caster.get_global_mouse_position()
	var direction = (mouse_pos - caster.global_position).normalized()
	var range_dist = data.range_distance
	var peer_id = caster.get("peer_id") if caster.get("peer_id") else 1

	var area = Area2D.new()
	area.monitorable = false
	area.monitoring = true
	area.collision_layer = 0
	area.collision_mask = 2

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(range_dist, range_dist)
	collision.shape = shape
	collision.position = Vector2(range_dist / 2.0, 0)
	area.add_child(collision)

	var slash = Polygon2D.new()
	slash.polygon = PackedVector2Array([
		Vector2(0, -10),
		Vector2(range_dist, -range_dist / 2.0),
		Vector2(range_dist, range_dist / 2.0),
		Vector2(0, 10)
	])
	slash.color = Color(0.8, 0.0, 0.8, 0.6)
	area.add_child(slash)

	area.global_position = caster.global_position
	area.rotation = direction.angle()

	var container = caster.get_tree().get_first_node_in_group("effects_container")
	if container:
		container.add_child(area, true)
	else:
		caster.get_parent().add_child(area, true)

	var mp = caster.get_tree().multiplayer
	if mp.multiplayer_peer != null and caster.has_method("_broadcast_spectral_visual"):
		caster._broadcast_spectral_visual.rpc(caster.global_position, direction.angle(), range_dist)

	var timer = caster.get_tree().create_timer(0.034)
	await timer.timeout
	await caster.get_tree().physics_frame

	if mp.multiplayer_peer == null or mp.is_server():
		var damage = GameState.get_scaled_damage(data.damage, data.damage_scale_percent, peer_id)
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			if body != caster and body.has_method("take_damage"):
				body.take_damage(damage, caster)

	var tween = slash.create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(area.queue_free)
