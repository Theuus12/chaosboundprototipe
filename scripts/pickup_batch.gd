extends Node3D

var orbs: Array[Node3D] = []
var batches: Array[MultiMeshInstance3D] = []
var dirty := true

func register(orb: Node3D) -> void:
	orbs.append(orb)
	dirty = true

func unregister(orb: Node3D) -> void:
	orbs.erase(orb)
	dirty = true

func _physics_process(_delta: float) -> void:
	var destinations: Dictionary = {}
	var radii: Dictionary = {}
	for orb in orbs.duplicate():
		if orb.is_queued_for_deletion() or not is_instance_valid(orb.target) or orb.target.get("dead"):
			continue
		var player = orb.target
		if not destinations.has(player):
			destinations[player] = player.global_position + Vector3.UP * 0.45
			radii[player] = pow(player.call("collection_radius"), 2)
		var distance: float = orb.global_position.distance_squared_to(destinations[player])
		if orb.magnetized or distance < radii[player] or distance < 0.65 * 0.65:
			orb.collect()
	if dirty:
		rebuild()

func rebuild() -> void:
	dirty = false
	for batch in batches:
		batch.queue_free()
	batches.clear()
	for kind in range(4):
		var selected: Array[Node3D] = []
		for orb in orbs:
			if not orb.is_queued_for_deletion() and orb.pickup_kind() == kind:
				selected.append(orb)
		if selected.is_empty():
			continue
		var batch := MultiMeshInstance3D.new()
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_custom_data = true
		multimesh.mesh = selected[0].visual.mesh
		multimesh.instance_count = selected.size()
		for i in range(selected.size()):
			multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, to_local(selected[i].global_position)))
			multimesh.set_instance_custom_data(i, Color(selected[i].phase, 0, 0, 1))
		batch.multimesh = multimesh
		add_child(batch)
		batches.append(batch)
