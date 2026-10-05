extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	var player: CharacterBody3D = arena.get("player")
	player.set_physics_process(false)
	player.global_position = Vector3(0, 0.1, 0)
	player.call("apply_character_buff", 8, 5.0)
	var camera := Camera3D.new()
	arena.add_child(camera)
	camera.position = Vector3(3, 3.2, 6)
	camera.look_at(Vector3(0, 1.4, 0))
	camera.current = true
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/shield-preview.png")
	player.set("coins", 5.0)
	arena.get_node("UpgradeMenu").call("queue_level", 2)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/upgrade-prices-preview.png")
	paused = false
	quit()
