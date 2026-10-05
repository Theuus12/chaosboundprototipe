extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	for i in range(10):
		await physics_frame
	arena.elapsed_time = 179.99
	arena.update_events()
	assert(not arena.boss_spawned)
	arena.elapsed_time = 180.0
	arena.update_events()
	assert(not arena.boss_spawned)
	assert(arena.orcs_spawned.is_empty())
	arena.elapsed_time = 300.0
	arena.update_events()
	assert(arena.boss.health == 7500)
	assert(is_equal_approx(arena.boss.body_height, 10.9 / 2.0))
	arena.elapsed_time = 479.99
	arena.update_events()
	assert(arena.orcs_spawned.size() == 1)
	arena.elapsed_time = 480.0
	arena.update_events()
	assert(arena.boss.health == 15000)
	# Reset event history before independently checking all four horde boundaries.
	arena.hordes_announced.clear()
	for time in [120.0, 240.0, 360.0, 540.0]:
		arena.pending_spawns = 0
		arena.elapsed_time = time - 0.01
		arena.update_events()
		assert(not arena.horde_active())
		arena.elapsed_time = time
		arena.update_events()
		assert(arena.horde_active())
		assert(arena.announcement == "Uma horda está a caminho")
		var before = arena.pending_spawns
		arena.enemy_defeated()
		assert(arena.pending_spawns == before)
		arena.queue_monsters(3)
		assert(arena.pending_spawns == before + 3)
		arena.elapsed_time = time + 29.99
		assert(arena.horde_active())
		arena.elapsed_time = time + 30.0
		assert(not arena.horde_active())
		before = arena.pending_spawns
		arena.enemy_defeated()
		assert(arena.pending_spawns == before)
	assert(arena.hordes_announced.size() == 4)
	assert(arena.boss_spawned)
	var boss = arena.boss
	boss.set_physics_process(false)
	assert(boss.health == 15000)
	boss.apply_difficulty(100, 8.0)
	assert(boss.health == 15000 and boss.max_health == 15000)
	assert(is_equal_approx(boss.visual.scale.y * 1.89, 10.9))
	boss.take_damage(100)
	assert(boss.health == 14900)
	arena.update_events()
	assert(get_nodes_in_group("bosses").size() == 2)
	# Saturation must not leave an unbounded backlog after a horde.
	arena.elapsed_time = 545.0
	arena.pending_spawns = arena.horde_enemy_limit - get_nodes_in_group("enemies").size() + 1
	var queued = arena.pending_spawns
	arena.enemy_defeated()
	assert(arena.pending_spawns == queued)
	print("Hordes and two unique orc bosses PASS")
	quit()
