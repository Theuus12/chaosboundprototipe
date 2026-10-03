extends Node3D
## Modelo geometrico original. A frente do personagem aponta para -Z.
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var torso: Node3D
var phase: float = 0.0

func _ready() -> void:
	torso = Node3D.new()
	add_child(torso)
	box(torso, Vector3(0, 1.05, 0), Vector3(0.58, 0.63, 0.36), Color("36735b"))
	box(torso, Vector3(0, 0.79, 0), Vector3(0.62, 0.1, 0.4), Color("614331"))
	box(torso, Vector3(0, 0.79, -0.215), Vector3(0.13, 0.12, 0.04), Color("d9b66b"))
	# Capuz envolvendo o rosto, com abertura frontal escura.
	var hood := SphereMesh.new()
	hood.radius = 0.33
	hood.height = 0.66
	hood.radial_segments = 12
	hood.rings = 6
	part(torso, hood, Vector3(0, 1.57, 0), Color("28513f"))
	box(torso, Vector3(0, 1.56, -0.27), Vector3(0.38, 0.37, 0.09), Color("172c28"))
	box(torso, Vector3(0, 1.53, -0.325), Vector3(0.26, 0.27, 0.045), Color("d7a477"))
	for x in [-0.065, 0.065]:
		box(torso, Vector3(x, 1.58, -0.352), Vector3(0.04, 0.035, 0.015), Color("202b30"))
	# Capa curta e aljava nas costas.
	box(torso, Vector3(0, 1.0, 0.24), Vector3(0.65, 0.68, 0.07), Color("213e38"))
	var quiver := CylinderMesh.new()
	quiver.top_radius = 0.12
	quiver.bottom_radius = 0.09
	quiver.height = 0.57
	quiver.radial_segments = 8
	var quiver_part := part(torso, quiver, Vector3(0.21, 1.13, 0.34), Color("845738"))
	quiver_part.rotation.z = -0.22
	for i in range(3):
		var x: float = 0.14 + i * 0.06
		segment(torso, Vector3(x, 1.28, 0.34), Vector3(x + 0.08, 1.68, 0.34), 0.014, Color("c7ad79"))
		box(torso, Vector3(x + 0.075, 1.61, 0.34), Vector3(0.07, 0.12, 0.025), Color("e0ddd0"))
	left_leg = limb(Vector3(-0.16, 0.76, 0), Vector3(0.22, 0.49, 0.24), Color("514d3e"))
	right_leg = limb(Vector3(0.16, 0.76, 0), Vector3(0.22, 0.49, 0.24), Color("514d3e"))
	for leg in [left_leg, right_leg]:
		box(leg, Vector3(0, -0.57, -0.035), Vector3(0.25, 0.3, 0.34), Color("493429"))
	left_arm = limb(Vector3(-0.4, 1.31, 0), Vector3(0.19, 0.43, 0.2), Color("36735b"))
	right_arm = limb(Vector3(0.4, 1.31, 0), Vector3(0.19, 0.43, 0.2), Color("36735b"))
	for arm in [left_arm, right_arm]:
		box(arm, Vector3(0, -0.39, 0), Vector3(0.2, 0.2, 0.21), Color("775038"))
		box(arm, Vector3(0, -0.52, 0), Vector3(0.17, 0.14, 0.17), Color("d7a477"))
	# Arco curvo feito de segmentos; acompanha a mao esquerda.
	var points: Array[Vector3] = []
	for i in range(9):
		var angle: float = -PI / 2.0 + i * PI / 8.0
		points.append(Vector3(-0.07, -0.49 + sin(angle) * 0.62, -0.08 - cos(angle) * 0.26))
	for i in range(points.size() - 1):
		segment(left_arm, points[i], points[i + 1], 0.035, Color("bd8c50"))
	segment(left_arm, points[0], points[8], 0.008, Color("e4d7b2"))

func animate(delta: float, speed: float, grounded: bool, dashing: bool) -> void:
	phase += delta * (5.0 + speed * 0.8)
	var stride: float = minf(speed / 14.0, 1.0) if grounded else 0.0
	var swing: float = sin(phase) * stride * 0.65
	left_leg.rotation.x = lerpf(left_leg.rotation.x, swing if grounded else -0.4, minf(delta * 15.0, 1.0))
	right_leg.rotation.x = lerpf(right_leg.rotation.x, -swing if grounded else 0.25, minf(delta * 15.0, 1.0))
	left_arm.rotation.x = -swing * 0.45 - 0.12
	right_arm.rotation.x = swing * 0.65
	torso.position.y = absf(sin(phase)) * stride * 0.035
	rotation.x = lerpf(rotation.x, -0.3 if dashing else 0.0, minf(delta * 12.0, 1.0))

func limb(pos: Vector3, size: Vector3, color: Color) -> Node3D:
	var joint := Node3D.new()
	joint.position = pos
	add_child(joint)
	box(joint, Vector3(0, -size.y / 2.0, 0), size, color)
	return joint

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return part(parent, mesh, pos, color)

func part(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	instance.material_override = material
	parent.add_child(instance)
	return instance

func segment(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 6
	var instance := part(parent, mesh, (a + b) * 0.5, color)
	instance.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
