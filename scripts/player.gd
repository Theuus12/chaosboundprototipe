extends CharacterBody3D
signal level_reached(new_level: int)
signal difficulty_changed(total_percent: int)
## Ajuste estes valores aqui; numa cena propria ficam disponiveis no Inspector.
@export var move_speed: float = 9.0
@export var acceleration: float = 38.0
@export var air_acceleration: float = 12.0
@export var jump_speed: float = 11.0
@export var gravity: float = 28.0
@export var mouse_sensitivity: float = 0.003
@export var max_health: int = 100
@export var damage_grace: float = 0.75
@export var attack_interval: float = 2.0
@export var weapon_damage: int = 100
@export var slash_interval: float = 2.0
@export var slash_damage: int = 100
var slash_left: float = 2.0
var shot_left: float = 2.0
var level: int = 1
var xp: int = 0
var bonus_orbs: int = 0
var attack_speed_bonus: int = 0
var projectile_bonus_tenths: int = 0
var extra_xp_chance: int = 0
var difficulty_bonus: int = 0
var movement_speed_bonus: int = 0
var kills: int = 0
var luck_bonus: int = 0
var magnets_collected: int = 0
var weapons: Dictionary = {
	10: {"unlocked": true, "level": 1, "damage": 0.0, "speed": 0.0, "projectiles": 0.0},
	11: {"unlocked": false, "level": 0, "damage": 0.0, "speed": 0.0, "area": 0.0, "projectiles": 0.0},
	12: {"unlocked": false, "level": 0, "damage": 0.0, "speed": 0.0, "area": 0.0}
}

func apply_weapon_upgrade(weapon: int, stats: Dictionary, developer: bool = false) -> bool:
	if not weapons.has(weapon) or stats.size() < 1 or (stats.size() > 2 and not developer):
		return false
	for attribute in stats:
		if attribute not in preload("res://scripts/weapon_upgrades.gd").ATTRIBUTES[weapon] or stats[attribute] <= 0:
			return false
	if not weapons[weapon].unlocked:
		var slot := item_slots.find("")
		if slot < 0:
			return false
		item_slots[slot] = preload("res://scripts/weapon_upgrades.gd").NAMES[weapon]
	weapons[weapon].unlocked = true
	weapons[weapon].level += 1
	for attribute in stats:
		weapons[weapon][attribute] += stats[attribute]
	return true

func effective_weapon_damage(weapon: int) -> int:
	var base := 50 if weapon == 12 else (weapon_damage if weapon == 10 else slash_damage)
	return roundi(base * (1.0 + weapons[weapon].damage / 100.0))

func weapon_radius(weapon: int, base: float) -> float:
	return base * sqrt(1.0 + weapons[weapon].area / 100.0)

func effective_slash_interval() -> float:
	return maxf(0.05, slash_interval / (1.0 + (attack_speed_bonus + weapons[11].speed) / 100.0))

func effective_aura_interval() -> float:
	return maxf(0.05, 1.0 / (1.0 + (attack_speed_bonus + weapons[12].speed) / 100.0))

func slash_count() -> int:
	return 1 + int((projectile_bonus_tenths + roundi(weapons[11].projectiles * 10.0)) / 10.0)

var firing: bool = false
var cutting: bool = false
const BUFF_NAMES = ["Velocidade de ataque", "Quantidade de Projetil", "Aumento de XP", "Dificuldade", "Velocidade de movimento", "Sorte"]
var item_slots: Array[String] = ["Arco", "", "", ""]
var buff_slots: Array[int] = []
var buff_stacks: Dictionary = {}
var buff_rarities: Dictionary = {}

