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
	player.call("apply_upgrade", 1, 3.0)
	var enemies: Array[Node3D] = []
	for point in [Vector3(5, 0, 0), Vector3(-8, 0, 0)]:
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.set("target", player)
		enemy.position = point
		arena.add_child(enemy)
		enemy.set_physics_process(false)
		enemies.append(enemy)
	player.call("shoot_arrow")
	var arrows := get_nodes_in_group("arrows")
	assert(arrows.size() == 4)
	var origins := {}
	for arrow in arrows:
		origins[arrow.global_position] = true
		var aim: Vector3 = (enemies[0].global_position + Vector3.UP * 0.7 - arrow.global_position).normalized()
		assert(aim.dot(arrow.get("direction")) > 0.9999)
	assert(origins.size() == 4)
	print("Volley aim: PASS (four simultaneous radial origins, same nearest target)")
	quit()
