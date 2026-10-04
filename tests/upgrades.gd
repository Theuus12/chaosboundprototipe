extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	var menu := arena.get_node("UpgradeMenu")
	for i in range(5):
		player.call("collect_xp")
	assert(paused and menu.get("choosing"), "Nivel deve pausar e abrir escolha")
	for i in range(3):
		var roll: float = menu.get("rolls")[i]
		var kind: int = menu.get("offered")[i]
		if preload("res://scripts/tomes.gd").is_weapon(kind):
			assert(menu.get("weapon_rolls")[i].size() in [1, 2])
			continue
		assert(roll >= (0.3 if kind == 1 else 1.0) and roll <= (2.5 if kind == 1 else 13.0))
	var expected: int = 5
	menu.get("offered").assign([0, 1, 2])
	menu.get("rolls")[0] = float(expected)
	menu.get("buttons")[0].emit_signal("pressed")
	assert(not paused and player.get("attack_speed_bonus") == expected)
	assert(player.call("effective_attack_interval") < 2.0)
	# Dois niveis recebidos no mesmo frame devem preservar ambas as escolhas.
	for i in range(10):
		player.call("collect_xp")
	assert(menu.get("pending_levels").size() == 2)
	menu.get("offered").assign([0, 1, 2])
	menu.get("rolls")[1] = 0.5
	menu.call("choose", 1)
	assert(paused and menu.get("pending_levels").size() == 1)
	menu.get("offered").assign([0, 1, 2])
	menu.get("rolls")[2] = 5.0
	menu.call("choose", 2)
	assert(not paused and player.get("extra_xp_chance") > 0)
	player.set("projectile_bonus_tenths", 0)
	player.call("apply_upgrade", 1, 0.5)
	player.call("apply_upgrade", 1, 0.5)
	assert(player.call("projectile_count") == 2)
	player.set("projectile_bonus_tenths", 0)
	player.call("apply_upgrade", 1, 1.8)
	player.call("apply_upgrade", 1, 0.3)
	assert(player.call("projectile_count") == 3 and player.get("projectile_bonus_tenths") == 21)
	var stats := arena.get_node("StatsMenu")
	stats.call("toggle")
	assert(paused and stats.get("overlay").visible)
	stats.call("toggle")
	assert(not paused)
	player.set("shot_left", 10000.0)
	for pos in [Vector3(-5, 0, -5), Vector3(5, 0, -5), Vector3(0, 0, 8)]:
		var aim_target := CharacterBody3D.new()
		aim_target.set_script(load("res://scripts/enemy.gd"))
		aim_target.position = pos
		arena.add_child(aim_target)
		aim_target.set_physics_process(false)
	player.call("shoot_arrow")
	var arrows := get_nodes_in_group("arrows")
	assert(arrows.size() == 1)
	player.set("extra_xp_chance", 100)
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	arena.add_child(enemy)
	# Mesmo sem drop base, melhoria com 100% garante uma azul adicional.
	enemy.call("drop_loot", 0.95)
	assert(get_nodes_in_group("pickups").size() == 1)
	assert(not get_nodes_in_group("pickups")[0].get("bonus"))
	player.call("apply_upgrade", 3, 1.0)
	for i in range(40):
		menu.call("queue_level", 10 + i)
		var offered: Array = menu.get("offered")
		assert(offered.size() == 3 and offered[0] != offered[1] and offered[1] != offered[2] and offered[0] != offered[2])
		menu.call("choose", 0)
	player.set("difficulty_bonus", 0)
	player.call("apply_upgrade", 3, 10.0)
	player.call("apply_upgrade", 3, 5.0)
	assert(player.get("difficulty_bonus") == 15)
	assert(is_equal_approx(enemy.get("move_speed"), 5.175))
	assert(enemy.get("max_health") == 115)
	assert(arena.call("effective_enemy_limit") == 29)
	assert(arena.call("effective_spawn_interval") < 1.8)
	assert(player.get("item_slots").size() == 4)
	assert(player.get("buff_slots").size() == 4)
	var fixed_slots: Array = player.get("buff_slots").duplicate()
	player.call("apply_upgrade", 0, 5.0)
	assert(player.get("buff_slots") == fixed_slots, "Repetir buff nao muda slots")
	var future_catalog: Array[int] = [0, 1, 2, 3, 4]
	var eligible: Array = player.call("eligible_buffs", future_catalog)
	assert(eligible.size() == 4 and 4 not in eligible, "Slots cheios bloqueiam buffs novos")
	assert(not player.call("apply_upgrade", 4, 5.0))
	stats.call("toggle")
	assert(stats.get("buff_labels").size() == 4 and stats.get("item_labels").size() == 4)
	assert(not stats.get("buff_labels")[0].text.contains("Vazio"))
	stats.call("toggle")
	print("Upgrades: PASS")
	quit(0)
