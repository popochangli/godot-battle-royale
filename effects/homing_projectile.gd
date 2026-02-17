class_name HomingProjectile
extends BaseProjectile

var target_peer_id: int = -1

var locked_target: Node2D:
	get:
		return _locked_target
	set(value):
		_locked_target = value
		_target_ref = weakref(value) if value else null

var _locked_target: Node2D
var _target_ref: WeakRef

func _get_target() -> Node2D:
	if _target_ref:
		var t = _target_ref.get_ref()
		if t:
			return t
	for p in get_tree().get_nodes_in_group("player"):
		if p.get_multiplayer_authority() == target_peer_id:
			locked_target = p
			_target_ref = weakref(p)
			return p
	return null

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

	var target = _get_target()
	if not target:
		queue_free()
		return

	_check_hit(delta)

	if not _hit:
		direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
