extends CharacterBody3D

@export var move_speed: float = 4.5
@export var max_health: int = 100
@export var contact_damage: int = 10
var health: int
var target: CharacterBody3D
var agent: NavigationAgent3D
var health_bar: Node3D
var visual: Node3D
var hit_flash: float = 0.0
var repath_left: float = 0.0
var knockback: Vector3 = Vector3.ZERO

func apply_knockback(origin: Vector3, force: float) -> void:
	var away := global_position - origin
	away.y = 0.0
	knockback += away.normalized() * force

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	collision_layer = 4
	collision_mask = 1 | 2
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.4
	shape.shape = capsule
	shape.position.y = 0.7
	add_child(shape)
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/goblin_visual.gd"))
	add_child(visual)
	agent = NavigationAgent3D.new()
	# O mapa fica ligeiramente acima do piso devido aos voxels do bake.
	# A tolerancia deve incluir essa altura para avancar os pontos do caminho.
	agent.path_desired_distance = 0.9
	agent.target_desired_distance = 0.9
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
	visual.call("animate", delta, Vector2(velocity.x, velocity.z).length(), velocity.y > 0.5, hit_flash > 0.0)
	if not is_on_floor():
		velocity.y -= 28.0 * delta
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		return
	repath_left -= delta
	if repath_left <= 0.0:
		agent.target_position = target.global_position
		repath_left = 0.5 + randf_range(0.0, 0.1)
	var direction := Vector3.ZERO
	# Atualiza o caminho antes de consultar se terminou: o alvo pode ter se movido.
	var next_point := agent.get_next_path_position()
	if not agent.is_navigation_finished():
		direction = next_point - global_position
		direction.y = 0.0
		direction = direction.normalized()
	velocity.x = direction.x * move_speed + knockback.x
	velocity.z = direction.z * move_speed + knockback.z
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 10.0, 1.0))
		# O caminho permite degraus baixos; o corpo precisa subir esses degraus.
		if is_on_floor() and test_move(global_transform, direction * 0.2):
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
	preload("res://scripts/combat_number.gd").show_number(self, previous_health - health)
	hit_flash = 0.12
	health_bar.call("set_health", health, max_health)
	if health == 0:
		if randf() < 0.01 and is_instance_valid(target):
			get_tree().current_scene.call("spawn_magnet", global_position + Vector3.UP * 0.45)
		if is_instance_valid(target):
			target.set("kills", target.get("kills") + 1)
		drop_loot()
		var arena := get_tree().current_scene
		if arena != null and arena.has_method("enemy_defeated") and not is_in_group("bosses"):
			arena.call("enemy_defeated")
		queue_free()

func apply_difficulty(total_percent: int, overtime_multiplier: float = 1.0) -> void:
	var ratio := float(health) / max_health
	var multiplier := 1.0 + total_percent / 100.0
	var base_speed: float = target.get("move_speed") if is_instance_valid(target) else 9.0
	move_speed = minf(base_speed, base_speed * 0.5 * multiplier * overtime_multiplier)
	max_health = roundi((100 + total_percent) * overtime_multiplier)
	contact_damage = roundi(10 * overtime_multiplier)
	health = ceili(max_health * ratio)
	health_bar.call("set_health", health, max_health)

func drop_loot(roll: float = -1.0, size_roll: float = -1.0, coin_roll: float = -1.0) -> void:
	if roll < 0.0:
		roll = randf()
	var drop_chance := float(target.call("xp_drop_chance")) if is_instance_valid(target) else 0.30
	if roll >= drop_chance:
		return
	if size_roll < 0.0:
		size_roll = randf()
	if coin_roll < 0.0:
		coin_roll = randf()
	var large_chance := float(target.call("large_xp_chance")) if is_instance_valid(target) else 0.0
	spawn_pickup(false, Vector3(-0.25, 0.3, 0), size_roll < large_chance)
	if coin_roll < 1.0 / 3.0:
		spawn_pickup(true, Vector3(0.25, 0.3, 0))

func spawn_pickup(bonus: bool, offset: Vector3, large_xp: bool = false) -> void:
	var pickup := Node3D.new()
	pickup.set_script(preload("res://scripts/pickup.gd"))
	pickup.set("bonus", bonus)
	pickup.set("large_xp", large_xp)
	pickup.set("target", target)
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + offset
