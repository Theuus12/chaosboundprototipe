extends CharacterBody3D
const MAX_CRYSTAL_LEVEL: int = 100
const MAX_WEAPON_LEVEL: int = 50
signal level_reached(new_level: int)
signal inventory_changed
signal difficulty_changed(total_percent: float)
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
@export var base_collection_radius: float = 3.5
var slash_left: float = 2.0
var shot_left: float = 2.0
var level: int = 1
var xp: int = 0
var bonus_orbs: int = 0
var attack_speed_bonus: float = 0.0
var projectile_bonus_tenths: float = 0.0
var extra_xp_chance: float = 0.0
var difficulty_bonus: float = 0.0
var movement_speed_bonus: float = 0.0
var kills: int = 0
var luck_bonus: float = 0.0
var magnets_collected: int = 0
var weapons: Dictionary = {
	10: {"unlocked": true, "level": 1, "damage": 0.0, "speed": 0.0, "projectiles": 0.0, "projectile_speed": 0.0, "area": 0.0, "crit_chance": 0.0, "crit_damage": 0.0},
	11: {"unlocked": false, "level": 0, "damage": 0.0, "speed": 0.0, "area": 0.0, "projectiles": 0.0, "knockback": 0.0},
	12: {"unlocked": false, "level": 0, "damage": 0.0, "speed": 0.0, "area": 0.0},
	26: {"unlocked": false, "level": 0, "damage": 0.0, "speed": 0.0, "projectiles": 0.0, "projectile_speed": 0.0, "bounces": 0.0}
}

func apply_weapon_upgrade(weapon: int, stats: Dictionary, developer: bool = false) -> bool:
	if not can_upgrade_weapon(weapon):
		return false
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
		weapons[weapon][attribute] = float(weapons[weapon].get(attribute, 0.0)) + stats[attribute]
	inventory_changed.emit()
	return true

func can_upgrade_weapon(weapon: int) -> bool:
	return weapons.has(weapon) and int(weapons[weapon].level) < MAX_WEAPON_LEVEL and (weapons[weapon].unlocked or "" in item_slots)

func effective_weapon_damage(weapon: int) -> int:
	var base: float = preload("res://scripts/megabonk_balance.gd").WEAPON_BASE_DAMAGE[weapon]
	return roundi((base + weapons[weapon].damage) * (1.0 + total_bonus(15) / 100.0))

func weapon_radius(weapon: int, base: float) -> float:
	return base * sqrt(1.0 + (weapons[weapon].area * 3.0 + total_bonus(17)) / 100.0)

func effective_slash_interval() -> float:
	return maxf(0.05, slash_interval / (1.0 + (attack_speed_bonus + weapons[11].speed) / 100.0))

func effective_aura_interval() -> float:
	return maxf(0.05, 1.0 / (1.0 + (attack_speed_bonus + weapons[12].speed) / 100.0))

func slash_count() -> int:
	return 1 + int((projectile_bonus_tenths + roundi(weapons[11].projectiles * 10.0)) / 10.0)

var firing: bool = false
var dagger_left: float = 0.0

func nearest_enemy(origin: Vector3, excluded: Array[int] = []) -> Node3D:
	var nearest: Node3D = null
	var best := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.get("health") <= 0 or enemy.get_instance_id() in excluded:
			continue
		var distance := origin.distance_squared_to(enemy.global_position)
		if distance < best:
			best = distance
			nearest = enemy
	return nearest

func effective_dagger_interval() -> float:
	return maxf(0.1, 1.6 / (1.0 + (attack_speed_bonus + weapons[26].speed) / 100.0))

func shoot_dagger() -> void:
	for i in range(dagger_count()):
		fire_dagger()

func dagger_count() -> int:
	return 1 + int((projectile_bonus_tenths + roundi(weapons[26].projectiles * 10.0)) / 10.0)

func dagger_hits() -> int:
	return 2 + int(weapons[26].bounces)

func dagger_bounce_damage() -> int:
	return effective_weapon_damage(26)

func fire_dagger() -> void:
	var enemy := nearest_enemy(global_position)
	if enemy == null:
		return
	var dagger := Node3D.new()
	dagger.set_script(preload("res://scripts/reverse_dagger.gd"))
	dagger.set("player", self)
	dagger.set("target", enemy)
	dagger.set("hits_left", dagger_hits())
	dagger.set("damage", effective_weapon_damage(26))
	dagger.set("bounce_damage", dagger_bounce_damage())
	dagger.set("speed", 28.0 * (1.0 + (total_bonus(21) + weapons[26].projectile_speed) / 100.0))
	get_tree().current_scene.add_child(dagger)
	dagger.global_position = global_position + Vector3.UP * 0.8
