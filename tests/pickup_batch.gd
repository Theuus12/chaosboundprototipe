extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	for i in range(1000):
		var orb := Node3D.new()
		orb.set_script(load("res://scripts/pickup.gd"))
		orb.set("target", arena.player)
		orb.set("large_xp", i % 2 == 0)
		orb.position = Vector3(20, 0.3, 20)
		arena.add_child(orb)
	var batch = arena.get_node("PickupBatch")
	batch.set_physics_process(false)
	batch.rebuild()
	assert(batch.batches.size() == 2)
	assert(batch.batches[0].multimesh.instance_count == 500)
	assert(batch.batches[1].multimesh.instance_count == 500)
	arena.player.collect_magnet()
	batch.call("_physics_process", 0.016)
	assert(arena.player.level == 201 and arena.player.xp == 0)
	assert(batch.batches.is_empty())
	print("1000 XP orbs in two draw batches; magnet preserves all 20000 XP PASS")
	quit()
