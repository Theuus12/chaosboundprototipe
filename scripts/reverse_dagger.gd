extends Node3D

var player: CharacterBody3D
var target: Node3D
var hits_left: int = 1
var damage: int = 100
var bounce_damage: int = 30
var speed: float = 28.0
var lifetime: float = 8.0
var used: Array[int] = []

func _ready() -> void:
	add_to_group("daggers")
	var blade := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0
	mesh.bottom_radius = 0.12
	mesh.height = 0.65
	mesh.radial_segments = 4
	blade.mesh = mesh
	blade.rotation.x = -PI / 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c6efff")
	material.emission_enabled = true
	material.emission = Color("438dac")
	blade.material_override = material
	add_child(blade)
	var handle := MeshInstance3D.new()
	var handle_mesh := BoxMesh.new()
	handle_mesh.size = Vector3(0.12, 0.12, 0.25)
	handle.mesh = handle_mesh
	handle.position.z = 0.4
	handle.material_override = material
	add_child(handle)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0 or not is_instance_valid(player) or player.get("dead"):
		queue_free()
		return
	if not is_instance_valid(target) or target.is_queued_for_deletion() or target.get("health") <= 0:
		target = player.call("nearest_enemy", global_position, used)
	if target == null:
		queue_free()
		return
	var destination := target.global_position + Vector3.UP * 0.7
	var next := global_position.move_toward(destination, speed * delta)
	if global_position.distance_squared_to(destination) > 0.001:
		look_at(destination, Vector3.RIGHT if absf((destination-global_position).normalized().y) > 0.99 else Vector3.UP)
	var query := PhysicsRayQueryParameters3D.create(global_position, next, 1)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position = next
	if global_position.distance_to(destination) < 0.15:
		var hit_damage := damage if used.is_empty() else bounce_damage
		used.append(target.get_instance_id())
		player.call("hit_enemy", target, hit_damage, -1.0, 26)
		hits_left -= 1
		if hits_left <= 0:
			queue_free()
		else:
			target = player.call("nearest_enemy", global_position, used)
			if target == null:
				queue_free()
