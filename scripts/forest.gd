extends RefCounted

static func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	return result

static func part(parent: Node3D, mesh: Mesh, pos: Vector3, scale_size: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.position = pos
	visual.scale = scale_size
	visual.material_override = material(color)
	parent.add_child(visual)

static func crown(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 8
	sphere.rings = 4
	part(parent, sphere, pos, size, color)

static func tree(arena: Node3D, pos: Vector3, kind: int, factor: float) -> void:
	var body := StaticBody3D.new()
	body.name = ["Oak", "Pine", "Birch"][kind]
	body.add_to_group("trees")
	body.set_meta("tree_type", kind)
	body.position = pos
	arena.navigation.add_child(body)
	var height: float = [3.0, 4.0, 4.5][kind] * factor
	var radius: float = [0.32, 0.24, 0.20][kind] * factor
	var trunk := CylinderMesh.new()
	trunk.height = height
	trunk.bottom_radius = radius
	trunk.top_radius = radius * 0.7
	trunk.radial_segments = 8
	part(body, trunk, Vector3.UP * height * 0.5, Vector3.ONE, Color("513521") if kind != 2 else Color("c7cab3"))
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius + 0.08
	shape.height = height
	collision.shape = shape
	collision.position.y = height * 0.5
	body.add_child(collision)
	if kind == 1:
		for i in range(3):
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = (1.75 - i * 0.38) * factor
			cone.height = 2.5 * factor
			cone.radial_segments = 9
			part(body, cone, Vector3.UP * (2.4 + i * 1.0) * factor, Vector3.ONE, Color("235b35").lightened(i * 0.035))
	else:
		for i in range(5):
			var angle := i * TAU / 5
			var width := 1.55 if kind == 0 else 1.0
			var offset := Vector3(cos(angle) * 0.75, height + (0.5 if i % 2 == 0 else 0.0), sin(angle) * 0.75)
			crown(body, offset, Vector3(width, 1.25 if kind == 0 else 1.7, width) * factor, Color("39772f").lightened(i * 0.025) if kind == 0 else Color("729438").lightened(i * 0.025))
		if kind == 2:
			for i in range(5):
				var stripe := CylinderMesh.new()
				stripe.height = 0.08
				stripe.top_radius = radius * (1.0 - i * 0.05) + 0.008
				stripe.bottom_radius = stripe.top_radius
				stripe.radial_segments = 8
				part(body, stripe, Vector3.UP * (0.5 + i * 0.65) * factor, Vector3.ONE, Color("343a30"))

static func populate(arena: Node3D) -> void:
	var ground: StaticBody3D = arena.add_box(Vector3(0, -0.5, 0), Vector3(120, 1, 120), Color.WHITE)
	ground.name = "GrassGround"
	var grass := material(Color("72a24a"))
	var noise := FastNoiseLite.new()
	noise.seed = 1729
	noise.frequency = 0.065
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.seamless = true
	texture.noise = noise
	var ramp := Gradient.new()
	ramp.set_color(0, Color("294523"))
	ramp.set_color(1, Color("8aa454"))
	texture.color_ramp = ramp
	grass.albedo_color = Color.WHITE
	grass.albedo_texture = texture
	grass.uv1_scale = Vector3(40, 40, 40)
	grass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ground.get_child(1).material_override = grass
	var rng := RandomNumberGenerator.new()
	rng.seed = 49137
	var placed: Array[Vector3] = []
	for i in range(100):
		var pos := Vector3(rng.randf_range(-55, 55), 0, rng.randf_range(-55, 55))
		if pos.length() < 7.0:
			continue
		var crowded := false
		for other in placed:
			if pos.distance_to(other) < 5.0:
				crowded = true
				break
		if crowded:
			continue
		placed.append(pos)
		tree(arena, pos, i % 3, rng.randf_range(0.8, 1.25))
	for i in range(90):
		var bush := Node3D.new()
		bush.name = "Bush"
		bush.add_to_group("bushes")
		bush.position = Vector3(rng.randf_range(-55, 55), 0, rng.randf_range(-55, 55))
		if bush.position.length() < 5.0:
			bush.free()
			continue
		arena.add_child(bush)
		for j in range(3):
			crown(bush, Vector3((j-1)*0.4, 0.45, rng.randf_range(-0.2, 0.2)), Vector3(0.65, rng.randf_range(0.45, 0.75), 0.6), Color("35632c").lightened(j * 0.04))
