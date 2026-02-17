class_name HomingProjectile
extends BaseProjectile

var locked_target: Node2D:
	set(value):
		locked_target = value
		_target_ref = weakref(value)

var _target_ref: WeakRef

func _physics_process(delta):
	if not _spawn_ready:
		_spawn_ready = true
		_spawn_position = global_position
		_on_spawned()
		return

	if _hit:
		return

	_lifetime += delta
	if _lifetime > max_lifetime or global_position.distance_to(_spawn_position) > max_range:
		queue_free()
		return

	var target = _target_ref.get_ref() if _target_ref else null
	if not target:
		queue_free()
		return

	_check_hit(delta)

	if not _hit:
		direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
