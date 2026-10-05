extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	var lich := CharacterBody3D.new()
	lich.set_script(load("res://scripts/lich.gd"))
	lich.set("target", arena.player)
	arena.add_child(lich)
	lich.set_physics_process(false)
	lich.global_position = arena.player.global_position + Vector3(0, 0, 8)
	assert(lich.health == 30)
	assert(lich.is_in_group("enemies") and lich.is_in_group("liches"))
	assert(lich.visual.parts.size() > 20)
	lich.fire()
	var shots := get_nodes_in_group("enemy_projectiles")
	assert(shots.size() == 1)
	assert(is_equal_approx(shots[0].direction.length(), 1.0))
	assert(shots[0].damage == lich.contact_damage)
	shots[0].set_physics_process(false)
	shots[0].lifetime = 0
	shots[0].call("_physics_process", 0.1)
	assert(shots[0].is_queued_for_deletion())
	for i in range(3):
		await physics_frame
	lich.fire()
	var shot = get_nodes_in_group("enemy_projectiles").back()
	shot.set_physics_process(false)
	shot.global_position = arena.player.global_position + Vector3(0, 0.9, 2)
	shot.direction = Vector3(0, 0, -1)
	var previous_health: int = arena.player.health
	shot.call("_physics_process", 0.4)
	assert(shot.is_queued_for_deletion())
	assert(arena.player.health < previous_health)
	lich.position = arena.player.position + Vector3(0, 0, 8)
	lich.cast_left = 0.0
	lich.call("_physics_process", 0.7)
	assert(is_zero_approx(lich.velocity.x) and is_zero_approx(lich.velocity.z))
	print("Lich visual, combat integration, fireball and expiration PASS")
	quit()
