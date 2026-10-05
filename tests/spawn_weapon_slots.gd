extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	var player: CharacterBody3D = arena.get("player")
	player.set_physics_process(false)
	await create_timer(0.6).timeout
	assert(get_nodes_in_group("enemies").is_empty())
	arena.call("_physics_process", 1.99)
	assert(get_nodes_in_group("enemies").is_empty())
	arena.call("_physics_process", 0.02)
	assert(get_nodes_in_group("enemies").size() == 3)
	arena.call("_physics_process", 0.0)
	assert(get_nodes_in_group("enemies").size() == 6)
	arena.call("_physics_process", 1.9)
	assert(get_nodes_in_group("enemies").size() == 6)
	arena.call("_physics_process", 0.11)
	arena.call("_physics_process", 0.0)
	assert(get_nodes_in_group("enemies").size() == 12)
	assert(player.get("item_slots").size() == 2)
	assert(player.get("item_slots")[0] == "Arco")
	assert(player.call("apply_weapon_upgrade", 11, {"damage": 1.0}))
	assert(not player.call("can_upgrade_weapon", 12))
	assert(not player.call("apply_weapon_upgrade", 12, {"damage": 1.0}))
	assert(player.call("apply_weapon_upgrade", 10, {"damage": 1.0}))
	var hud := arena.get_node("GameHUD")
	var stats := arena.get_node("StatsMenu")
	stats.call("refresh_inventory")
	assert(hud.get("weapon_slots").size() == 2 and hud.get("crystal_slots").size() == 4)
	assert(stats.get("item_labels").size() == 2 and stats.get("crystal_slots").size() == 4)
	print("Spawn timing and two weapon slots: PASS")
	quit()
