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
	var minimap: Control = arena.get_node("GameHUD").get_child(0).get_node("Minimap")
	var forest := preload("res://scripts/forest.gd")
	assert(forest.MAP_SIZE == 360)
	var ground: StaticBody3D = arena.get("navigation").get_node("GrassGround")
	assert(is_equal_approx(ground.get_child(1).mesh.get_aabb().size.x, 360))
	assert(is_equal_approx(ground.get_child(1).mesh.get_aabb().size.z, 360))
	assert(minimap.call("map_offset", player.global_position).is_zero_approx())
	var statues := get_nodes_in_group("buff_statues")
	assert(statues.size() == 15)
	var outer := 0
	for statue in statues:
		if Vector2(statue.position.x, statue.position.z).length() > 60:
			outer += 1
	assert(outer == 10)
	assert(minimap.call("nearby_statues").size() == 5)
	player.global_position = statues[1].global_position
	assert(statues[1] in minimap.call("nearby_statues"))
	assert(minimap.call("map_offset", statues[1].global_position).is_zero_approx())
	var camera := player.get_viewport().get_camera_3d()
	assert(camera.fov == 70 and camera.far == 85)
	var environment: Environment
	for child in arena.get_children():
		if child is WorldEnvironment:
			environment = child.environment
	assert(environment.fog_enabled and environment.fog_depth_end == 65)
	for i in range(10):
		await physics_frame
	await create_timer(0.5).timeout
	var map: RID = arena.get("navigation").get_navigation_map()
	var distant := Vector3(140, 0, 130)
	var closest := NavigationServer3D.map_get_closest_point(map, distant)
	print("Outer navigation: ", closest, " iteration: ", NavigationServer3D.map_get_iteration_id(map))
	if closest.distance_to(distant) >= 3:
		push_error("Expanded terrain is missing navigation near outer point")
		quit(1)
		return
	player.global_position = distant
	seed(71219)
	var spawned := false
	for attempt in range(5):
		if arena.call("spawn_enemy"):
			spawned = true
			break
	assert(spawned, "Inimigos devem surgir perto do jogador na área ampliada.")
	arena.call("spawn_boss", 1)
	assert(arena.get("boss").global_position.x > 60)
	print("Map/minimap: PASS (360x360, fog/FOV, player center, nearby statues, outer navigation)")
	quit()
