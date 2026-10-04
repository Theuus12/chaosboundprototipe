extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena: Node3D = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	var player: CharacterBody3D = arena.get("player")
	player.set_physics_process(false)
	player.position = Vector3.ZERO
	var enemies: Array[Node3D] = []
	for i in range(3):
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.set("target", player)
		enemy.position = Vector3(0, 0, -2.0 - i * 2.0)
		arena.add_child(enemy)
		enemy.set_physics_process(false)
		enemies.append(enemy)
	assert(player.call("apply_weapon_upgrade", 26, {"damage": 1.0}))
	assert(player.get("weapons")[26].level == 1)
	player.call("spawn_slash")
	assert(enemies[0].get("health") == 0)
	await process_frame
	await process_frame
	for i in range(2):
		player.call("apply_weapon_upgrade", 26, {"damage": 1.0})
	assert(player.get("weapons")[26].level == 3)
	player.get("weapons")[26].damage = 0.0
	assert(player.call("effective_weapon_damage", 26) == 100)
	assert(player.call("dagger_bounce_damage") == 30)
	# Replace the sword target so the projectile can hit three distinct targets.
	var replacement := CharacterBody3D.new()
	replacement.set_script(load("res://scripts/enemy.gd"))
	replacement.set("target", player)
	replacement.position = Vector3(0, 0, -2)
	arena.add_child(replacement)
	replacement.set_physics_process(false)
	player.call("shoot_dagger")
	var dagger: Node = get_nodes_in_group("daggers")[0]
	dagger.set_physics_process(false)
	for i in range(90):
		if dagger.is_queued_for_deletion():
			break
		dagger.call("_physics_process", 1.0 / 60.0)
	assert(dagger.get("used").size() == 3)
	assert(dagger.is_queued_for_deletion())
	assert(enemies[1].get("health") == 70 and enemies[2].get("health") == 70)
	player.call("apply_weapon_upgrade", 26, {"projectiles": 1.0, "projectile_speed": 25.0})
	player.call("apply_weapon_upgrade", 26, {"damage": 50.0, "bounces": 1.0})
	assert(player.call("dagger_count") == 2)
	assert(player.call("dagger_hits") == 6)
	assert(player.call("effective_weapon_damage", 26) == 150)
	assert(player.call("dagger_bounce_damage") == 45)
	player.set("projectile_bonus_tenths", 10)
	player.call("shoot_dagger")
	var launched := 0
	for shot in get_nodes_in_group("daggers"):
		if shot.is_queued_for_deletion():
			continue
		launched += 1
		assert(is_equal_approx(shot.get("speed"), 35.0))
	assert(launched == 3)
	assert(player.get("item_slots")[1] == "Adaga reversa")
	print("Sword aim and reverse dagger three-target ricochet PASS")
	quit()
