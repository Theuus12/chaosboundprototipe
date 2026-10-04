extends Node3D
## Monstro original de pedra, construído com malhas leves.
var skin: StandardMaterial3D
var limbs: Array[Node3D] = []
var phase: float = 0.0

func _ready() -> void:
	skin = StandardMaterial3D.new()
	skin.albedo_color = Color("75558b")
	skin.roughness = 0.9
	part(Vector3(0.66, 0.66, 0.42), Vector3(0, 0.78, 0), skin)
	part(Vector3(0.6, 0.42, 0.48), Vector3(0, 1.26, -0.04), skin)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("302940")
	part(Vector3(0.38, 0.12, 0.03), Vector3(0, 1.16, -0.3), dark)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffb447")
	glow.emission_enabled = true
	glow.emission = Color("ff702b")
	for side in [-1.0, 1.0]:
		part(Vector3(0.13, 0.08, 0.04), Vector3(side * 0.16, 1.31, -0.3), glow)
		var horn := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.12
		cone.height = 0.32
		cone.radial_segments = 5
		horn.mesh = cone
		horn.material_override = dark
		horn.position = Vector3(side * 0.23, 1.6, 0)
		horn.rotation.z = -side * 0.35
		add_child(horn)
		for arm in [true, false]:
			var joint := Node3D.new()
			joint.position = Vector3(side * (0.42 if arm else 0.19), 1.0 if arm else 0.48, 0)
			add_child(joint)
			var limb := part(Vector3(0.2, 0.48 if arm else 0.42, 0.24), Vector3(0, -0.22, 0), skin)
			remove_child(limb)
			joint.add_child(limb)
			limbs.append(joint)

func part(size: Vector3, pos: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	add_child(node)
	return node

func animate(delta: float, speed: float, climbing: bool, flash: bool) -> void:
	phase += delta * (10.0 if climbing else 8.0)
	skin.albedo_color = Color.WHITE if flash else Color("75558b")
	for i in range(limbs.size()):
		limbs[i].rotation.x = sin(phase + (PI if i in [1, 2] else 0.0)) * minf(speed / 9.0, 0.65)
	rotation.x = -0.15 if climbing else 0.0
