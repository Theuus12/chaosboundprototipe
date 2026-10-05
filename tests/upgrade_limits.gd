extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	var player = arena.player
	player.set_physics_process(false)
	player.buff_slots.assign([0, 1, 2, 15])
	for kind in player.buff_slots:
		player.buff_stacks[kind] = 99
		assert(player.apply_upgrade(kind, 1.0))
		assert(player.buff_stacks[kind] == 100)
		assert(not player.apply_upgrade(kind, 1.0))
	assert(player.eligible_buffs(preload("res://scripts/tomes.gd").catalog()).is_empty())
	for weapon in player.weapons:
		player.weapons[weapon].unlocked = true
		player.weapons[weapon].level = 49
		assert(player.apply_weapon_upgrade(weapon, {"damage": 1.0}))
		assert(player.weapons[weapon].level == 50)
		assert(not player.apply_weapon_upgrade(weapon, {"damage": 1.0}, true))
	var menu = arena.get_node("UpgradeMenu")
	player.collect_xp(250)
	assert(player.level == 3 and player.xp == 50)
	assert(not paused and not menu.choosing and not menu.overlay.visible)
	assert(menu.offered.is_empty())
	# An uncapped equipped crystal remains eligible while capped weapons do not.
	player.buff_stacks[15] = 99
	player.collect_xp(50)
	assert(paused and menu.offered == [15])
	menu.choose(0)
	assert(player.buff_stacks[15] == 100 and not paused)
	print("Crystal level 100, weapon level 50, offer filtering and continued XP PASS")
	quit()
