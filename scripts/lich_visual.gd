extends Node3D

var phase := 0.0
var casting := false
var parts: Array[MeshInstance3D] = []
var staff: Node3D

func _ready() -> void:
	# Stylized skeletal mage: burgundy robes, gold crown and violet crystals.
	cone(Vector3(0, 0.8, 0), 0.7, 0.3, 1.5, Color("422442"))
	cone(Vector3(0, 1.35, 0.12), 0.64, 0.27, 1.2, Color("8a2354"))
	sphere(Vector3(0, 2.12, 0), Vector3(0.38, 0.46, 0.31), Color("332139"))
	sphere(Vector3(0, 2.14, -0.19), Vector3(0.25, 0.3, 0.21), Color("e5d3a1"))
	for side in [-1, 1]:
		sphere(Vector3(side * 0.1, 2.2, -0.36), Vector3(0.065, 0.05, 0.025), Color("df43ff"))
		cone(Vector3(side * 0.27, 2.51, 0), 0.12, 0, 0.48, Color("d4a348"))
		sphere(Vector3(side * 0.5, 1.75, 0), Vector3(0.35, 0.18, 0.3), Color("d4a348"))
		cone(Vector3(side * 0.64, 1.91, 0), 0.12, 0, 0.38, Color("d4a348"))
		cone(Vector3(side * 0.52, 1.16, 0.14), 0.24, 0.1, 1.05, Color("8a2354"))
		sphere(Vector3(side * 0.54, 1.62, -0.12), Vector3(0.11, 0.08, 0.12), Color("e5d3a1"))
	for i in range(4):
		sphere(Vector3(0, 1.25 + i * 0.12, -0.32), Vector3(0.23 - i * 0.025, 0.025, 0.045), Color("e5d3a1"))
	cone(Vector3(0, 2.59, -0.03), 0.16, 0, 0.62, Color("d4a348"))
	gem(Vector3(0, 2.5, -0.16), 0.12)
	gem(Vector3(0, 0.98, -0.49), 0.17)
	staff = Node3D.new()
	staff.position = Vector3(-0.8, 0, -0.12)
	add_child(staff)
	var shaft := cone(Vector3(-0.8, 1.2, -0.12), 0.055, 0.055, 2.4, Color("6c463b"))
	remove_child(shaft)
	staff.add_child(shaft)
	shaft.position = Vector3(0, 1.2, 0)
	gem(Vector3(-0.8, 2.52, -0.12), 0.25)
	for side in [-1, 1]:
		cone(Vector3(-0.8 + side * 0.22, 2.54, -0.12), 0.09, 0, 0.5, Color("d4a348"))

func part(mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	node.material_override = material
	add_child(node)
	parts.append(node)
	return node

func cone(pos: Vector3, bottom: float, top: float, height: float, color: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 7
	return part(mesh, pos, color)

func sphere(pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 8
	mesh.rings = 4
	part(mesh, pos, color).scale = dimensions

func gem(pos: Vector3, radius: float) -> void:
	cone(pos + Vector3.UP * radius / 2, radius, 0, radius, Color("c538ff"))
	cone(pos - Vector3.UP * radius / 2, 0, radius, radius, Color("7924c9"))

func animate(delta: float, _speed: float, _climbing: bool, flash: bool) -> void:
	phase += delta
	position.y = 0.12 + sin(phase * 2) * 0.08
	staff.rotation.x = -0.35 if casting else sin(phase * 2) * 0.04
	for node in parts:
		var material := node.material_override as StandardMaterial3D
		material.emission_enabled = flash or casting
		material.emission = Color("ff7329") * 0.35 if casting else Color.WHITE * 0.3
