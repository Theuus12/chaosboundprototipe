extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	player.global_position = Vector3.ZERO
	player.set("shot_left", 10000.0)
	player.set("slash_left", 10000.0)
	player.get("weapons")[11].unlocked = true
	var enemies: Array[CharacterBody3D] = []
	for pos in [Vector3(0, 0, -2), Vector3(0.6, 0, -2), Vector3(0, 0, 2), Vector3(2, 0, 0), Vector3(0, 0, -4)]:
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.set("max_health", 200)
		enemy.position = pos
		arena.add_child(enemy)
		enemy.set_physics_process(false)
		enemies.append(enemy)
	player.call("perform_slash")
	assert(enemies[0].get("health") == 100 and enemies[1].get("health") == 100)
	for i in range(2, 5):
		assert(enemies[i].get("health") == 200, "Cone nao deve atingir atras, ao lado ou fora do alcance")
	player.get("visual").rotation.y = PI
	player.call("perform_slash")
	assert(enemies[2].get("health") == 100, "Corte deve acompanhar a frente do personagem")
	player.call("apply_upgrade", 0, 5.0, 4)
	var stats := arena.get_node("StatsMenu")
	stats.call("toggle")
	assert(stats.get("buff_labels")[0].get_theme_color("font_color") == Color.WHITE)
	print("Slash attack: PASS")
	quit(0)