func eligible_buffs(catalog: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for kind in catalog:
		if buff_slots.size() < 4 or kind in buff_slots:
			result.append(kind)
	return result

func buff_value(kind: int) -> String:
	match kind:
		0: return "+%d%%" % attack_speed_bonus
		1: return "+%.1f (%d flechas)" % [projectile_bonus_tenths / 10.0, projectile_count()]
		2: return "+%d%%" % extra_xp_chance
		3: return "+%d%%" % difficulty_bonus
		4: return "+%d%%" % movement_speed_bonus
		5: return "+%d%%" % luck_bonus
	return ""

func collect_xp() -> void:
	xp += 20
	if xp >= 100:
		xp -= 100
		level += 1
		level_reached.emit(level)

func apply_upgrade(kind: int, amount: float, rarity: int = 0) -> bool:
	if kind < 0 or kind >= BUFF_NAMES.size():
		return false
	if kind not in buff_slots:
		if buff_slots.size() >= 4:
			return false
		buff_slots.append(kind)
	buff_stacks[kind] = int(buff_stacks.get(kind, 0)) + 1
	buff_rarities[kind] = maxi(int(buff_rarities.get(kind, 0)), clampi(rarity, 0, 4))
	var percent := clampi(roundi(amount), 1, 13)
	match kind:
		0:
			attack_speed_bonus += percent
			shot_left = minf(shot_left, effective_attack_interval())
		1:
			projectile_bonus_tenths += clampi(roundi(amount * 10.0), 3, 25)
		2:
			extra_xp_chance = mini(100, extra_xp_chance + percent)
		3:
			difficulty_bonus += percent
			difficulty_changed.emit(difficulty_bonus)
		4:
			movement_speed_bonus += percent
		5:
			luck_bonus += percent
	return true

func effective_move_speed() -> float:
	return move_speed * (1.0 + movement_speed_bonus / 100.0)

func effective_attack_interval() -> float:
	return maxf(0.05, attack_interval / (1.0 + (attack_speed_bonus + weapons[10].speed) / 100.0))

func projectile_count() -> int:
	return 1 + int((projectile_bonus_tenths + roundi(weapons[10].projectiles * 10.0)) / 10.0)

func collect_bonus() -> void:
	bonus_orbs += 1

func collect_magnet() -> void:
	magnets_collected += 1
	var magnet_slot := -1
	for i in range(item_slots.size()):
		if item_slots[i].begins_with("Ima"):
			magnet_slot = i
			break
	if magnet_slot < 0:
		magnet_slot = item_slots.find("")
	if magnet_slot >= 0:
		item_slots[magnet_slot] = "Ima x%d" % magnets_collected
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not pickup.get("bonus") and not pickup.is_queued_for_deletion():
			pickup.set("target", self)
			pickup.set("magnetized", true)

var health: int = 100
var dead: bool = false
var damage_grace_left: float = 0.0
var health_bar: Node3D

var pivot: Node3D
var visual: Node3D
var coyote_left: float = 0.0
var jump_buffer: float = 0.0

func _ready() -> void:
	health = max_health
	shot_left = attack_interval
	slash_left = slash_interval
	collision_layer = 2
	collision_mask = 1 | 4
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/archer_visual.gd"))
	visual.name = "ArcherVisual"
	add_child(visual)
	var aura := Node3D.new()
	aura.set_script(preload("res://scripts/aura.gd"))
	aura.set("player", self)
	aura.position.y = 0.1
	add_child(aura)
	health_bar = Node3D.new()
	health_bar.set_script(preload("res://scripts/health_bar_3d.gd"))
	health_bar.position.y = 2.2
	add_child(health_bar)
	health_bar.call("set_health", health, max_health)
	pivot = Node3D.new()
	pivot.position.y = 1.4
	pivot.rotation.x = -0.3
	add_child(pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 6.0
	arm.margin = 0.2
	pivot.add_child(arm)
	arm.add_excluded_object(get_rid())
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 80.0
	arm.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivot.rotation.y -= event.relative.x * mouse_sensitivity
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * mouse_sensitivity, -1.1, 0.35)

func _physics_process(delta: float) -> void:
	if dead:
		return
	slash_left -= delta
	if slash_left <= 0.0 and weapons[11].unlocked:
		perform_slash()
		slash_left = effective_slash_interval()
	shot_left -= delta
	if shot_left <= 0.0:
		shoot_arrow()
		shot_left += effective_attack_interval()
	damage_grace_left = maxf(0.0, damage_grace_left - delta)
	visual.visible = damage_grace_left <= 0.0 or int(damage_grace_left * 16.0) % 2 == 0
	coyote_left = 0.12 if is_on_floor() else maxf(0.0, coyote_left - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	if jump_buffer > 0.0 and coyote_left > 0.0:
		velocity.y = jump_speed
		jump_buffer = 0.0
		coyote_left = 0.0
	if not is_on_floor():
		velocity.y -= gravity * delta
	var input_axis := Input.get_vector("left", "right", "forward", "back")
	var direction := Basis(Vector3.UP, pivot.rotation.y) * Vector3(input_axis.x, 0.0, input_axis.y)
	var speed := effective_move_speed()
	var accel := acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.2:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-velocity.x, -velocity.z), minf(delta * 14.0, 1.0))
	visual.call("animate", delta, horizontal_speed, is_on_floor(), false)
	if global_position.y < -15.0 or Input.is_action_just_pressed("reset"):
		global_position = Vector3(0, 2, 0)
		velocity = Vector3.ZERO

