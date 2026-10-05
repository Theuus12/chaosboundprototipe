extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	var player = arena.player
	var counts = [0, 0, 0]
	for i in range(1000):
		counts[player.xp_orb_tier(float(i) / 1000)] += 1
	assert(counts == [850, 100, 50])
	assert(player.xp_drop_chance() == 1.0)
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	for roll in [0.01, 0.1, 0.9]:
		enemy.drop_loot(roll, roll, 1)
	var orbs = get_nodes_in_group("pickups")
	assert(orbs.size() == 3)
	assert(orbs[0].xp_tier == 2 and orbs[1].xp_tier == 1 and orbs[2].xp_tier == 0)
	orbs[0].collect()
	assert(player.xp == 50)
	orbs[1].collect()
	assert(player.xp == 80)
	orbs[2].collect()
	assert(player.xp == 90)
	player.extra_xp_chance = 100
	assert(player.xp_orb_tier(0.19) == 2)
	assert(player.xp_orb_tier(0.99) == 1)
	print("Guaranteed XP drop: 85% 10XP, 10% 30XP, 5% 50XP; crystal boosts quality PASS")
	quit()
