extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	player.set("shot_left", 10000.0)
	player.call("apply_upgrade", 4, 10.0)
	player.call("apply_upgrade", 4, 5.0)
	assert(is_equal_approx(player.call("effective_move_speed"), 10.35))
	assert(not InputMap.has_action("dash") and not InputMap.has_action("sprint"))
	var bindings := InputMap.action_get_events("stats")
	assert(bindings[0].physical_keycode == KEY_ESCAPE)
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	arena.add_child(enemy)
	enemy.call("take_damage", 999)
	enemy.call("take_damage", 999)
	assert(player.get("kills") == 1)
	await process_frame
	await process_frame
	var hud := arena.get_node("GameHUD")
	assert(hud.get("slots").size() == 2)
	assert(hud.get("crystal_slots").size() == 4)
	assert(hud.get("kills_label").text.begins_with("Kills: 1 | Moedas:"))
	for slot in hud.get("slots"):
		assert(slot.get_theme_color("font_color") == Color.WHITE)
	assert(hud.get("level_label").text == "1")
	print("HUD movement: PASS")
	quit(0)
