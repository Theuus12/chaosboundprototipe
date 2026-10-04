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
	await create_timer(0.5).timeout
	for i in range(24):
		arena.call("_physics_process", 1.0 / 60.0)
		if arena.get("pending_spawns") == 0:
			break
	var enemies := get_nodes_in_group("enemies")
	assert(enemies.size() == 12)
	for enemy in enemies:
		enemy.set_physics_process(false)
		var distance := Vector2(enemy.position.x, enemy.position.z).length()
		assert(distance >= 16.0 and distance <= 26.0)
	enemies[0].call("take_damage", 10000)
	enemies[0].call("take_damage", 10000)
	assert(arena.get("pending_spawns") == 1)
	await process_frame
	await process_frame
	arena.call("_physics_process", 1.0 / 60.0)
	assert(get_nodes_in_group("enemies").size() == 12)
	assert(arena.get("pending_spawns") == 0)
	arena.call("_physics_process", 10.0)
	assert(get_nodes_in_group("enemies").size() == 12)
	print("Enemy replacement: 12 initial, doubled distance, exactly one per kill, no timed waves PASS")
	quit()
