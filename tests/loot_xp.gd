extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	player.set("shot_left", 10000.0)
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	enemy.position = Vector3(20, 0, 20)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	# 1000 resultados igualmente espacados validam as faixas exatas.
	for i in range(1000):
		enemy.call("drop_loot", float(i) / 1000.0)
	var blue := 0
	var yellow := 0
	for pickup in get_nodes_in_group("pickups"):
		if pickup.get("bonus"):
			yellow += 1
		else:
			blue += 1
		pickup.free()
	if blue != 900 or yellow != 300:
		push_error("Probabilidades incorretas: %d azuis, %d amarelas" % [blue, yellow])
		quit(1)
		return
	for i in range(5):
		var pickup := Node3D.new()
		pickup.set_script(load("res://scripts/pickup.gd"))
		pickup.set("target", player)
		arena.add_child(pickup)
		pickup.global_position = player.global_position + Vector3.UP * 0.45
		await physics_frame
		await physics_frame
		if player.get("xp") != ((i + 1) * 20) % 100:
			push_error("Cada coleta deve preencher exatamente 20%")
			quit(1)
			return
	if player.get("level") != 2:
		quit(1)
		return
	player.call("collect_bonus")
	if player.get("bonus_orbs") != 1 or player.get("xp") != 0:
		quit(1)
		return
	print("Loot XP: PASS")
	quit(0)
