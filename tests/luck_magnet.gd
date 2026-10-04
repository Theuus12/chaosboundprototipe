extends SceneTree
const Rarity = preload("res://scripts/buff_rarity.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var base := Rarity.probabilities(0)
	var lucky := Rarity.probabilities(100)
	assert(lucky[4] > base[4] and lucky[0] < base[0])
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	player.set("shot_left", 10000.0)
	player.set("slash_left", 10000.0)
	player.call("apply_upgrade", 5, 13.0, 4)
	player.call("apply_upgrade", 5, 3.0)
	assert(player.get("luck_bonus") == 16 and 5 in player.get("buff_slots"))
	var orbs: Array[Node3D] = []
	for i in range(3):
		var orb := Node3D.new()
		orb.set_script(load("res://scripts/pickup.gd"))
		orb.set("target", player)
		orb.set("bonus", i == 2)
		orb.position = Vector3(20, 0.3, 10 + i)
		arena.add_child(orb)
		orbs.append(orb)
	arena.call("spawn_magnet", Vector3(0, 0.45, 0))
	var magnet: Node3D = get_nodes_in_group("magnets")[0]
	magnet.global_position = player.global_position + Vector3.UP * 0.45
	await physics_frame
	await physics_frame
	assert(player.get("magnets_collected") == 1)
	await physics_frame
	assert(not is_instance_valid(orbs[0]) or orbs[0].is_queued_for_deletion())
	assert(not is_instance_valid(orbs[1]) or orbs[1].is_queued_for_deletion())
	assert(not orbs[2].get("magnetized"))
	assert(player.get("xp") == 40)
	assert(is_instance_valid(orbs[2]))
	# Yellow orbs also collect in one physics step once inside attraction range.
	orbs[2].global_position = player.global_position + Vector3.UP * 0.45 + Vector3.RIGHT
	orbs[2].call("_physics_process", 1.0 / 60.0)
	assert(orbs[2].is_queued_for_deletion())
	assert(player.get("bonus_orbs") == 1)
	assert(player.get("item_slots") == ["Arco", "", "", ""])
	print("Luck magnet: PASS")
	quit(0)
