extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	player.set("slash_left", 10000.0)
	player.set("shot_left", 10000.0)
	for i in range(10):
		await physics_frame
	assert(arena.call("effective_wave_size") == 1)
	player.call("apply_upgrade", 3, 10.0)
	assert(arena.call("effective_wave_size") == 4)
	arena.call("spawn_wave")
	assert(get_nodes_in_group("enemies").size() == 4)
	for enemy in get_nodes_in_group("enemies"):
		assert(enemy.get("max_health") == 110)
		enemy.free()
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	enemy.position = Vector3(0, 0, -5)
	arena.add_child(enemy)
	enemy.call("apply_difficulty", 10)
	enemy.set_physics_process(false)
	player.call("shoot_arrow")
	for i in range(25):
		await physics_frame
	assert(is_instance_valid(enemy) and enemy.get("health") == 10, "Flecha deve dar 100 de dano sem matar monstro de 110 HP")
	assert(player.get("kills") == 0)
	player.call("shoot_arrow")
	for i in range(25):
		await physics_frame
	assert(not is_instance_valid(enemy) and player.get("kills") == 1)
	player.call("apply_upgrade", 3, 10.0)
	assert(arena.call("effective_wave_size") == 7)
	print("Difficulty combat: PASS")
	quit(0)
