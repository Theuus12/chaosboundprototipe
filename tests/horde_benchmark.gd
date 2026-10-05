extends SceneTree
var physics_times: Array[float] = []
var frame_times: Array[float] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	print("Arena ready")
	var player: CharacterBody3D = arena.get("player")
	var mixed := OS.get_cmdline_user_args().has("--mixed")
	var count := 100 if OS.get_cmdline_user_args().has("--100") else 200
	player.set("damage_grace_left", 100000.0)
	player.call("apply_weapon_upgrade", 10, {"projectiles": 4.0})
	await create_timer(0.6).timeout
	for i in range(count):
		var enemy := CharacterBody3D.new()
		var script_path := "res://scripts/enemy.gd"
		if mixed and i == count - 1:
			script_path = "res://scripts/orc_boss.gd"
		elif mixed and i % 20 == 0:
			script_path = "res://scripts/lich.gd"
		enemy.set_script(load(script_path))
		if mixed and i % 20 == 1:
			enemy.set("model_path", "res://assets/characters/skeleton/skeleton.glb")
		enemy.set("max_health", 1000000)
		enemy.set("target", player)
		var angle := i * TAU / count
		var radius := 16.0 + (i % 5) * 2.0
		enemy.position = Vector3(cos(angle) * radius, 0.1, sin(angle) * radius)
		arena.add_child(enemy)
		if i % 10 == 0:
			await process_frame
	print(count, " enemies spawned")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/crowd-health-preview.png")
	var previous := Time.get_ticks_usec()
	for i in range(360):
		await process_frame
		var now := Time.get_ticks_usec()
		frame_times.append((now - previous) / 1000.0)
		physics_times.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
		previous = now
		if i % 30 == 0:
			print("Measured frames: ", i, " enemies: ", get_nodes_in_group("enemies").size())
	frame_times.sort()
	physics_times.sort()
	var average := 0.0
	for ms in frame_times:
		average += ms / frame_times.size()
	var report := "%d %s, normal arena, moving AI and five-arrow volleys.\nFrames: %d\nAverage frame: %.2f ms (%.1f FPS)\nMedian frame: %.2f ms\nP95 frame: %.2f ms\nP95 physics: %.2f ms\nEnemies remaining: %d\nDraw calls: %d\n" % [count, "mixed enemies including a boss" if mixed else "goblins", frame_times.size(), average, 1000.0 / average, frame_times[180], frame_times[342], physics_times[342], get_nodes_in_group("enemies").size(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
	FileAccess.open("res://builds/horde-benchmark-100.txt" if count == 100 else ("res://builds/horde-benchmark-mixed.txt" if mixed else "res://builds/horde-benchmark.txt"), FileAccess.WRITE).store_string(report)
	if arena.has_node("EnemyVisualBatch"):
		print("Mesh batches: ", arena.get_node("EnemyVisualBatch").get("batches").size())
	print(report)
	quit()
