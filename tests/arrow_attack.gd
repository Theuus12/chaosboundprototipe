extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	player.set("damage_grace_left", 10000.0)
	for i in range(10):
		await physics_frame
	# Dois alvos alinhados: uma flecha deve matar apenas o primeiro.
	for z in [-5.0, -8.0]:
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.position = Vector3(0, 0, z)
		enemy.set("target", player)
		arena.add_child(enemy)
		enemy.set_physics_process(false)
	player.set("shot_left", 2.0)
	for i in range(100):
		await physics_frame
	if get_nodes_in_group("enemies").size() != 2 or not get_nodes_in_group("arrows").is_empty():
		push_error("Disparo aconteceu antes de 2 segundos")
		quit(1)
		return
	for i in range(45):
		await physics_frame
	if get_nodes_in_group("enemies").size() != 1:
		push_error("Primeira flecha deve matar exatamente um monstro")
		quit(1)
		return
	for i in range(120):
		await physics_frame
	if not get_nodes_in_group("enemies").is_empty():
		push_error("Segundo disparo automatico deve matar o proximo monstro")
		quit(1)
		return
	player.set("shot_left", 0.01)
	player.set("dead", true)
	for i in range(10):
		await physics_frame
	if not get_nodes_in_group("arrows").is_empty():
		push_error("Jogador morto nao deve disparar")
		quit(1)
		return
	print("Arrow attack: PASS")
	quit(0)
