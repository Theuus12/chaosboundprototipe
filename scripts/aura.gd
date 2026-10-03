extends Node3D
var player: CharacterBody3D
var ring: MeshInstance3D
var hit_cooldowns: Dictionary = {}

func _ready() -> void:
	ring = MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.94
	mesh.outer_radius = 1.0
	ring.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.5, 0.6, 1.0, 0.7)
	ring.material_override = material
	add_child(ring)

func _physics_process(delta: float) -> void:
	var active: bool = player.get("weapons")[12].unlocked and not player.get("dead")
	visible = active
	if not active:
		return
	var radius: float = player.call("weapon_radius", 12, 2.5)
	ring.scale = Vector3(radius, 1, radius)
	var interval: float = player.call("effective_aura_interval")
	for id in hit_cooldowns.keys():
		hit_cooldowns[id] = minf(hit_cooldowns[id], interval) - delta
		if hit_cooldowns[id] <= 0.0:
			hit_cooldowns.erase(id)
	pulse()

func pulse() -> void:
	var radius: float = player.call("weapon_radius", 12, 2.5)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion():
			continue
		var offset: Vector3 = enemy.global_position - player.global_position
		if absf(offset.y) <= 1.5 and Vector2(offset.x, offset.z).length() <= radius:
			var id := enemy.get_instance_id()
			if hit_cooldowns.has(id):
				continue
			hit_cooldowns[id] = player.call("effective_aura_interval")
			enemy.call("take_damage", player.call("effective_weapon_damage", 12))
