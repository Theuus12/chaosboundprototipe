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
	var statue: Node3D = get_nodes_in_group("buff_statues")[0]
	player.global_position = statue.global_position + Vector3(0, 0.1, 3)
	var pivot: Node3D = player.get("pivot")
	pivot.rotation = Vector3(-0.2, 0, 0)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/map-minimap-preview.png")
	print("Map/minimap preview saved")
	quit()
