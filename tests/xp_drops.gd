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
	player.collect_xp()
	assert(player.xp == 10)
	player.collect_xp(20)
	assert(player.xp == 30)
	assert(is_equal_approx(player.xp_drop_chance(), 0.3))
	assert(player.large_xp_chance() == 0)
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.drop_loot(0.30, 0, 1)
	assert(get_nodes_in_group("pickups").is_empty())
	enemy.drop_loot(0.29, 0, 1)
	assert(get_nodes_in_group("pickups").size() == 1)
	assert(not get_nodes_in_group("pickups")[0].large_xp)
	player.extra_xp_chance = 20
	assert(is_equal_approx(player.xp_drop_chance(), 0.5))
	assert(is_equal_approx(player.large_xp_chance(), 0.2))
	enemy.drop_loot(0.49, 0.19, 1)
	var pickups = get_nodes_in_group("pickups")
	assert(pickups.size() == 2 and pickups[1].large_xp)
	assert(is_equal_approx(pickups[1].visual.mesh.radius, 0.28))
	print("XP 10/20, 30% drop and crystal drop/large-orb chances PASS")
	quit()
