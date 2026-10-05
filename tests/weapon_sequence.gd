extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	arena.set_physics_process(false)
	var player := arena.get("player") as CharacterBody3D
	player.set("shot_left", 10000.0)
	player.set("slash_left", 10000.0)
	player.call("apply_weapon_upgrade", 10, {"projectiles": 2.0})
	player.call("shoot_arrow")
	assert(get_nodes_in_group("arrows").size() == 3)
	for i in range(6):
		await physics_frame
	assert(get_nodes_in_group("arrows").size() == 3)
	for i in range(20):
		await physics_frame
	assert(get_nodes_in_group("arrows").size() == 3)
	var first := preload("res://scripts/weapon_upgrades.gd").roll_stats(11, 0, 1)
	assert(first.size() == 1)
	player.call("apply_weapon_upgrade", 11, first)
	assert(player.get("weapons")[11].has("projectiles") and player.get("weapons")[11].has("area"))
	var stats := arena.get_node("StatsMenu")
	stats.call("toggle")
	assert(stats.get("item_labels")[1].get_parent().tooltip_text.contains("Quantidade de projetil"))
	print("Simultaneous arrow volley: PASS")
	quit(0)
