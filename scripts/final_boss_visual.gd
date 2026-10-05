extends "res://scripts/lich_visual.gd"
## Rei Ossuario: esqueleto coroado, armadura escura e tecido vermelho.

var left_arm: Node3D
var right_arm: Node3D

func _ready() -> void:
	var bone := Color("debf91")
	var armor := Color("504545")
	var red := Color("782335")
	cone(Vector3(0, 0.8, 0.06), 0.45, 0.3, 1.2, red)
	for side in [-1, 1]:
		sphere(Vector3(side * 0.28, 0.55, 0), Vector3(0.13, 0.45, 0.13), bone)
		sphere(Vector3(side * 0.28, 0.22, -0.03), Vector3(0.21, 0.22, 0.2), armor)
		sphere(Vector3(side * 0.28, 0.09, -0.14), Vector3(0.22, 0.11, 0.3), armor)
		cone(Vector3(side * 0.65, 1.75, 0), 0.29, 0.33, 0.34, armor)
		cone(Vector3(side * 0.65, 2.04, 0), 0.13, 0, 0.47, bone)
		cone(Vector3(side * 0.88, 1.91, 0), 0.1, 0, 0.3, armor)
		cone(Vector3(side * 0.6, 1.35, 0.15), 0.27, 0.12, 0.9, red)
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.65, 1.62, 0)
		add_child(arm)
		if side < 0:
			left_arm = arm
		else:
			right_arm = arm
		var forearm := cone(Vector3.ZERO, 0.16, 0.16, 0.65, bone)
		remove_child(forearm)
		arm.add_child(forearm)
		forearm.position = Vector3(side * 0.2, -0.32, 0)
		var gauntlet := sphere_part(Vector3.ZERO, Vector3(0.2, 0.27, 0.2), armor)
		remove_child(gauntlet)
		arm.add_child(gauntlet)
		gauntlet.position = Vector3(side * 0.25, -0.68, -0.05)
		mini_skull(Vector3(side * 0.42, 1.49, -0.3), 0.13)
	for i in range(5):
		sphere(Vector3(0, 1.15 + i * 0.12, -0.03), Vector3(0.11, 0.08, 0.12), bone)
		for side in [-1, 1]:
			var rib := sphere_part(Vector3(side * 0.23, 1.2 + i * 0.12, -0.12), Vector3(0.24, 0.035, 0.16), bone)
			rib.rotation.z = side * 0.15
	sphere(Vector3(0, 1.02, 0), Vector3(0.43, 0.13, 0.27), armor)
	mini_skull(Vector3(0, 1.04, -0.31), 0.19)
	sphere(Vector3(0, 2.17, 0.03), Vector3(0.35, 0.43, 0.32), red)
	mini_skull(Vector3(0, 2.17, -0.12), 0.29)
	for x in [-0.23, 0.0, 0.23]:
		cone(Vector3(x, 2.59, -0.03), 0.1, 0, 0.54 if x == 0 else 0.4, armor)

func sphere_part(pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1
	mesh.height = 2
	mesh.radial_segments = 8
	mesh.rings = 4
	var node := part(mesh, pos, color)
	node.scale = dimensions
	return node

func mini_skull(pos: Vector3, radius: float) -> void:
	sphere(pos, Vector3(radius, radius * 1.1, radius * 0.75), Color("debf91"))
	for side in [-1, 1]:
		sphere(pos + Vector3(side * radius * 0.38, radius * 0.18, -radius * 0.68), Vector3(radius * 0.24, radius * 0.22, radius * 0.1), Color("281d1b"))
		if radius > 0.2:
			sphere(pos + Vector3(side * radius * 0.38, radius * 0.18, -radius * 0.76), Vector3(radius * 0.1, radius * 0.09, radius * 0.035), Color("ff4426"))
	sphere(pos + Vector3(0, -radius * 0.48, -radius * 0.55), Vector3(radius * 0.5, radius * 0.18, radius * 0.18), Color("34201e"))
	for x in [-0.3, 0.0, 0.3]:
		sphere(pos + Vector3(x * radius, -radius * 0.41, -radius * 0.74), Vector3(radius * 0.1, radius * 0.16, radius * 0.06), Color("eed1a1"))

func animate(delta: float, speed: float, _climbing: bool, flash: bool) -> void:
	phase += delta * (2.0 + speed)
	left_arm.rotation.x = sin(phase) * 0.3
	right_arm.rotation.x = -sin(phase) * 0.3
	position.y = absf(sin(phase)) * 0.025
	for node in parts:
		var material := node.material_override as StandardMaterial3D
		material.emission_enabled = flash
		material.emission = Color.WHITE * 0.4
