extends Node2D

# NEW: Camp configuration system
@export var camp_configs: Array[CampConfig] = []
@export var random_selection: bool = true
@export var fixed_config_index: int = 0

# Original settings (kept for backward compatibility)
@export var enemy_count: int = 3
@export var spawn_radius: float = 50.0
@export var patrol_radius: float = 80.0
@export var leash_range: float = 300.0
@export var aggro_timeout: float = 8.0
@export var enemy_scene: PackedScene

# Respawn system
var active_config: CampConfig = null
var respawn_timer: float = 0.0
var respawn_cooldown: float = 60.0  # 1 minute
var is_cleared: bool = false
var has_spawned: bool = false  # Prevent false clear detection on first frame

func _ready():
	add_to_group("enemy_camp")
	if enemy_scene == null:
		enemy_scene = preload("res://enemy/enemy.tscn")

	# Auto-create configs if none provided
	if camp_configs.size() == 0:
		_create_default_configs()

	_spawn_enemies()

func _process(delta):
	if not has_spawned:
		return

	if not is_cleared:
		# Check if all enemies are dead
		var alive_count = 0
		for child in get_children():
			if child is CharacterBody2D and child.is_in_group("enemy"):
				alive_count += 1
		if alive_count == 0:
			is_cleared = true
			respawn_timer = 0.0
	else:
		# Camp is cleared — count down respawn timer
		respawn_timer += delta
		if respawn_timer >= respawn_cooldown:
			# Only respawn if camp is inside the zone
			var zone_manager = get_tree().get_first_node_in_group("zone_manager")
			if zone_manager and zone_manager.has_method("is_inside_zone"):
				if zone_manager.is_inside_zone(global_position):
					_respawn_camp()
				# If outside zone, don't respawn (timer keeps ticking but we reset)
				else:
					respawn_timer = 0.0
			else:
				_respawn_camp()

func _respawn_camp():
	is_cleared = false
	respawn_timer = 0.0
	# Re-randomize config on respawn
	active_config = null
	_spawn_enemies()

func _spawn_enemies():
	has_spawned = true
	is_cleared = false
	# NEW: Use camp config system if available
	if camp_configs.size() > 0:
		_spawn_configured_enemies()
	else:
		# Fallback to old system (for backward compatibility)
		_spawn_legacy_enemies()

func _spawn_configured_enemies():
	if active_config == null:
		if random_selection:
			active_config = camp_configs.pick_random()
		elif fixed_config_index < camp_configs.size():
			active_config = camp_configs[fixed_config_index]
		else:
			push_warning("Invalid fixed_config_index, using first config")
			active_config = camp_configs[0]

	# XP multiplier based on difficulty tier: tier 1 (hard) = 1.5x, tier 2 (medium) = 1.0x, tier 3 (easy) = 0.7x
	var xp_multiplier = _get_xp_multiplier(active_config.difficulty_tier)

	# Spawn 1 leader
	var leader = enemy_scene.instantiate()
	leader.enemy_stats = active_config.leader_stats
	leader.leader_skill = active_config.leader_skill
	leader.xp_value = int(leader.enemy_stats.xp_value * xp_multiplier) if leader.enemy_stats else 25
	var angle = randf() * TAU
	var dist = randf() * spawn_radius
	var spawn_offset = Vector2(cos(angle), sin(angle)) * dist
	leader.position = spawn_offset
	add_child(leader)
	leader.set_camp(self, global_position, patrol_radius, leash_range, aggro_timeout)

	# Spawn 2 minions
	for i in 2:
		var minion = enemy_scene.instantiate()
		minion.enemy_stats = active_config.minion_stats
		minion.leader_skill = null
		minion.xp_value = int(minion.enemy_stats.xp_value * xp_multiplier) if minion.enemy_stats else 15
		angle = randf() * TAU
		dist = randf() * spawn_radius
		spawn_offset = Vector2(cos(angle), sin(angle)) * dist
		minion.position = spawn_offset
		add_child(minion)
		minion.set_camp(self, global_position, patrol_radius, leash_range, aggro_timeout)

func _get_xp_multiplier(tier: int) -> float:
	match tier:
		1: return 1.5  # Hard camps give most XP
		2: return 1.0  # Medium camps
		3: return 0.7  # Easy camps give least XP
		_: return 1.0

func _spawn_legacy_enemies():
	# Old spawning system (3 identical enemies)
	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate()
		var angle = randf() * TAU
		var dist = randf() * spawn_radius
		var spawn_offset = Vector2(cos(angle), sin(angle)) * dist
		enemy.position = spawn_offset
		add_child(enemy)
		enemy.set_camp(self, global_position, patrol_radius, leash_range, aggro_timeout)

