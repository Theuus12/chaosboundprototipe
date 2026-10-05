extends Node3D
## Olho infernal sem asas, bracos ou prolongamentos laterais.

var phase := 0.0
var parts: Array[MeshInstance3D] = []
var iris: MeshInstance3D
var flashing := false
var flash_material: StandardMaterial3D

func _ready() -> void:
	sphere(Vector3.ZERO, Vector3(0.76, 0.86, 0.65), Color("8f1833"))
	# O rosto aponta para -Z, a mesma direcao usada pelos inimigos.
	sphere(Vector3(0, 0, -0.38), Vector3(0.64, 0.69, 0.37), Color("ead4a1"))
	iris = sphere(Vector3(0, 0, -0.69), Vector3(0.39, 0.52, 0.11), Color("ff8d20"))
	var glow := iris.material_override as StandardMaterial3D
	glow.emission_enabled = true
	glow.emission = Color("ff681b")
	glow.emission_energy_multiplier = 0.6
	sphere(Vector3(0, 0, -0.79), Vector3(0.085, 0.43, 0.035), Color("261011"))
	sphere(Vector3(-0.15, 0.23, -0.805), Vector3(0.065, 0.065, 0.015), Color("fff8da"))
	# Placas osseas compactas ao redor do corpo, sem extensoes nos lados.
	for i in range(10):
		var angle := float(i) / 10.0 * TAU
		var plate := sphere(Vector3(sin(angle) * 0.66, cos(angle) * 0.75, -0.38), Vector3(0.16, 0.2, 0.13), Color("c99b6a"))
		plate.rotation.z = -angle
	spike(Vector3(0, 0.93, -0.05), 0.19, 0.66, Color("f0c994"))
	var lower := spike(Vector3(0, -0.96, -0.1), 0.15, 0.52, Color("bc805a"))
	lower.rotation.z = PI
	# Pequenas tiras inferiores dao uma silhueta irregular ao corpo flutuante.
	for x in [-0.4, -0.2, 0.2, 0.4]:
		var strip := spike(Vector3(x, -0.72, 0.05), 0.09, 0.42, Color("a62643"))
		strip.rotation.z = PI + x * 0.4
	# Veios vermelhos sobre a parte clara do olho.
	for side in [-1, 1]:
		for y in [-0.3, 0.0, 0.32]:
			vein(Vector3(side * 0.52, y, -0.64), Vector3(side * 0.36, y + 0.07, -0.72))
			vein(Vector3(side * 0.36, y + 0.07, -0.72), Vector3(side * 0.29, y + 0.03, -0.75))
	flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE

func part(mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	node.material_override = material
	node.set_meta("original_material", material)
	add_child(node)
	parts.append(node)
	return node

func sphere(pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	var node := part(mesh, pos, color)
	node.scale = dimensions
	return node

func spike(pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 5
	return part(mesh, pos, color)

func vein(start: Vector3, finish: Vector3) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.012
	mesh.bottom_radius = 0.018
	mesh.height = start.distance_to(finish)
	mesh.radial_segments = 4
	var node := part(mesh, (start + finish) * 0.5, Color("b12b36"))
	var axis := (finish - start).normalized()
	var side := axis.cross(Vector3.FORWARD).normalized()
	node.basis = Basis(side, axis, side.cross(axis))

func animate(delta: float, _speed: float, _climbing: bool, flash: bool) -> void:
	phase += delta
	position.y = 1.35 + sin(phase * 2.4) * 0.12
	rotation.z = sin(phase * 1.6) * 0.04
	if flash != flashing:
		flashing = flash
		for node in parts:
			node.material_override = flash_material if flash else node.get_meta("original_material")
