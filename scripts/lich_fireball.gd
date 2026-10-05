extends Node3D

var direction := Vector3.FORWARD
var speed := 10.0
var lifetime := 5.0
var damage := 10
var target: CharacterBody3D

func _ready() -> void:
	add_to_group("enemy_projectiles")
	for radius in [0.23, 0.13]:
		var part := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2
		sphere.radial_segments = 8
		sphere.rings = 4
		part.mesh = sphere
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color("ff6728") if radius > 0.2 else Color("fff19a")
		part.material_override = material
		part.position = -direction * 0.1 if radius > 0.2 else direction * 0.12
		add_child(part)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0 or not is_instance_valid(target) or target.get("dead"):
		queue_free()
		return
	var next := global_position + direction * speed * delta
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.23
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.motion = next - global_position
	query.collision_mask = 1 | 2
	var space := get_world_3d().direct_space_state
	var initial := space.intersect_shape(query)
	var fractions := space.cast_motion(query)
	if not initial.is_empty() or fractions[0] < 1.0:
		query.transform.origin = global_position + query.motion * fractions[1]
		var hit := space.get_rest_info(query)
		var collider: Object = instance_from_id(hit.get("collider_id", 0)) if not hit.is_empty() else (initial[0].collider if not initial.is_empty() else null)
		if collider == target:
			target.call("take_damage", damage)
		queue_free()
		return
	global_position = next
