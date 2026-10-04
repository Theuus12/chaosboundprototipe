extends Node3D
@export var model_path: String = "res://assets/characters/goblin/goblin.glb"

var model: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var elbows: Array[Node3D] = []
var phase := 0.0
var stride := 0.0
var meshes: Array[MeshInstance3D] = []
var flash_material: StandardMaterial3D
var flashing: bool = false

func _ready() -> void:
	model = load(model_path).instantiate()
	model.rotation.y = PI
	add_child(model)
	for side in ["L", "R"]:
		arms.append(model.find_child("Arm_" + side, true, false))
		legs.append(model.find_child("Leg_" + side, true, false))
		knees.append(model.find_child("Knee_" + side, true, false))
		elbows.append(model.find_child("Elbow_" + side, true, false))
	collect_meshes(model)
	flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE
	animate(0.0, 0.0, false, false)

func collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		# The batched glTF stores its palette in COLOR_0 rather than textures.
		# Explicitly enable that palette in Godot's imported materials.
		for surface in range(node.mesh.get_surface_count()):
			var material = node.mesh.surface_get_material(surface)
			if material is StandardMaterial3D:
				material.vertex_color_use_as_albedo = true
				material.albedo_color = Color.WHITE
		meshes.append(node)
	for child in node.get_children():
		collect_meshes(child)

func animate(delta: float, speed: float, climbing: bool, flash: bool) -> void:
	stride = lerpf(stride, clampf(speed / 4.5, 0.0, 1.0), 1.0 - exp(-delta * 10.0))
	phase += delta * lerpf(2.0, 10.0, stride)
	for i in range(2):
		var cycle := sin(phase + i * PI)
		arms[i].rotation.z = 1.12 if i == 0 else -1.12
		arms[i].rotation.x = -cycle * 0.65 * stride
		elbows[i].rotation.y = (0.18 + maxf(0.0, cycle) * 0.25 * stride) * (-1.0 if i == 0 else 1.0)
		legs[i].rotation.x = cycle * 0.65 * stride
		knees[i].rotation.x = -maxf(0.0, -cycle) * 0.8 * stride
	model.position.y = absf(cos(phase)) * 0.045 * stride
	model.rotation.z = sin(phase) * 0.045 * stride
	rotation.x = lerpf(rotation.x, -0.18 if climbing else -0.06 * stride, 1.0 - exp(-delta * 8.0))
	if flash != flashing:
		flashing = flash
		for mesh in meshes:
			mesh.material_override = flash_material if flash else null
