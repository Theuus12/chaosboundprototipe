extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	arena.add_child(enemy)
	enemy.call("apply_difficulty", 0)
	assert(enemy.get("move_speed") == 4.5)
	arena.set("elapsed_time", 899.9)
	arena.call("_physics_process", 0.0)
	assert(arena.call("overtime_multiplier") == 1.0)
	arena.set("elapsed_time", 900.0)
	arena.call("_physics_process", 0.0)
	assert(enemy.get("max_health") == 200 and enemy.get("contact_damage") == 20)
	arena.set("elapsed_time", 1200.0)
	arena.call("_physics_process", 0.0)
	assert(enemy.get("max_health") == 400 and enemy.get("move_speed") == 9.0)
	var stats := arena.get_node("StatsMenu")
	stats.call("toggle")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.ctrl_pressed = true
	stats.call("item_click", click, 0)
	for attribute in ["projectiles", "speed", "damage"]:
		assert(player.get("weapons")[10][attribute] == 1.0)
	assert(stats.get("item_labels")[0].text.contains("Velocidade de ataque"))
	print("Overtime: PASS")
	quit(0)
