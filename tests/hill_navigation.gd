extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Engine.time_scale = 3.0
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	arena.player.shot_left = 100000
	arena.player.damage_grace_left = 100000
	for i in range(20):
		await physics_frame
	var forest = preload("res://scripts/forest.gd")
	var targets: Array[CharacterBody3D] = []
	var enemies: Array[CharacterBody3D] = []
	for i in range(forest.HILLS.size()):
		var center: Vector2 = forest.HILLS[i]
		var target := CharacterBody3D.new()
		target.set_script(load("res://scripts/player.gd"))
		arena.add_child(target)
		target.set_physics_process(false)
		target.global_position = Vector3(center.x, forest.HILL_HEIGHT, center.y)
		target.damage_grace_left = 100000
		target.shot_left = 100000
		targets.append(target)
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.set("target", target)
		if i % 2 == 1:
			enemy.set("model_path", "res://assets/characters/skeleton/skeleton.glb")
		arena.add_child(enemy)
		var start := Vector3(center.x, 0, center.y + forest.HILL_RADIUS + 2)
		enemy.global_position = NavigationServer3D.map_get_closest_point(arena.navigation.get_navigation_map(), start)
		enemies.append(enemy)
	for i in range(900):
		await physics_frame
	for i in range(enemies.size()):
		var enemy = enemies[i]
		print("Hill ", i, " enemy: ", enemy.global_position, " target: ", targets[i].global_position)
		assert(enemy.global_position.y > 4.5, "Enemy did not climb hill")
		assert(enemy.global_position.distance_to(targets[i].global_position) < 2.0, "Enemy did not reach summit")
	print("Four enlarged hills: goblins and skeletons climb to summits PASS")
	arena.queue_free()
	await process_frame
	await process_frame
	quit()