var cutting: bool = false
const Tomes = preload("res://scripts/tomes.gd")
const BUFF_NAMES = Tomes.NAMES
var tome_bonuses: Dictionary = {}
var character_buffs: Dictionary = {}
var character_buff_stacks: Dictionary = {}
var character_buff_rarities: Dictionary = {}
var jumps_used := 0
var shield_bar: Node3D
var chaos_results: Dictionary = {}
var base_max_health: int = 100
var shield: float = 0.0
var shield_delay: float = 0.0
var regen_credit: float = 0.0
var heal_credit: float = 0.0
var coins: float = 0.0

func tome_bonus(kind: int) -> float:
	return float(tome_bonuses.get(kind, 0.0))

func total_bonus(kind: int) -> float:
	var direct := float(character_buffs.get(kind, 0.0))
	return ((1.0 + tome_bonus(kind) / 100.0) * (1.0 + direct / 100.0) - 1.0) * 100.0 if kind == 15 else tome_bonus(kind) + direct

func apply_character_buff(kind: int, amount: float, rarity: int = 0) -> bool:
	if dead or kind not in preload("res://scripts/shrine_rewards.gd").CATALOG or amount <= 0:
		return false
	var previous := float(character_buffs.get(kind, 0.0))
	character_buffs[kind] = ((1.0 + previous / 100.0) * (1.0 + amount / 100.0) - 1.0) * 100.0 if kind == 15 else previous + amount
	character_buff_stacks[kind] = int(character_buff_stacks.get(kind, 0)) + 1
	character_buff_rarities[kind] = maxi(int(character_buff_rarities.get(kind, 0)), rarity)
	match kind:
		1: projectile_bonus_tenths += amount * 10.0
		3:
			difficulty_bonus += amount
			difficulty_changed.emit(difficulty_bonus)
		4: movement_speed_bonus += amount
		5: luck_bonus += amount
		8:
			shield = max_shield()
			refresh_shield_bar()
	inventory_changed.emit()
	return true

func refresh_shield_bar() -> void:
	if is_instance_valid(shield_bar):
		shield_bar.visible = max_shield() > 0.0
		shield_bar.call("set_health", shield, max_shield())

func max_jumps() -> int:
	return 1 + int(character_buffs.get(31, 0))

func try_jump() -> bool:
	if dead:
		return false
	if is_on_floor() or coyote_left > 0:
		jumps_used = 1
	elif maxi(1, jumps_used) < max_jumps():
		jumps_used = maxi(1, jumps_used) + 1
	else:
		return false
	velocity.y = effective_jump_speed()
	jump_buffer = 0.0
	coyote_left = 0.0
	return true

func max_shield() -> float:
	return total_bonus(8)

func collection_radius() -> float:
	return base_collection_radius * (1.0 + total_bonus(24) / 100.0)

func effect_duration(base: float) -> float:
	return base * (1.0 + total_bonus(18) / 100.0)

func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	heal_credit += amount
	var whole := floori(heal_credit)
	heal_credit -= whole
	var previous_health := health
	health = mini(max_health, health + whole)
	preload("res://scripts/combat_number.gd").show_number(self, health - previous_health, true)
	if health == max_health:
		heal_credit = 0.0
	if is_instance_valid(health_bar):
		health_bar.call("set_health", health, max_health)

func update_survival(delta: float) -> void:
	regen_credit += delta * total_bonus(7) / 60.0
	if regen_credit >= 1.0:
		var whole := floori(regen_credit)
		regen_credit -= whole
		heal(whole)
	shield_delay = maxf(0.0, shield_delay - delta)
	if shield_delay <= 0.0:
		shield = minf(max_shield(), shield + delta * max_shield() / 2.0)
	refresh_shield_bar()

