extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	var player: Node = arena.get("player")
	player.set_physics_process(false)
	var menu: Node = arena.get_node("UpgradeMenu")
	menu.call("queue_level", 2)
	var ban_id: int = menu.get("offered")[0]
	menu.call("toggle_ban")
	menu.call("choose", 0)
	assert(ban_id in menu.get("banned"))
	assert(menu.get("pending_levels") == [2])
	for i in range(20):
		menu.call("reroll_choices")
		assert(ban_id not in menu.get("offered"))
	assert(player.get("buff_slots").is_empty())
	menu.call("queue_level", 3)
	menu.call("skip_level")
	assert(menu.get("pending_levels") == [3])
	menu.call("skip_level")
	assert(not paused and not menu.get("choosing"))
	assert(player.get("buff_slots").is_empty())
	menu.get("banned").assign(preload("res://scripts/tomes.gd").catalog() + [10, 11, 12, 26])
	menu.call("queue_level", 4)
	assert(menu.get("offered").is_empty())
	menu.call("skip_level")
	player.call("apply_weapon_upgrade", 12, {"area": 1.0})
	assert(is_equal_approx(player.call("weapon_radius", 12, 2.5), 2.5 * sqrt(1.03)))
	arena.free()
	var main: Control = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(main)
	assert(main.get("main").get_child(1).text == "Jogar")
	assert(main.get("main").get_child(2).text == "Opções")
	assert(main.get("main").get_child(3).text == "Sair")
	print("Upgrade actions: ban persistence, reroll, skip, exhaustion, area and main menu PASS")
	quit()
