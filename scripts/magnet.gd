extends Node3D

var target: CharacterBody3D
var phase: float = 0.0

func _ready() -> void:
	add_to_group("magnets")
	# Ima em U com pontas claras.
	for pos in [Vector3(-0.18, 0, 0), Vector3(0.18, 0, 0), Vector3(0, -0.2, 0)]:
		var part := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.14, 0.42, 0.14) if pos.x != 0 else Vector3(0.5, 0.14, 0.14)
		part.mesh = mesh
		part.position = pos
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("f15d67")
		part.material_override = material
		add_child(part)
	for x in [-0.18, 0.18]:
		var tip := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.145, 0.13, 0.145)
		tip.mesh = mesh
		tip.position = Vector3(x, 0.2, 0)
		add_child(tip)

func _physics_process(delta: float) -> void:
	phase += delta
	rotation.y += delta
	if is_instance_valid(target) and not target.get("dead"):
		if global_position.distance_to(target.global_position + Vector3.UP * 0.45) < 0.85:
			target.call("collect_magnet")
			set_physics_process(false)
			queue_free()
