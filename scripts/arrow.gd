extends Node3D
## Flecha em linha reta com varredura entre frames para nao atravessar alvos.
var direction: Vector3 = Vector3.FORWARD
var speed: float = 32.0
var lifetime: float = 3.0
var damage: int = 100
var player: CharacterBody3D
var hit_radius: float = 0.04

func _ready() -> void:
	add_to_group("arrows")
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.045, 0.045, 0.8)
	add_part(shaft, Vector3(0, 0, 0.4), Color("c89c61"))
	var tip := CylinderMesh.new()
	tip.top_radius = 0.0
	tip.bottom_radius = 0.1
	tip.height = 0.22
	tip.radial_segments = 4
	var head := add_part(tip, Vector3(0, 0, -0.02), Color("e9eee9"))
	head.rotation.x = -PI / 2.0
	for angle in [0.0, PI / 2.0]:
		var feather := BoxMesh.new()
		feather.size = Vector3(0.23, 0.025, 0.22)
		var part := add_part(feather, Vector3(0, 0, 0.7), Color("f1d47b"))
		part.rotation.z = angle
	look_at(global_position + direction, Vector3.UP if absf(direction.y) < 0.99 else Vector3.RIGHT)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var next := global_position + direction * speed * delta
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = hit_radius
	shape.height = global_position.distance_to(next) + 2.0 * hit_radius
	query.shape = shape
	var axis := direction.normalized()
	var side := axis.cross(Vector3.UP if absf(axis.y) < 0.99 else Vector3.RIGHT).normalized()
	query.transform = Transform3D(Basis(side, axis, side.cross(axis)), (global_position + next) * 0.5)
	query.collision_mask = 1 | 4
	var hits := get_world_3d().direct_space_state.intersect_shape(query)
	hits.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return global_position.distance_squared_to(a.collider.global_position) < global_position.distance_squared_to(b.collider.global_position))
	var hit: Dictionary = {} if hits.is_empty() else hits[0]
	if not hit.is_empty():
		var collider := hit.collider as Node
		if collider and collider.is_in_group("enemies") and collider.has_method("take_damage"):
			if is_instance_valid(player):
				player.call("hit_enemy", collider, damage, -1.0, 10)
			else:
				collider.call("take_damage", damage)
		queue_free()
		return
	global_position = next

func add_part(mesh: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	part.material_override = material
	add_child(part)
	return part
