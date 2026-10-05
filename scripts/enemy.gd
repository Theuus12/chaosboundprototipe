extends CharacterBody3D

@export var move_speed: float = 4.5
const GOBLIN_BASE_HEALTH: int = 9
const SKELETON_BASE_HEALTH: int = 15
@export var max_health: int = GOBLIN_BASE_HEALTH
var base_health: int = GOBLIN_BASE_HEALTH
@export var contact_damage: int = 10
@export var model_path: String = "res://assets/characters/goblin/goblin.glb"
const MAGNET_DROP_CHANCE: float = 0.005
var health: int
var target: CharacterBody3D
var agent: NavigationAgent3D
var health_bar: Node3D
var visual: Node3D
var hit_flash: float = 0.0
var repath_left: float = 0.0
var knockback: Vector3 = Vector3.ZERO
var knockback_resistance: float = 1.0
var animation_credit := 0.0
var direct_chase := false
var crowd_velocity := Vector3.ZERO
var crowd_velocity_ready := false

func apply_knockback(origin: Vector3, force: float) -> void:
	var away := global_position - origin
	away.y = 0.0
	knockback += away.normalized() * force / knockback_resistance

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	base_health = max_health
	collision_layer = 4
	# A separação da multidão fica a cargo do RVO, sem contatos físicos par a par.
	collision_mask = 1 | 2
	max_slides = 2
	floor_snap_length = 0.6
	floor_max_angle = deg_to_rad(45.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.4
	shape.shape = capsule
	shape.position.y = 0.7
	add_child(shape)
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/goblin_visual.gd"))
	visual.set("model_path", model_path)
	add_child(visual)
	agent = NavigationAgent3D.new()
	# O mapa fica ligeiramente acima do piso devido aos voxels do bake.
	# A tolerancia deve incluir essa altura para avancar os pontos do caminho.
	agent.path_desired_distance = 0.9
	agent.target_desired_distance = 0.9
	agent.avoidance_enabled = true
	agent.radius = 0.5
	agent.height = 1.4
	agent.neighbor_distance = 3.0
	agent.max_neighbors = 8
	agent.time_horizon_agents = 0.35
	agent.velocity_computed.connect(func(safe: Vector3): crowd_velocity = safe; crowd_velocity_ready = true)
	repath_left = randf_range(0.0, 0.5)
	add_child(agent)
	health_bar = Node3D.new()
	health_bar.set_script(preload("res://scripts/health_bar_3d.gd"))
	health_bar.position.y = 2.05
	add_child(health_bar)
	health_bar.call("set_health", health, max_health)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.get("dead"):
		return
	hit_flash = maxf(hit_flash - delta, 0.0)
	animation_credit += delta
	var view_distance := global_position.distance_squared_to(target.global_position)
	var animation_interval := 1.0 / 30.0 if view_distance < 625 else 1.0 / 10.0
	if animation_credit >= animation_interval:
		if view_distance < 4225:
			visual.call("animate", animation_credit, Vector2(velocity.x, velocity.z).length(), velocity.y > 0.5, hit_flash > 0.0)
		animation_credit = 0.0
	if not is_on_floor():
		velocity.y -= 28.0 * delta
	else:
		velocity.y = 0.0
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	repath_left -= delta
	if repath_left <= 0.0:
		var sight := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.7, target.global_position + Vector3.UP * 0.7, 1)
		direct_chase = absf(target.global_position.y - global_position.y) < 0.8 and get_world_3d().direct_space_state.intersect_ray(sight).is_empty()
		agent.target_position = target.global_position
		repath_left = 0.5 + randf_range(0.0, 0.1)
	var direction := Vector3.ZERO
	# A consulta também sincroniza a posição do agente usada pelo desvio RVO.
	# Ela é necessária mesmo quando seguimos diretamente o jogador.
	var next_point := agent.get_next_path_position()
	if direct_chase:
		direction = target.global_position - global_position
		direction.y = 0.0
		direction = direction.normalized()
	else:
		# Obstáculos e desníveis ainda usam a rota do NavigationAgent.
		if not agent.is_navigation_finished():
			direction = next_point - global_position
			direction.y = 0.0
			direction = direction.normalized()
	velocity.x = direction.x * move_speed + knockback.x
	velocity.z = direction.z * move_speed + knockback.z
	agent.max_speed = maxf(move_speed, Vector2(velocity.x, velocity.z).length())
	agent.velocity = Vector3(velocity.x, 0, velocity.z)
	if crowd_velocity_ready:
		velocity.x = crowd_velocity.x
		velocity.z = crowd_velocity.z
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 10.0, 1.0))
		# O caminho permite degraus baixos; o corpo precisa subir esses degraus.
		if not direct_chase and is_on_floor() and test_move(global_transform, direction * 0.2):
			var raised := global_transform
			raised.origin.y += 0.3
			if not test_move(global_transform, Vector3.UP * 0.3) and not test_move(raised, direction * 0.2):
				global_position.y += 0.3
	move_and_slide()
	# Inclui contatos nas duas direcoes, mesmo quando o jogador empurra o inimigo.
	var offset := target.global_position - global_position
	if Vector2(offset.x, offset.z).length() <= 0.95 and offset.y < 1.4 and offset.y > -1.8:
		target.call("take_damage", contact_damage, self)
	if global_position.y < -15.0:
		queue_free()

