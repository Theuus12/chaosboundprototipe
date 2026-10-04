extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var visual := Node3D.new()
	visual.set_script(load("res://scripts/goblin_visual.gd"))
	root.add_child(visual)
	assert(visual.get("meshes").size() == 9)
	var colored_vertices := 0
	for mesh in visual.get("meshes"):
		for surface in range(mesh.mesh.get_surface_count()):
			var material = mesh.mesh.surface_get_material(surface)
			assert(material.vertex_color_use_as_albedo)
			var colors = mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]
			assert(colors != null and colors.size() > 0)
			for color in colors:
				if color.r < 0.9 or color.g < 0.9 or color.b < 0.9:
					colored_vertices += 1
	assert(colored_vertices > 100)
	for list_name in ["arms", "legs", "knees", "elbows"]:
		for joint in visual.get(list_name):
			assert(is_instance_valid(joint))
	for i in range(60):
		visual.call("animate", 1.0 / 60.0, 4.5, false, false)
	assert(absf(visual.get("legs")[0].rotation.x) > 0.01)
	visual.call("animate", 0.016, 4.5, false, true)
	for mesh in visual.get("meshes"):
		assert(mesh.material_override != null)
	visual.call("animate", 0.016, 0.0, false, false)
	for mesh in visual.get("meshes"):
		assert(mesh.material_override == null)
	print("Goblin import, articulated walk and hit flash PASS")
	quit()
