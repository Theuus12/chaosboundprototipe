extends "res://scripts/buff_statue.gd"
## Ritual único por partida. Não pertence à lista de totens de buffs.
var target: CharacterBody3D
var activated := false
var prompt: Label

func _ready() -> void:
	add_to_group("boss_altars")
	var stone := make_material(Color("ad9c7d"))
	var moss := make_material(Color("63752d"))
	var dark := make_material(Color("39352b"))
	for level in range(3):
		var radius := 4.0 - level * 0.55
		var disk := CylinderMesh.new()
		disk.top_radius = radius
		disk.bottom_radius = radius
		disk.height = 0.20
		disk.radial_segments = 32
		part(disk, Vector3(0, 0.12 + level * 0.2, 0), Vector3.ONE, stone)
		for i in range(24):
			var angle := i * TAU / 24
			var tile := block(Vector3(cos(angle) * (radius - 0.25), 0.17 + level * 0.2, sin(angle) * (radius - 0.25)), Vector3(0.48, 0.23, 0.63), stone)
			tile.rotation.y = -angle
			rock(Vector3(cos(angle) * radius, 0.10 + level * 0.2, sin(angle) * radius), Vector3(0.25, 0.09, 0.3), moss)
	var base_collision := CollisionShape3D.new()
	var base_shape := CylinderShape3D.new()
	base_shape.radius = 4
	base_shape.height = 0.2
	base_collision.shape = base_shape
	base_collision.position.y = 0.1
	add_child(base_collision)
	for spec in [Vector3(0, 4.8, -3.0), Vector3(-2.7, 3.2, -1.8), Vector3(2.7, 3.2, -1.8), Vector3(-3.6, 1.4, 0.6), Vector3(3.6, 1.4, 0.6)]:
		var pos := Vector3(spec.x, 0, spec.z)
		var pillar := block(pos + Vector3.UP * (0.45 + spec.y / 2), Vector3(0.85, spec.y, 0.72), stone)
		pillar.rotation.z = spec.x * 0.015
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(0.85, spec.y, 0.72)
		collider.shape = shape
		collider.position = pillar.position
		add_child(collider)
		rock(pos + Vector3.UP * (0.45 + spec.y), Vector3(0.88, 0.09, 0.75), moss)
		for side in [-1, 1]:
			var rune := block(pos + Vector3(side * 0.16, spec.y * 0.6 + 0.45, 0.37), Vector3(0.035, 0.53, 0.02), dark)
			rune.rotation.z = side * 0.62
			var rune_bottom := block(pos + Vector3(side * 0.16, spec.y * 0.6, 0.37), Vector3(0.035, 0.53, 0.02), dark)
			rune_bottom.rotation.z = -side * 0.62
	for i in range(4):
		var line := block(Vector3(0, 0.625, 0), Vector3(1.2, 0.02, 0.04), dark)
		line.position = Vector3(cos(i * PI / 2) * 0.6, 0.625, sin(i * PI / 2) * 0.6)
		line.rotation.y = -i * PI / 2 + PI / 4
	for i in range(18):
		var angle := i * TAU / 18
		rock(Vector3(cos(angle) * 4.2, 0.1, sin(angle) * 4.2), Vector3(0.6, 0.35, 0.55), stone)
		var grass := block(Vector3(cos(angle) * 4.05, 0.32, sin(angle) * 4.05), Vector3(0.06, 0.55, 0.15), moss)
		grass.rotation = Vector3(0.15, -angle, 0.25)
	marker = Label3D.new()
	marker.text = "Altar do Rei Ossuário"
	marker.position.y = 5.7
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.font_size = 40
	marker.pixel_size = 0.009
	marker.modulate = Color("ffd15b")
	marker.visibility_range_end = 60
	add_child(marker)

func setup(player: CharacterBody3D) -> void:
	target = player
	var canvas := CanvasLayer.new()
	add_child(canvas)
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -230
	prompt.offset_bottom = -190
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_color", Color("ffd15b"))
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 6)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(prompt)

func can_activate() -> bool:
	return is_instance_valid(target) and not target.get("dead") and not activated and global_position.distance_to(target.global_position) <= 5.5

func activate() -> bool:
	if not can_activate() or get_tree().paused:
		return false
	var arena := get_tree().current_scene
	if not arena.call("spawn_final_boss", global_position):
		return false
	activated = true
	marker.text = "Ritual realizado"
	return true

func _process(_delta: float) -> void:
	if is_instance_valid(prompt):
		prompt.visible = can_activate()
		prompt.text = "[E] Invocar Rei Ossuário — 50.000 de vida"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and activate():
		get_viewport().set_input_as_handled()
