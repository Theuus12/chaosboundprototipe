extends Node3D
## Corte instantaneo: setor de 90 graus com alcance de 3 metros.
var damage: int = 100
var player: CharacterBody3D
var lifetime: float = 0.22
var reach: float = 3.0
var half_angle: float = PI / 4.0
var age: float = 0.0
var visual: MeshInstance3D

func _ready() -> void:
	add_to_group("slashes")
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(20):
		var a := -half_angle + 2.0 * half_angle * i / 20.0
		var b := -half_angle + 2.0 * half_angle * (i + 1) / 20.0
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(Vector3(sin(a), 0, -cos(a)) * reach)
		surface.add_vertex(Vector3(sin(b), 0, -cos(b)) * reach)
	visual = MeshInstance3D.new()
	visual.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.7, 0.95, 1.0, 0.65)
	visual.material_override = material
	add_child(visual)

func strike() -> void:
	var forward := -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion():
			continue
		var target_point: Vector3 = enemy.global_position + Vector3.UP * 0.7
		var offset := target_point - global_position
		if absf(offset.y) > 1.3:
			continue
		offset.y = 0.0
		if offset.length() > reach:
			continue
		if offset.length_squared() > 0.001 and forward.dot(offset.normalized()) < cos(half_angle):
			continue
		# Obstaculos bloqueiam o corte; outros monstros nao bloqueiam a area.
		var query := PhysicsRayQueryParameters3D.create(global_position, target_point, 1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			continue
		if is_instance_valid(player):
			player.call("hit_enemy", enemy, damage)
		else:
			enemy.call("take_damage", damage)

func _process(delta: float) -> void:
	age += delta
	var material := visual.material_override as StandardMaterial3D
	material.albedo_color.a = maxf(0.0, 0.65 * (1.0 - age / lifetime))
	if age >= lifetime:
		queue_free()
