extends Node3D
## Compartilhe cada peça do glTF entre os inimigos, preservando suas articulações.
var sources: Array[MeshInstance3D] = []
var owners: Dictionary = {}
var batches: Array[Dictionary] = []
var dirty := false

func register(visual: Node3D, meshes: Array[MeshInstance3D]) -> void:
	for mesh in meshes:
		sources.append(mesh)
		owners[mesh.get_instance_id()] = visual
		mesh.hide()
	dirty = true

func unregister(meshes: Array[MeshInstance3D]) -> void:
	for mesh in meshes:
		if is_instance_valid(mesh):
			owners.erase(mesh.get_instance_id())
			sources.erase(mesh)
	dirty = true

func rebuild() -> void:
	for batch in batches:
		batch.node.queue_free()
	batches.clear()
	var groups := {}
	for source in sources:
		if not is_instance_valid(source) or source.is_queued_for_deletion():
			continue
		var visual: Node3D = owners.get(source.get_instance_id())
		# glTF pode duplicar recursos locais ao instanciar: o caminho da peça
		# dentro do mesmo modelo identifica a geometria compartilhável.
		var key := str(visual.get("model_path")) + "|" + str(visual.get_path_to(source))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(source)
	for key in groups:
		var members: Array = groups[key]
		var node := MultiMeshInstance3D.new()
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.mesh = members[0].mesh
		multimesh.instance_count = members.size()
		node.multimesh = multimesh
		add_child(node)
		batches.append({"node": node, "members": members})
	dirty = false

func _process(_delta: float) -> void:
	if dirty:
		rebuild()
	var inverse := global_transform.affine_inverse()
	for batch in batches:
		var multimesh: MultiMesh = batch.node.multimesh
		var members: Array = batch.members
		for i in range(members.size()):
			var mesh: MeshInstance3D = members[i]
			if not is_instance_valid(mesh):
				dirty = true
				continue
			multimesh.set_instance_transform(i, inverse * mesh.global_transform)
			var owner: Node3D = owners.get(mesh.get_instance_id())
			multimesh.set_instance_color(i, Color(2, 2, 2, 1) if is_instance_valid(owner) and owner.get("flashing") else Color.WHITE)