func perform_slash() -> void:
	if not weapons[11].unlocked or cutting or dead:
		return
	cutting = true
	var count := slash_count()
	for i in range(count):
		if i > 0:
			await get_tree().create_timer(minf(0.15, effective_slash_interval() / count), false, true).timeout
		if dead:
			break
		spawn_slash()
	cutting = false

func spawn_slash() -> void:
	var slash := Node3D.new()
	slash.set_script(preload("res://scripts/slash.gd"))
	slash.set("damage", effective_weapon_damage(11))
	slash.set("reach", weapon_radius(11, 3.0))
	get_tree().current_scene.add_child(slash)
	slash.global_position = global_position + Vector3.UP * 0.8
	slash.rotation.y = visual.global_rotation.y
	slash.call("strike")

func shoot_arrow() -> void:
	if firing or dead:
		return
	firing = true
	var count := projectile_count()
	var used: Array[int] = []
	for i in range(count):
		if i > 0:
			await get_tree().create_timer(minf(0.15, effective_attack_interval() / count), false, true).timeout
		if dead:
			break
		fire_sequence_arrow(used)
	firing = false

func fire_sequence_arrow(used: Array[int]) -> void:
	var origin := global_position + Vector3.UP * 0.9
	var targets: Array[Node3D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.get("health") <= 0:
			continue
		targets.append(enemy)
	targets.sort_custom(func(a: Node3D, b: Node3D) -> bool: return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	var selected: Node3D = null
	for enemy in targets:
		if enemy.get_instance_id() not in used:
			selected = enemy
			break
	if selected == null and not targets.is_empty():
		selected = targets[0]
	var aim := -visual.global_basis.z
	if selected:
		used.append(selected.get_instance_id())
		aim = (selected.global_position + Vector3.UP * 0.7 - origin).normalized()
	spawn_arrow(origin, aim)

func spawn_arrow(origin: Vector3, aim: Vector3) -> void:
	var arrow := Node3D.new()
	arrow.set_script(preload("res://scripts/arrow.gd"))
	arrow.set("direction", aim)
	arrow.set("damage", effective_weapon_damage(10))
	# Na cena raiz, as flechas nao acompanham o movimento do jogador.
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = origin
	arrow.look_at(origin + aim, Vector3.UP if absf(aim.y) < 0.99 else Vector3.RIGHT)

func take_damage(amount: int) -> void:
	if dead or damage_grace_left > 0.0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	damage_grace_left = damage_grace
	health_bar.call("set_health", health, max_health)
	if health == 0:
		dead = true
		velocity = Vector3.ZERO
		visual.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