func apply_tome_effect(kind: int, percent: float) -> void:
	if kind == 25:
		tome_bonuses[25] = tome_bonus(25) + percent
		var options: Array[int] = [6, 7, 8, 9, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
		var chosen: int = options.pick_random()
		chaos_results[chosen] = float(chaos_results.get(chosen, 0.0)) + percent
		apply_tome_effect(chosen, percent)
		return
	tome_bonuses[kind] = ((1.0 + tome_bonus(kind) / 100.0) * (1.0 + percent / 100.0) - 1.0) * 100.0 if kind == 15 else tome_bonus(kind) + percent
	if kind == 6:
		var previous := max_health
		max_health = roundi(base_max_health + total_bonus(6))
		heal(max_health - previous)
	if kind == 8:
		shield = max_shield()
		refresh_shield_bar()

func hit_enemy(enemy: Node3D, damage: int, critical_roll: float = -1.0, weapon: int = 10) -> void:
	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get("health") <= 0:
		return
	var roll := randf() if critical_roll < 0.0 else critical_roll
	var multiplier := preload("res://scripts/combat_stats.gd").critical_multiplier(total_bonus(16) + float(weapons[weapon].get("crit_chance", 0.0)), roll)
	if multiplier > 1.0:
		multiplier *= 1.0 + (float(weapons[weapon].get("crit_damage", 0.0)) + total_bonus(27)) / 100.0
	if enemy.is_in_group("elites") or enemy.is_in_group("bosses"):
		multiplier *= 1.0 + total_bonus(29) / 100.0
	var dealt := mini(int(enemy.get("health")), roundi(damage * multiplier))
	enemy.call("take_damage", dealt)
	heal(dealt * total_bonus(20) / 100.0)
	var push: float = total_bonus(19) + float(weapons[weapon].get("knockback", 0.0))
	if push > 0.0 and enemy.has_method("apply_knockback"):
		enemy.call("apply_knockback", global_position, 4.0 * (1.0 + push / 100.0))
var item_slots: Array[String] = ["Arco", ""]
var buff_slots: Array[int] = []
var buff_stacks: Dictionary = {}
var buff_rarities: Dictionary = {}

func eligible_buffs(catalog: Array[int]) -> Array[int]:
	var result: Array[int] = []
	for kind in catalog:
		if int(buff_stacks.get(kind, 0)) < MAX_CRYSTAL_LEVEL and (buff_slots.size() < 4 or kind in buff_slots):
			result.append(kind)
	return result

func buff_value(kind: int) -> String:
	match kind:
		0: return "+%.2f%%" % attack_speed_bonus
		1: return "+%.2f (%d flechas)" % [projectile_bonus_tenths / 10.0 - float(character_buffs.get(1, 0)), projectile_count()]
		2: return "+%.2f%%" % extra_xp_chance
		3: return "+%.2f%%" % (difficulty_bonus - float(character_buffs.get(3, 0)))
		4: return "+%.2f%%" % (movement_speed_bonus - float(character_buffs.get(4, 0)))
		5: return "+%.2f%%" % (luck_bonus - float(character_buffs.get(5, 0)))
	return preload("res://scripts/megabonk_balance.gd").describe_crystal(kind, tome_bonus(kind))

func xp_drop_chance() -> float:
	return 1.0

func xp_orb_tier(roll: float) -> int:
	var bonus := clampf((extra_xp_chance + luck_bonus) / 100.0, 0.0, 1.0)
	var big_chance := 0.05 + bonus * 0.20
	var medium_chance := 0.10 + bonus * 0.65
	if roll < big_chance - 0.0000001:
		return 2
	return 1 if roll < big_chance + medium_chance - 0.0000001 else 0

func large_xp_chance() -> float:
	return clampf(extra_xp_chance / 100.0, 0.0, 1.0)

func xp_required() -> int:
	return (int((maxi(1, level) - 1) / 10) + 1) * 100

func collect_xp(amount: int = 10, power_up: bool = false) -> void:
	xp += maxi(0, roundi(amount * (1.0 + total_bonus(28) / 100.0)) if power_up else amount)
	while xp >= xp_required():
		xp -= xp_required()
		level += 1
		level_reached.emit(level)

func apply_upgrade(kind: int, amount: float, rarity: int = 0) -> bool:
	if not BUFF_NAMES.has(kind) or int(buff_stacks.get(kind, 0)) >= MAX_CRYSTAL_LEVEL:
		return false
	if kind not in buff_slots:
		if buff_slots.size() >= 4:
			return false
		buff_slots.append(kind)
	buff_stacks[kind] = int(buff_stacks.get(kind, 0)) + 1
	buff_rarities[kind] = maxi(int(buff_rarities.get(kind, 0)), clampi(rarity, 0, 4))
	var percent := maxf(0.0, amount)
	match kind:
		0:
			attack_speed_bonus += percent
			shot_left = minf(shot_left, effective_attack_interval())
		1:
			projectile_bonus_tenths += amount * 10.0
		2:
			extra_xp_chance = minf(100.0, extra_xp_chance + percent)
		3:
			difficulty_bonus += percent
			difficulty_changed.emit(difficulty_bonus)
		4:
			movement_speed_bonus += percent
		5:
			luck_bonus += percent
		_:
			apply_tome_effect(kind, percent)
	inventory_changed.emit()
	return true

func effective_move_speed() -> float:
	return move_speed * (1.0 + movement_speed_bonus / 100.0)

func effective_jump_speed() -> float:
	return jump_speed * sqrt(1.0 + total_bonus(30) / 100.0)

func effective_attack_interval() -> float:
	return maxf(0.05, attack_interval / (1.0 + (attack_speed_bonus + weapons[10].speed) / 100.0))

func projectile_count() -> int:
	return 1 + int((projectile_bonus_tenths + roundi(weapons[10].projectiles * 10.0)) / 10.0)

func collect_bonus() -> void:
	bonus_orbs += 1
	coins += 1.0 + (total_bonus(22) + total_bonus(23)) / 100.0

func collect_magnet() -> void:
	magnets_collected += 1
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
	base_max_health = max_health
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
	visual.set_script(preload("res://scripts/imported_archer_visual.gd"))
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
	shield_bar = Node3D.new()
	shield_bar.set_script(preload("res://scripts/health_bar_3d.gd"))
	shield_bar.set("fill_color", Color("429fff"))
	shield_bar.set("low_fill_color", Color("429fff"))
	shield_bar.position.y = 2.4
	add_child(shield_bar)
	refresh_shield_bar()
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
	camera.fov = 70.0
	camera.far = 85.0
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
	update_survival(delta)
	dagger_left -= delta
	if weapons[26].unlocked and dagger_left <= 0.0:
		shoot_dagger()
		dagger_left = effective_dagger_interval()
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
	if is_on_floor():
		jumps_used = 0
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	if jump_buffer > 0.0:
		try_jump()
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
	visual.call("animate", delta, horizontal_speed, is_on_floor(), false, velocity.y)
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
	slash.set("player", self)
	slash.set("lifetime", effect_duration(0.22))
	get_tree().current_scene.add_child(slash)
	slash.global_position = global_position + Vector3.UP * 0.8
	slash.rotation.y = visual.global_rotation.y
	var enemy := nearest_enemy(global_position)
	if enemy != null:
		var direction := enemy.global_position - global_position
		if Vector2(direction.x, direction.z).length_squared() > 0.0001:
			slash.rotation.y = atan2(-direction.x, -direction.z)
	slash.call("strike")

func shoot_arrow() -> void:
	if firing or dead:
		return
	firing = true
	var count := projectile_count()
	var target := nearest_enemy(global_position)
	for i in range(count):
		var angle := i * TAU / count
		var offset := Vector3(cos(angle), 0, sin(angle)) * (0.7 if count > 1 else 0.0)
		var origin := global_position + Vector3.UP * 0.9 + offset
		var aim := -visual.global_basis.z
		if target != null:
			aim = (target.global_position + Vector3.UP * 0.7 - origin).normalized()
		spawn_arrow(origin, aim)
	firing = false

func spawn_arrow(origin: Vector3, aim: Vector3) -> void:
	var arrow := Node3D.new()
	arrow.set_script(preload("res://scripts/arrow.gd"))
	arrow.set("direction", aim)
	arrow.set("damage", effective_weapon_damage(10))
	arrow.set("player", self)
	arrow.set("speed", 32.0 * (1.0 + (total_bonus(21) + float(weapons[10].get("projectile_speed", 0.0))) / 100.0))
	arrow.set("lifetime", effect_duration(3.0))
	arrow.set("hit_radius", 0.04 * sqrt(1.0 + total_bonus(17) / 100.0))
	arrow.scale = Vector3.ONE * sqrt(1.0 + (total_bonus(17) + float(weapons[10].get("area", 0.0))) / 100.0)
	# Na cena raiz, as flechas nao acompanham o movimento do jogador.
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = origin
	arrow.look_at(origin + aim, Vector3.UP if absf(aim.y) < 0.99 else Vector3.RIGHT)

func take_damage(amount: int, attacker: Node3D = null, evasion_roll: float = -1.0) -> void:
	if dead or damage_grace_left > 0.0 or amount <= 0:
		return
	var roll := randf() if evasion_roll < 0.0 else evasion_roll
	if roll < minf(75.0, total_bonus(9)) / 100.0:
		damage_grace_left = damage_grace
		return
	var reduced := maxi(1, roundi(amount * 100.0 / (100.0 + total_bonus(13))))
	var absorbed := minf(shield, reduced)
	shield -= absorbed
	refresh_shield_bar()
	shield_delay = 5.0
	var received := ceili(reduced - absorbed)
	var previous_health := health
	health = maxi(0, health - received)
	preload("res://scripts/combat_number.gd").show_number(self, previous_health - health)
	if received > 0 and is_instance_valid(attacker):
		attacker.call("take_damage", roundi(total_bonus(14)))
	damage_grace_left = damage_grace
	health_bar.call("set_health", health, max_health)
	if health == 0:
		dead = true
		velocity = Vector3.ZERO
		visual.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

