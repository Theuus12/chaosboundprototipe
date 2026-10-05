extends RefCounted
const MAP_SCALE = 3.0
const MAP_SIZE = 120.0 * MAP_SCALE
const HALF_SIZE = MAP_SIZE * 0.5
const PLAYABLE_LIMIT = HALF_SIZE - 12.0
const HILLS = [Vector2(-24, -20), Vector2(25, 18), Vector2(-26, 25), Vector2(26, -25)]
const HILL_RADIUS = 18.0
const HILL_HEIGHT = 6.0

static func ground_height(x: float, z: float) -> float:
	var height := 0.0
	for center in HILLS:
		var distance := Vector2(x, z).distance_to(center)
		if distance < HILL_RADIUS:
			height += (1.0 + cos(distance / HILL_RADIUS * PI)) * 0.5 * HILL_HEIGHT
	return height

static func terrain(ground: StaticBody3D) -> void:
	ground.position = Vector3.ZERO
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Mesma malha de 80 células, agora com passos de 4,5 unidades.
	for x in range(80):
		for z in range(80):
			var corners: Array[Vector3] = []
			for offset in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]:
				var px: float = -HALF_SIZE + (x + offset.x) * MAP_SIZE / 80.0
				var pz: float = -HALF_SIZE + (z + offset.y) * MAP_SIZE / 80.0
				corners.append(Vector3(px, ground_height(px, pz), pz))
			for index in [0, 1, 2, 0, 2, 3]:
				var vertex := corners[index]
				surface.set_uv(Vector2(vertex.x + HALF_SIZE, vertex.z + HALF_SIZE) / MAP_SIZE)
				surface.add_vertex(vertex)
	surface.generate_normals()
	var mesh := surface.commit()
	ground.get_child(0).shape = mesh.create_trimesh_shape()
	ground.get_child(0).position = Vector3.ZERO
	ground.get_child(1).mesh = mesh
	ground.get_child(1).position = Vector3.ZERO

static func buildings(arena: Node3D) -> void:
	# Peripheral decorative buildings have no collision and cannot block paths.
	for i in range(6):
		var house := Node3D.new()
		house.name = "ForestHouse" if i < 4 else "ForestTower"
		house.add_to_group("buildings")
		house.position = [Vector3(-48, 0, -35), Vector3(47, 0, 34), Vector3(-46, 0, 40), Vector3(46, 0, -40), Vector3(-51, 0, 8), Vector3(51, 0, -8)][i]
		house.position *= MAP_SCALE
		arena.add_child(house)
		if i < 4:
			var wall := BoxMesh.new()
			wall.size = Vector3(4, 2.8, 3.5)
			part(house, wall, Vector3(0, 1.4, 0), Vector3.ONE, Color("ba9f70"))
			var roof := CylinderMesh.new()
			roof.radial_segments = 4
			roof.bottom_radius = 3.5
			roof.top_radius = 0
			roof.height = 1.8
			part(house, roof, Vector3(0, 3.6, 0), Vector3.ONE, Color("794632"))
			var door := BoxMesh.new()
			door.size = Vector3(0.85, 1.8, 0.06)
			part(house, door, Vector3(0, 0.9, -1.78), Vector3.ONE, Color("443021"))
		else:
			var tower := CylinderMesh.new()
			tower.height = 6
			tower.bottom_radius = 1.5
			tower.top_radius = 1.35
			tower.radial_segments = 8
			part(house, tower, Vector3(0, 3, 0), Vector3.ONE, Color("777e7e"))
			var roof := CylinderMesh.new()
			roof.height = 2
			roof.bottom_radius = 1.9
			roof.top_radius = 0
			roof.radial_segments = 8
			part(house, roof, Vector3(0, 7, 0), Vector3.ONE, Color("604433"))

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
	visual.visibility_range_end = 85.0
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
	var ground: StaticBody3D = arena.add_box(Vector3(0, -0.5, 0), Vector3(MAP_SIZE, 1, MAP_SIZE), Color.WHITE)
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
	grass.uv1_scale = Vector3(40, 40, 40) * MAP_SCALE
	grass.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ground.get_child(1).material_override = grass
	terrain(ground)
	buildings(arena)
	var rng := RandomNumberGenerator.new()
	rng.seed = 49137
	var placed: Array[Vector3] = []
	for i in range(900):
		var pos := Vector3(rng.randf_range(-HALF_SIZE + 5, HALF_SIZE - 5), 0, rng.randf_range(-HALF_SIZE + 5, HALF_SIZE - 5))
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
		pos.y = ground_height(pos.x, pos.z)
		tree(arena, pos, i % 3, rng.randf_range(0.8, 1.25))
	for i in range(810):
		var bush := Node3D.new()
		bush.name = "Bush"
		bush.add_to_group("bushes")
		bush.position = Vector3(rng.randf_range(-HALF_SIZE + 5, HALF_SIZE - 5), 0, rng.randf_range(-HALF_SIZE + 5, HALF_SIZE - 5))
		if bush.position.length() < 5.0:
			bush.free()
			continue
		arena.add_child(bush)
		bush.position.y = ground_height(bush.position.x, bush.position.z)
		for j in range(3):
			crown(bush, Vector3((j-1)*0.4, 0.45, rng.randf_range(-0.2, 0.2)), Vector3(0.65, rng.randf_range(0.45, 0.75), 0.6), Color("35632c").lightened(j * 0.04))
