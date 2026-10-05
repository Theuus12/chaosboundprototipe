extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202c28")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("dfeddf")
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	scene.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 1.3
	scene.add_child(sun)
	for i in range(5):
		var statue := StaticBody3D.new()
		statue.set_script(load("res://scripts/buff_statue.gd"))
		statue.set("rarity", i)
		statue.position.x = (i - 2) * 2.7
		scene.add_child(statue)
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.position = Vector3(1.5, 5, -14)
	camera.look_at(Vector3(0, 2, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.5
	camera.current = true
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png("res://builds/statue-preview.png")
	print("Statue preview saved")
	quit()