func _create_default_configs():
	# Tank Camp - Ground Slam skill, melee, tanky
	var tank_config = CampConfig.new()
	tank_config.camp_name = "Tank Camp"

	var ground_slam_skill = EnemySkillData.new()
	ground_slam_skill.skill_id = "ground_slam"
	ground_slam_skill.skill_name = "Ground Slam"
	ground_slam_skill.cooldown = 12.0  # Increased cooldown
	ground_slam_skill.damage = 30
	ground_slam_skill.radius = 120.0
	ground_slam_skill.range = 120.0  # Set range same as radius for AoE
	ground_slam_skill.effect_color = Color(0.6, 0.4, 0.2)
	ground_slam_skill.skill_script = preload("res://enemy/skills/ground_slam.gd")

	var tank_leader_stats = EnemyStats.new()
	tank_leader_stats.max_health = 200
	tank_leader_stats.speed = 120
	tank_leader_stats.damage = 15
	tank_leader_stats.attack_range = 50  # Melee
	tank_leader_stats.xp_value = 40
	tank_leader_stats.sprite_scale = 1.3
	tank_leader_stats.color_tint = Color(0.7, 0.5, 0.3)

	var tank_minion_stats = EnemyStats.new()
	tank_minion_stats.max_health = 120
	tank_minion_stats.speed = 100
	tank_minion_stats.damage = 10
	tank_minion_stats.attack_range = 50  # Melee
	tank_minion_stats.xp_value = 25
	tank_minion_stats.sprite_scale = 1.0
	tank_minion_stats.color_tint = Color(0.8, 0.6, 0.4)

	tank_config.leader_skill = ground_slam_skill
	tank_config.leader_stats = tank_leader_stats
	tank_config.minion_stats = tank_minion_stats
	tank_config.difficulty_tier = 2

	# Mage Camp - Fireball skill, ranged, glass cannon
	var mage_config = CampConfig.new()
	mage_config.camp_name = "Mage Camp"

	var fireball_skill = EnemySkillData.new()
	fireball_skill.skill_id = "fireball"
	fireball_skill.skill_name = "Fireball"
	fireball_skill.cooldown = 8.0  # Increased cooldown
	fireball_skill.damage = 25
	fireball_skill.range = 300.0
	fireball_skill.effect_color = Color(1.0, 0.5, 0.1)
	fireball_skill.skill_script = preload("res://enemy/skills/fireball.gd")

	var mage_leader_stats = EnemyStats.new()
	mage_leader_stats.max_health = 120
	mage_leader_stats.speed = 130
	mage_leader_stats.damage = 10
	mage_leader_stats.attack_range = 150  # Ranged
	mage_leader_stats.xp_value = 35
	mage_leader_stats.sprite_scale = 1.2
	mage_leader_stats.color_tint = Color(0.5, 0.3, 0.9)

	var mage_minion_stats = EnemyStats.new()
	mage_minion_stats.max_health = 80
	mage_minion_stats.speed = 110
	mage_minion_stats.damage = 8
	mage_minion_stats.attack_range = 150  # Ranged
	mage_minion_stats.xp_value = 20
	mage_minion_stats.sprite_scale = 0.9
	mage_minion_stats.color_tint = Color(0.6, 0.4, 1.0)

	mage_config.leader_skill = fireball_skill
	mage_config.leader_stats = mage_leader_stats
	mage_config.minion_stats = mage_minion_stats
	mage_config.difficulty_tier = 2

	# Ranged Camp - Poison Arrow skill, fast ranged
	var ranged_config = CampConfig.new()
	ranged_config.camp_name = "Ranged Camp"

	var poison_skill = EnemySkillData.new()
	poison_skill.skill_id = "poison_arrow"
	poison_skill.skill_name = "Poison Arrow"
	poison_skill.cooldown = 10.0  # Increased cooldown
	poison_skill.damage = 15
	poison_skill.range = 350.0
	poison_skill.effect_color = Color(0.3, 0.8, 0.2)
	poison_skill.skill_script = preload("res://enemy/skills/poison_arrow.gd")

	var ranged_leader_stats = EnemyStats.new()
	ranged_leader_stats.max_health = 100
	ranged_leader_stats.speed = 160
	ranged_leader_stats.damage = 12
	ranged_leader_stats.attack_range = 180  # Long ranged
	ranged_leader_stats.xp_value = 35
	ranged_leader_stats.sprite_scale = 1.1
	ranged_leader_stats.color_tint = Color(0.2, 0.8, 0.3)

	var ranged_minion_stats = EnemyStats.new()
	ranged_minion_stats.max_health = 70
	ranged_minion_stats.speed = 140
	ranged_minion_stats.damage = 8
	ranged_minion_stats.attack_range = 180  # Long ranged
	ranged_minion_stats.xp_value = 20
	ranged_minion_stats.sprite_scale = 0.9
	ranged_minion_stats.color_tint = Color(0.3, 0.9, 0.4)

	ranged_config.leader_skill = poison_skill
	ranged_config.leader_stats = ranged_leader_stats
	ranged_config.minion_stats = ranged_minion_stats
	ranged_config.difficulty_tier = 1

	# Add all configs to array
	camp_configs.append(tank_config)
	camp_configs.append(mage_config)
	camp_configs.append(ranged_config)
