extends Node3D

var bonus: bool = false
var magnetized: bool = false
var target: CharacterBody3D
var phase: float = 0.0
var visual: MeshInstance3D

func _ready() -> void:
	add_to_group("pickups")
	visual = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	mesh.radial_segments = 12
	mesh.rings = 6
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffd34d") if bonus else Color("40a4ff")
	material.emission_enabled = true
	material.emission = material.albedo_color
	material.emission_energy_multiplier = 0.7
	visual.material_override = material
	add_child(visual)
	phase = randf() * TAU

func _physics_process(delta: float) -> void:
	phase += delta * 3.0
	visual.position.y = sin(phase) * 0.06
	if not is_instance_valid(target) or target.get("dead"):
		return
	var destination := target.global_position + Vector3.UP * 0.45
	var distance := global_position.distance_to(destination)
	if distance < 2.2 or magnetized:
		global_position = global_position.move_toward(destination, (18.0 if magnetized else 7.0) * delta)
	if global_position.distance_to(destination) < 0.65:
		if bonus:
			target.call("collect_bonus")
		else:
			target.call("collect_xp")
		set_physics_process(false)
		queue_free()
