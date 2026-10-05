extends Node3D

var bonus: bool = false
var large_xp: bool = false
var xp_tier: int = 0

func pickup_kind() -> int:
	return 3 if bonus else maxi(xp_tier, 1 if large_xp else 0)
var magnetized: bool = false
var target: CharacterBody3D
var phase: float = 0.0
var visual: MeshInstance3D
var batch: Node3D
static var shared_meshes: Dictionary = {}

func _ready() -> void:
	add_to_group("pickups")
	visual = MeshInstance3D.new()
	var kind := pickup_kind()
	if not shared_meshes.has(kind):
		var mesh := SphereMesh.new()
		mesh.radius = [0.18, 0.28, 0.38, 0.18][kind]
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 12
		mesh.rings = 6
		var material := ShaderMaterial.new()
		material.shader = preload("res://scripts/pickup_bob.gdshader")
		material.set_shader_parameter("orb_color", Color("ffd34d") if bonus else (Color("94dfff") if kind == 2 else Color("40a4ff")))
		mesh.material = material
		shared_meshes[kind] = mesh
	visual.mesh = shared_meshes[kind]
	visual.visible = false
	add_child(visual)
	phase = randf() * TAU
	batch = get_parent().get_node_or_null("PickupBatch")
	if batch == null:
		batch = Node3D.new()
		batch.name = "PickupBatch"
		batch.set_script(preload("res://scripts/pickup_batch.gd"))
		get_parent().add_child(batch)
	batch.register(self)
	set_physics_process(false)

func _exit_tree() -> void:
	if is_instance_valid(batch):
		batch.unregister(self)

func collect() -> void:
	if is_queued_for_deletion():
		return
	if bonus:
		target.call("collect_bonus")
	else:
		target.call("collect_xp", [10, 30, 50][pickup_kind()], magnetized)
	queue_free()
	if is_instance_valid(batch):
		batch.dirty = true

func _physics_process(delta: float) -> void:
	phase += delta * 3.0
	visual.position.y = sin(phase) * 0.06
	if not is_instance_valid(target) or target.get("dead"):
		return
	var destination := target.global_position + Vector3.UP * 0.45
	var distance := global_position.distance_to(destination)
	if distance < target.call("collection_radius") or magnetized:
		global_position = destination
	if global_position.distance_to(destination) < 0.65:
		collect()
