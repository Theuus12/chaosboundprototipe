extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var statues := get_nodes_in_group("buff_statues")
	assert(statues.size() == 15)
	var counts := [0, 0, 0, 0, 0]
	var player: CharacterBody3D = arena.get("player")
	for statue in statues:
		counts[statue.get("rarity")] += 1
		assert(statue.get("skull_material").albedo_color == preload("res://scripts/buff_rarity.gd").COLORS[statue.get("rarity")])
		for tree in get_nodes_in_group("trees"):
			assert(Vector2(statue.position.x, statue.position.z).distance_to(Vector2(tree.position.x, tree.position.z)) >= 4.0)
	assert(counts == [3, 3, 3, 3, 3])
	var statue: StaticBody3D = statues[2]
	player.position = Vector3.ZERO
	player.set("coins", 1000.0)
	assert(statue.call("offers", player).is_empty())
	assert(player.get("coins") == 1000.0)
	player.global_position = statue.global_position + Vector3(0, 0.1, 2)
	player.set("coins", 0.0)
	assert(player.get("buff_slots").is_empty())
	assert(statue.call("offers", player).size() == 3)
	var result: Dictionary = statue.call("claim", player, 0)
	assert(result.ok and result.rarity == 2)
	assert(player.get("coins") == 0.0)
	assert(player.get("character_buff_rarities")[result.kind] == 2)
	assert(not statue.call("claim", player, 0).ok)
	assert(player.get("coins") == 0.0)
	# Nenhuma cobrança quando os quatro slots atingiram o nível máximo.
	var stacks: Dictionary = player.get("buff_stacks")
	var slots: Array[int] = [0, 1, 2, 4]
	player.set("buff_slots", slots)
	for kind in slots:
		stacks[kind] = player.MAX_CRYSTAL_LEVEL
	var second: StaticBody3D = statues[3]
	player.global_position = second.global_position + Vector3(0, 0.1, 2)
	assert(second.call("offers", player).size() == 3)
	assert(player.get("coins") == 0.0 and not second.get("purchased"))
	print("Statue shrines: PASS (15 statues, rarity, spacing, free reward, range, limits)")
	quit()
