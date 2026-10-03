extends SceneTree
## Executar: Godot --headless --path . --script res://tests/combat_smoke.gd
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	# Disable automatic spawning so all checks use a controlled enemy.
	arena.set("spawn_left", 1000.0)
	for i in range(10):
		await physics_frame
	arena.call("spawn_enemy")
	var enemies := get_nodes_in_group("enemies")
	check(enemies.size() == 1, "Spawn deve criar um inimigo no mapa navegavel")
	if enemies.is_empty():
		quit(1)
		return
	var player := arena.get("player") as CharacterBody3D
	player.set("shot_left", 10000.0)
	var enemy := enemies[0] as CharacterBody3D
	var initial_distance := enemy.global_position.distance_to(player.global_position)
	check(initial_distance >= 8.0 and initial_distance <= 13.5, "Spawn deve respeitar distancia do jogador")
	for i in range(90):
		await physics_frame
	check(enemy.global_position.distance_to(player.global_position) < initial_distance, "Inimigo deve se aproximar do jogador")
	enemy.call("take_damage", 10)
	check(enemy.get("health") == 20, "Dano deve reduzir vida do inimigo")
	player.global_position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	enemy.global_position = Vector3(0.85, 0, 0)
	enemy.velocity = Vector3.ZERO
	for i in range(10):
		await physics_frame
	check(player.get("health") == 90, "Contato deve causar 10 de dano uma unica vez durante protecao")
	player.call("take_damage", 10)
	check(player.get("health") == 90, "Protecao deve bloquear dano repetido")
	player.set("damage_grace_left", 0.0)
	player.call("take_damage", 200)
	check(player.get("health") == 0 and player.get("dead"), "Vida deve chegar a zero e marcar morte")
	var dead_position := player.global_position
	for i in range(10):
		await physics_frame
	check(player.global_position.is_equal_approx(dead_position), "Jogador morto deve parar")
	enemy.call("take_damage", 30)
	await process_frame
	check(get_nodes_in_group("enemies").is_empty(), "Inimigo sem vida deve ser removido")
	print("Combat smoke: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
