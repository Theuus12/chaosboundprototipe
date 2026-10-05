extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var navigation: NavigationRegion3D = arena.get("navigation")
	var ground := navigation.get_node("GrassGround")
	assert(ground.get_child(0).shape is ConcavePolygonShape3D)
	assert(preload("res://scripts/forest.gd").ground_height(-24, -20) > 1.0)
	assert(get_nodes_in_group("buildings").size() == 6)
	assert(ground.get_child(1).material_override.albedo_texture != null)
	var types := {}
	for tree in get_nodes_in_group("trees"):
		types[tree.get_meta("tree_type")] = true
		assert(tree.get_child(1) is CollisionShape3D)
	assert(types.size() == 3)
	assert(get_nodes_in_group("trees").size() > 30)
	assert(get_nodes_in_group("bushes").size() > 30)
	assert(get_nodes_in_group("climb_routes").is_empty())
	for i in range(6):
		await physics_frame
	await create_timer(0.5).timeout
	var point := NavigationServer3D.map_get_closest_point(navigation.get_navigation_map(), Vector3(50, 0, 50))
	assert(point.distance_to(Vector3(50, 0, 50)) < 2.0)
	arena.call("spawn_enemy")
	assert(not get_nodes_in_group("enemies").is_empty())
	print("Forest: expanded terrain, grass, three tree types, bushes and enemy navigation PASS")
	quit()
