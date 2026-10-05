extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	for i in range(10):
		await physics_frame
	for i in range(42):
		var spawned := false
		for attempt in range(20):
			if arena.spawn_enemy():
				spawned = true
				break
			await physics_frame
		assert(spawned)
		var enemies = get_nodes_in_group("enemies")
		var enemy = enemies.back()
		assert(enemy.is_in_group("skeletons") == (i % 21 == 20))
		if enemy.is_in_group("skeletons"):
			assert(enemy.visual.meshes.size() == 9)
			assert(enemy.visual.model.find_child("LeftShoulder", true, false) == null)
			assert(enemy.visual.arms.size() == 2)
		enemy.free()
	assert(preload("res://scripts/enemy.gd").MAGNET_DROP_CHANCE == 0.005)
	print("Two skeletons per forty goblins, optimized model and 0.5% magnet drop PASS")
	quit()
