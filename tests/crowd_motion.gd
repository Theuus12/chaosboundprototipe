extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var player: CharacterBody3D = arena.get("player")
	player.set("shot_left", 10000.0)
	player.set("damage_grace_left", 10000.0)
	await create_timer(1.0).timeout
	var starts := {}
	for enemy in get_nodes_in_group("enemies"):
		starts[enemy.get_instance_id()] = enemy.global_position
	await create_timer(3.0).timeout
	var moving := 0
	var stopped := 0
	for enemy in get_nodes_in_group("enemies"):
		if not starts.has(enemy.get_instance_id()):
			continue
		if enemy.global_position.distance_to(starts[enemy.get_instance_id()]) > 2:
			moving += 1
		else:
			stopped += 1
			if stopped <= 3:
				print("Stopped: ", enemy.global_position, " direct=", enemy.get("direct_chase"), " velocity=", enemy.velocity, " safe=", enemy.get("crowd_velocity"), " ready=", enemy.get("crowd_velocity_ready"), " speed=", enemy.get("move_speed"))
	print("Crowd motion: moving=", moving, " stopped=", stopped)
	var enemy: Node3D = get_nodes_in_group("enemies")[0]
	var bar: Node3D = enemy.get("health_bar")
	var material: ShaderMaterial = bar.get("bar_material")
	bar.call("set_health", 9, 9)
	assert(material.get_shader_parameter("health_ratio") == 1.0)
	bar.call("set_health", 3, 9)
	assert(is_equal_approx(material.get_shader_parameter("health_ratio"), 1.0 / 3.0))
	bar.call("set_health", 0, 9)
	assert(not bar.get("fill").visible)
	print("Single-surface health bars: PASS")
	quit(0 if stopped <= 3 else 1)
