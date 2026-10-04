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
	player.set("shot_left", 10000.0)
	assert(get_nodes_in_group("climb_routes").size() == 14)
	for ramp in get_nodes_in_group("climb_routes"):
		var mesh: ArrayMesh = ramp.get_child(1).mesh
		var normals: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
		assert(normals[0].y > 0.0, "Topo da rampa deve ser visivel por cima")
		var shape: ConvexPolygonShape3D = ramp.get_child(0).shape
		var height := shape.points[2].y
		var run := shape.points[4].z
		player.position = ramp.to_global(Vector3(0, height, -1.1))
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.set("target", player)
		enemy.position = ramp.to_global(Vector3(0, 0.1, run + 1.0))
		arena.add_child(enemy)
		assert(enemy.get("visual").get_child_count() > 8)
		var reached := false
		for i in range(720):
			await physics_frame
			if enemy.position.y > height - 0.3 and enemy.position.distance_to(player.position) < 2.0:
				reached = true
				break
		if not reached:
			push_error("Enemy failed to climb: %s target %s" % [enemy.position, player.position])
			quit(1)
			return
		enemy.queue_free()
		player.set("health", 100)
		player.set("dead", false)
	print("All 14 structures climb: PASS")
	quit(0)
