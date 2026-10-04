extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set("spawn_left", 10000.0)
	var player := arena.get("player") as CharacterBody3D
	player.set("slash_left", 10000.0)
	player.set("shot_left", 10000.0)
	player.set("damage_grace_left", 10000.0)
	for i in range(10):
		await physics_frame
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	arena.add_child(enemy)
	# Longas perseguicoes, incluindo trajeto passando pelas plataformas baixas.
	# Evita iniciar dentro da nova rampa que ocupa x=10..21 em z=-18.
	var starts: Array[Vector3] = [Vector3(0, 0, 18), Vector3(23, 0, -18), Vector3(-20, 0, -20)]
	for start in starts:
		player.global_position = Vector3(0, 0, 3)
		player.velocity = Vector3.ZERO
		enemy.global_position = start
		enemy.velocity = Vector3.ZERO
		enemy.set("repath_left", 0.0)
		for i in range(600):
			await physics_frame
		if enemy.global_position.distance_to(player.global_position) > 1.3:
			push_error("Inimigo parou antes de chegar: %s -> %s" % [start, enemy.global_position])
			quit(1)
			return
	# Deve retomar a perseguicao quando o jogador muda de lugar.
	player.global_position = Vector3(8, 0, 4)
	for i in range(240):
		await physics_frame
	if enemy.global_position.distance_to(player.global_position) > 1.3:
		push_error("Inimigo nao retomou perseguicao do alvo em movimento")
		quit(1)
		return
	print("Enemy chase: PASS")
	quit(0)
