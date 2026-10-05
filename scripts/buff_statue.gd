extends StaticBody3D
## Totem de pedra: a cabeça identifica a raridade, a base mantém sua cor natural.
const Rarity = preload("res://scripts/buff_rarity.gd")
const Balance = preload("res://scripts/megabonk_balance.gd")
const Tomes = preload("res://scripts/tomes.gd")
const Rewards = preload("res://scripts/shrine_rewards.gd")
const TITLES = ["Comum", "Incomum", "Raro", "Épico", "Lendário"]
const INTERACTION_DISTANCE = 3.5
var rarity: int = 0
var purchased := false
var skull_material: StandardMaterial3D
var eyes_material: StandardMaterial3D
var marker: Label3D
var offered: Array[Dictionary] = []

func _ready() -> void:
	add_to_group("buff_statues")
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.82
	shape.height = 3.8
	collider.shape = shape
	collider.position.y = 1.9
	add_child(collider)
	build_visual()

func make_material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	if glow > 0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = glow
	return material

func part(mesh: Mesh, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.scale = size
	instance.material_override = material
	add_child(instance)
	return instance

func block(pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	return part(BoxMesh.new(), pos, size, material)

func rock(pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 4
	return part(mesh, pos, size, material)

func build_visual() -> void:
	var stone := make_material(Color("928572"))
	var pale := make_material(Color("b3a58d"))
	var moss := make_material(Color("64762f"))
	var dark := make_material(Color("252820"))
	skull_material = make_material(Rarity.COLORS[rarity], 0.12)
	eyes_material = make_material(Rarity.COLORS[rarity], 0.8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3091 + rarity
	# Blocos separados, rochas de fundação e musgo.
	for i in range(9):
		var angle := i * TAU / 9.0
		rock(Vector3(cos(angle) * 0.7, 0.22, sin(angle) * 0.7), Vector3(0.75, 0.5, 0.65), stone)
	for i in range(3):
		var body := block(Vector3(0, 0.65 + i * 0.57, 0), Vector3(0.96, 0.54, 0.85), pale if i == 1 else stone)
		body.rotation.y = rng.randf_range(-0.05, 0.05)
		block(Vector3(0, 0.94 + i * 0.57, 0), Vector3(1.02, 0.055, 0.92), moss)
	for i in range(16):
		var angle := rng.randf_range(0, TAU)
		rock(Vector3(cos(angle) * 0.65, 0.23, sin(angle) * 0.65), Vector3(0.22, 0.15, 0.18), moss)
	# Espiral gravada na face frontal do pedestal.
	var rune = [Vector2(-0.29, -0.21), Vector2(-0.29, 0.23), Vector2(0.27, 0.23), Vector2(0.27, -0.17), Vector2(-0.12, -0.17), Vector2(-0.12, 0.08), Vector2(0.10, 0.08)]
	for i in range(rune.size() - 1):
		var a: Vector2 = rune[i]
		var b: Vector2 = rune[i + 1]
		block(Vector3((a.x + b.x) / 2, 1.22 + (a.y + b.y) / 2, -0.434), Vector3(maxf(absf(b.x - a.x), 0.045), maxf(absf(b.y - a.y), 0.045), 0.015), dark)
	# Crânio facetado com órbitas profundas, sobrancelhas e dentes individuais.
	rock(Vector3(0, 2.93, 0), Vector3(1.42, 1.53, 1.04), skull_material)
	block(Vector3(0, 2.39, -0.16), Vector3(0.96, 0.38, 0.75), skull_material)
	for side in [-1, 1]:
		rock(Vector3(side * 0.34, 2.91, -0.45), Vector3(0.52, 0.42, 0.12), dark)
		var brow := block(Vector3(side * 0.34, 3.17, -0.45), Vector3(0.62, 0.20, 0.22), skull_material)
		brow.rotation.z = side * 0.16
		rock(Vector3(side * 0.54, 2.70, -0.31), Vector3(0.30, 0.36, 0.32), skull_material)
		rock(Vector3(side * 0.34, 2.92, -0.519), Vector3(0.16, 0.10, 0.025), eyes_material)
	var nose := CylinderMesh.new()
	nose.top_radius = 0
	nose.bottom_radius = 0.16
	nose.height = 0.30
	nose.radial_segments = 3
	part(nose, Vector3(0, 2.71, -0.53), Vector3(1, 1, 0.25), dark)
	block(Vector3(0, 2.40, -0.548), Vector3(0.83, 0.27, 0.025), dark)
	for i in range(6):
		block(Vector3(-0.35 + i * 0.14, 2.41, -0.574), Vector3(0.115, 0.26, 0.08), skull_material)
	for i in range(6):
		var crack := block(Vector3(-0.48 + i * 0.18, 3.42 - (i % 3) * 0.065, -0.31), Vector3(0.018, 0.20, 0.018), dark)
		crack.rotation.z = rng.randf_range(-0.5, 0.5)
	rock(Vector3(0, 3.62, 0), Vector3(1.05, 0.12, 0.70), moss)
	marker = Label3D.new()
	marker.position.y = 4.15
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 40
	marker.pixel_size = 0.007
	marker.modulate = Rarity.COLORS[rarity]
	marker.text = "%s • Buff gratuito" % TITLES[rarity]
	marker.no_depth_test = false
	marker.visibility_range_end = 60.0
	add_child(marker)

func in_range(player: Node3D) -> bool:
	return is_instance_valid(player) and global_position.distance_to(player.global_position) <= INTERACTION_DISTANCE

func offers(player: CharacterBody3D) -> Array[Dictionary]:
	if purchased or player.get("dead") or not in_range(player):
		return []
	var eligible: Array[int] = Rewards.CATALOG.duplicate()
	for reward in offered:
		if reward.kind not in eligible:
			offered.clear()
			break
	if offered.is_empty():
		eligible.shuffle()
		for i in range(mini(3, eligible.size())):
			var kind := eligible[i]
			offered.append({"kind": kind, "rarity": rarity, "amount": Rewards.roll(kind, rarity)})
	return offered.duplicate(true)

func claim(player: CharacterBody3D, index: int) -> Dictionary:
	if player.get("dead") or not in_range(player):
		return {"ok": false, "message": "Aproxime-se da estátua."}
	if purchased:
		return {"ok": false, "message": "Esta estátua já concedeu seu buff."}
	if index < 0 or index >= offered.size():
		return {"ok": false, "message": "Escolha um dos buffs oferecidos."}
	var kind: int = offered[index].kind
	var amount: float = offered[index].amount
	if not player.call("apply_character_buff", kind, amount, rarity):
		return {"ok": false, "message": "Não foi possível aplicar o buff."}
	purchased = true
	skull_material.albedo_color = Color("716d65")
	skull_material.emission_enabled = false
	eyes_material.albedo_color = Color("252820")
	eyes_material.emission_enabled = false
	marker.text = "Esgotada"
	marker.modulate = Color("99958c")
	return {"ok": true, "kind": kind, "rarity": rarity, "amount": amount, "message": "%s (%s): %s" % [Rewards.NAMES[kind], TITLES[rarity], Rewards.describe(kind, amount)]}
