extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func clear_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.free()

func spawn_checked(arena: Node) -> void:
	for attempt in range(60):
		if arena.spawn_enemy():
			return
		await physics_frame
	assert(false, "Could not find a valid spawn point")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	for i in range(10):
		await physics_frame
	assert(get_nodes_in_group("boss_altars").size() == 1)
	assert(get_nodes_in_group("buff_statues").size() == 15)
	var altar = arena.boss_altar
	assert(not altar.activate())
	arena.elapsed_time = 600.0
	arena.update_events()
	assert(not arena.final_boss_spawned)
	clear_enemies()
	arena.elapsed_time = 180.0
	arena.enemies_since_soldier = 9
	arena.enemies_since_lich = 0
	await spawn_checked(arena)
	assert(get_nodes_in_group("orc_soldiers").size() == 1)
	assert(get_nodes_in_group("bosses").is_empty())
	clear_enemies()
	arena.elapsed_time = 300.0
	for i in range(24):
		await spawn_checked(arena)
	assert(get_nodes_in_group("goblins").is_empty())
	assert(get_nodes_in_group("orc_soldiers").is_empty())
	assert(get_nodes_in_group("skeletons").size() > 0)
	assert(get_nodes_in_group("liches").size() > 0)
	assert(get_nodes_in_group("infernal_eyes").is_empty())
	clear_enemies()
	arena.player.global_position = altar.global_position + Vector3(0, 1, 4.5)
	assert(altar.activate())
	assert(not altar.activate())
	var bosses := get_nodes_in_group("final_bosses")
	assert(bosses.size() == 1)
	var boss = bosses[0]
	boss.set_physics_process(false)
	assert(boss.health == 50000)
	assert(is_equal_approx(boss.body_height, 10.9))
	boss.apply_difficulty(100, 8)
	assert(boss.health == 50000)
	assert(not arena.infernal_eyes_unlocked)
	boss.take_damage(50000)
	assert(arena.infernal_eyes_unlocked)
	assert(boss.is_queued_for_deletion())
	await process_frame
	await spawn_checked(arena)
	assert(get_nodes_in_group("infernal_eyes").size() == 1)
	print("Altar unique ritual, 50000 HP boss, soldier and five-minute spawn transition, eye unlock PASS")
	clear_enemies()
	await create_timer(1.0).timeout
	arena.queue_free()
	await process_frame
	await process_frame
	quit()