func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	var previous_health := health
	health = maxi(0, health - amount)
	preload("res://scripts/hit_effect.gd").show_hit(self)
	preload("res://scripts/combat_number.gd").show_number(self, previous_health - health)
	hit_flash = 0.12
	health_bar.call("set_health", health, max_health)
	if health == 0:
		if randf() < MAGNET_DROP_CHANCE and is_instance_valid(target):
			get_tree().current_scene.call("spawn_magnet", global_position + Vector3.UP * 0.45)
		if is_instance_valid(target):
			target.set("kills", target.get("kills") + 1)
		drop_loot()
		var arena := get_tree().current_scene
		if arena != null and arena.has_method("enemy_defeated") and not is_in_group("bosses"):
			arena.call("enemy_defeated")
		queue_free()

func apply_difficulty(total_percent: float, overtime_multiplier: float = 1.0) -> void:
	var ratio := float(health) / max_health
	var arena := get_tree().current_scene
	var scaling: Dictionary = arena.call("enemy_multipliers", total_percent) if arena != null and arena.has_method("enemy_multipliers") else preload("res://scripts/difficulty_scaling.gd").multipliers(0.0, total_percent)
	var base_speed: float = target.get("move_speed") if is_instance_valid(target) else 9.0
	move_speed = minf(base_speed, base_speed * 0.5 * scaling.speed)
	max_health = maxi(1, roundi(base_health * scaling.health))
	contact_damage = roundi(10.0 * scaling.damage)
	knockback_resistance = scaling.knockback
	health = ceili(max_health * ratio)
	health_bar.call("set_health", health, max_health)

func drop_loot(roll: float = -1.0, size_roll: float = -1.0, coin_roll: float = -1.0) -> void:
	if roll < 0.0:
		roll = randf()
	if size_roll < 0.0:
		size_roll = roll
	if coin_roll < 0.0:
		coin_roll = randf()
	var tier := int(target.call("xp_orb_tier", size_roll)) if is_instance_valid(target) else (2 if size_roll < 0.05 else (1 if size_roll < 0.15 else 0))
	spawn_pickup(false, Vector3(-0.25, 0.3, 0), tier == 1, tier)
	if coin_roll < 1.0 / 3.0:
		if is_instance_valid(target):
			target.call("collect_bonus")

func spawn_pickup(bonus: bool, offset: Vector3, large_xp: bool = false, xp_tier: int = 0) -> void:
	var pickup := Node3D.new()
	pickup.set_script(preload("res://scripts/pickup.gd"))
	pickup.set("bonus", bonus)
	pickup.set("large_xp", large_xp)
	pickup.set("xp_tier", xp_tier)
	pickup.set("target", target)
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + offset
