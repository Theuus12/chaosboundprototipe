extends SceneTree
const Weapons = preload("res://scripts/weapon_upgrades.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for weapon in [10, 11, 12]:
		for i in range(50):
			var stats := Weapons.roll_stats(weapon, 4)
			assert(stats.size() == 2)
			for attribute in stats:
				assert(attribute in Weapons.ATTRIBUTES[weapon])
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var player := arena.get("player") as CharacterBody3D
	assert(player.get("weapons")[10].unlocked and not player.get("weapons")[11].unlocked and not player.get("weapons")[12].unlocked)
	assert(get_nodes_in_group("magnets").is_empty())
	player.call("apply_weapon_upgrade", 10, {"projectiles": 1.0, "damage": 10.0})
	assert(player.call("projectile_count") == 2 and player.call("effective_weapon_damage", 10) == 110)
	assert(player.get("attack_speed_bonus") == 0 and player.get("buff_slots").is_empty())
	player.call("apply_weapon_upgrade", 11, {"speed": 10.0, "area": 10.0})
	assert(player.get("weapons")[11].unlocked and player.call("effective_slash_interval") < 2.0)
	player.call("apply_weapon_upgrade", 12, {"area": 10.0, "damage": 10.0})
	assert(player.call("effective_weapon_damage", 12) == 55)
	assert(player.get("item_slots") == ["Arco", "Corte frontal", "Aura", ""])
	player.call("apply_weapon_upgrade", 12, {"speed": 10.0, "damage": 10.0})
	assert(player.call("effective_aura_interval") < 1.0)
	assert(player.get("item_slots") == ["Arco", "Corte frontal", "Aura", ""])
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.position = player.global_position + Vector3(1, 0, 0)
	arena.add_child(enemy)
	for child in player.get_children():
		if child.get_script() == load("res://scripts/aura.gd"):
			child.call("pulse")
	assert(enemy.get("health") == 40)
	for child in player.get_children():
		if child.get_script() == load("res://scripts/aura.gd"):
			child.call("pulse")
	assert(enemy.get("health") == 40, "Aura deve respeitar intervalo por inimigo")
	var menu := arena.get_node("StatsMenu")
	menu.call("toggle")
	assert(menu.get("item_labels")[0].text.contains("Arco"))
	await process_frame
	await process_frame
	var slot_rect: Rect2 = menu.get("item_labels")[3].get_global_rect()
	assert(slot_rect.position.x >= 0 and slot_rect.end.x <= root.get_visible_rect().size.x, "Itens devem caber na janela")
	var old_level: int = player.get("weapons")[10].level
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.ctrl_pressed = true
	menu.call("item_click", click, 0)
	assert(player.get("weapons")[10].level == old_level + 1)
	assert(paused and menu.get("overlay").visible)
	menu.call("toggle")
	print("Weapons: PASS")
	quit(0)
