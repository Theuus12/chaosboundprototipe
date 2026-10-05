extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var hud_script = preload("res://scripts/game_hud.gd")
	assert(hud_script.format_timer(599) == "00:01")
	assert(hud_script.format_timer(600) == "00:00")
	assert(hud_script.format_timer(601) == "-00:01")
	assert(hud_script.format_timer(665) == "-01:05")
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	var player = arena.player
	var hud = arena.get_node("GameHUD")
	var stats = arena.get_node("StatsMenu")
	stats.toggle()
	assert(player.apply_weapon_upgrade(10, {"damage": 1.75}))
	assert(hud.weapon_slots[0].level_label.text == "Nv. 2")
	assert(stats.item_labels[0].text.contains("Nivel 2"))
	assert(player.apply_upgrade(15, 8.0))
	assert(hud.crystal_slots[0].level_label.text == "Nv. 1")
	assert(stats.crystal_slots[0].level_label.text == "Nv. 1")
	assert(player.apply_upgrade(15, 8.0))
	assert(hud.crystal_slots[0].level_label.text == "Nv. 2")
	stats.toggle()
	arena.elapsed_time = 600
	arena.call("_physics_process", 2.0)
	hud.call("_process", 0.016)
	assert(hud.timer_label.text == "-00:02")
	print("Paused inventory/HUD levels synchronized; negative overtime advances PASS")
	quit()
