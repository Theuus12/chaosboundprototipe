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
	assert(arena.get("pending_spawns") == 0)
	assert(arena.call("effective_wave_size") == 6)
	player.set("difficulty_bonus", 100.0)
	assert(arena.call("population_limit") == 50)
	assert(arena.call("effective_spawn_interval") == 2.0)
	player.set("difficulty_bonus", 0.0)
	arena.set("pending_spawns", 0)
	var orcs: Array[int] = [0, 1, 2]
	var hordes: Array[int] = [0, 1, 2, 3]
	arena.set("orcs_spawned", orcs)
	arena.set("hordes_announced", hordes)
	arena.set("elapsed_time", 120.0)
	arena.set("horde_until", 10000.0)
	assert(arena.call("effective_wave_size") == 6)
	await create_timer(0.6).timeout
	player.set("damage_grace_left", 100000.0)
	for i in range(300):
		arena.call("_physics_process", 0.6)
		if get_nodes_in_group("enemies").size() > 100:
			print("Over cap: ", get_nodes_in_group("enemies").size(), " regular: ", arena.call("regular_enemy_count"), " bosses: ", get_nodes_in_group("bosses").size(), " limit: ", arena.call("population_limit"))
			quit(1)
			return
		assert(arena.get("pending_spawns") <= 100)
		await physics_frame
	print("Horde population reached: ", get_nodes_in_group("enemies").size(), " pending: ", arena.get("pending_spawns"))
	assert(get_nodes_in_group("enemies").size() == 100)
	assert(player.get("kills") == 0)
	assert(arena.get("pending_spawns") == 0)
	arena.call("spawn_boss", 1)
	assert(get_nodes_in_group("enemies").size() == 100)
	assert(get_nodes_in_group("bosses").size() == 1)
	arena.set("horde_until", 0.0)
	arena.call("_physics_process", 0.01)
	assert(arena.get("pending_spawns") == 0)
	assert(get_nodes_in_group("enemies").size() == 50)
	print("Spawn caps: PASS (6 per batch, 50 normal, 100 horde, bosses preserved)")
	quit()
