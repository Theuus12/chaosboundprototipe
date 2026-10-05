extends Node
const Statue = preload("res://scripts/buff_statue.gd")
const Forest = preload("res://scripts/forest.gd")
var player: CharacterBody3D
var statues: Array[StaticBody3D] = []
var prompt: Label
var feedback: Label
var feedback_left := 0.0
var choice_menu: ColorRect
var choice_heading: Label
var choice_buttons: Array[Button] = []
var active_statue: StaticBody3D
var previous_mouse_mode: int

func populate(arena: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71219
	for i in range(15):
		var angle := i * TAU / 15.0
		var radius := 20.0 if i % 3 == 0 else (29.0 * Forest.MAP_SCALE if i % 3 == 1 else 43.0 * Forest.MAP_SCALE)
		var desired := Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var point := desired
		var found := false
		for attempt in range(160):
			point = desired + Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6)) if attempt > 0 else desired
			if absf(point.x) > Forest.PLAYABLE_LIMIT or absf(point.z) > Forest.PLAYABLE_LIMIT:
				continue
			var clear := true
			for tree in arena.get_tree().get_nodes_in_group("trees"):
				if Vector2(point.x, point.z).distance_to(Vector2(tree.global_position.x, tree.global_position.z)) < 4.0:
					clear = false
					break
			for other in statues:
				if point.distance_to(Vector3(other.position.x, 0, other.position.z)) < 7.5:
					clear = false
			if clear:
				found = true
				break
		assert(found, "Não foi encontrado espaço livre para a estátua.")
		point.y = Forest.ground_height(point.x, point.z)
		var statue := StaticBody3D.new()
		statue.set_script(Statue)
		statue.set("rarity", i % 5)
		statue.name = "BuffStatue%d" % (i + 1)
		statue.position = point
		statue.rotation.y = atan2(point.x, point.z)
		arena.navigation.add_child(statue)
		statues.append(statue)

func setup(target: CharacterBody3D) -> void:
	player = target
	process_mode = Node.PROCESS_MODE_ALWAYS
	var canvas := CanvasLayer.new()
	canvas.layer = 4
	add_child(canvas)
	prompt = Label.new()
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -225
	prompt.offset_bottom = -185
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 2)
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(prompt)
	feedback = Label.new()
	feedback.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	feedback.offset_top = -270
	feedback.offset_bottom = -225
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.add_theme_font_size_override("font_size", 21)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(feedback)
	var menu_canvas := CanvasLayer.new()
	menu_canvas.layer = 12
	add_child(menu_canvas)
	choice_menu = ColorRect.new()
	choice_menu.color = Color(0.02, 0.04, 0.055, 0.94)
	choice_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_canvas.add_child(choice_menu)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	choice_menu.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	center.add_child(column)
	choice_heading = Label.new()
	choice_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choice_heading.add_theme_font_size_override("font_size", 30)
	column.add_child(choice_heading)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(310, 210)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 19)
		button.pressed.connect(choose.bind(i))
		row.add_child(button)
		choice_buttons.append(button)
	var cancel := Button.new()
	cancel.text = "Voltar — Esc"
	cancel.pressed.connect(close_choices)
	column.add_child(cancel)
	choice_menu.hide()

func open_choices(statue: StaticBody3D) -> void:
	var rewards: Array[Dictionary] = statue.call("offers", player)
	if rewards.is_empty():
		feedback.text = "Santuário esgotado ou buffs no limite."
		feedback_left = 5.0
		return
	active_statue = statue
	var rarity: int = statue.get("rarity")
	choice_heading.text = "Santuário %s\nEscolha 1 buff gratuito" % Statue.TITLES[rarity]
	choice_heading.modulate = Statue.Rarity.COLORS[rarity]
	for i in range(choice_buttons.size()):
		var button := choice_buttons[i]
		button.visible = i < rewards.size()
		if not button.visible:
			continue
		var reward: Dictionary = rewards[i]
		button.text = "%s\n\n%s\n\n%s" % [Statue.Rewards.NAMES[reward.kind], Statue.Rewards.describe(reward.kind, reward.amount), Statue.Rewards.DESCRIPTIONS[reward.kind]]
		button.add_theme_color_override("font_color", Statue.Rarity.COLORS[rarity])
	previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	choice_menu.show()
	get_tree().paused = true
	choice_buttons[0].grab_focus()

func choose(index: int) -> void:
	if not is_instance_valid(active_statue):
		return
	var result: Dictionary = active_statue.call("claim", player, index)
	feedback.text = result.message
	feedback_left = 5.0
	if result.ok:
		close_choices()

func close_choices() -> void:
	if not choice_menu.visible:
		return
	choice_menu.hide()
	active_statue = null
	get_tree().paused = false
	Input.mouse_mode = previous_mouse_mode

func _input(event: InputEvent) -> void:
	if is_instance_valid(choice_menu) and choice_menu.visible and event.is_action_pressed("stats"):
		close_choices()
		get_viewport().set_input_as_handled()

func nearest_statue() -> StaticBody3D:
	var nearest: StaticBody3D
	var distance := Statue.INTERACTION_DISTANCE
	for statue in statues:
		var current := statue.global_position.distance_to(player.global_position)
		if current <= distance:
			distance = current
			nearest = statue
	return nearest

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(prompt):
		return
	feedback_left = maxf(0, feedback_left - delta)
	feedback.visible = feedback_left > 0 and not player.get("dead")
	var statue := nearest_statue()
	prompt.visible = statue != null and not player.get("dead")
	if not prompt.visible:
		return
	prompt.modulate = Statue.Rarity.COLORS[statue.get("rarity")]
	prompt.text = "Santuário esgotado" if statue.get("purchased") else "[E] Santuário %s — escolha 1 de 3 buffs grátis" % Statue.TITLES[statue.get("rarity")]

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player) or player.get("dead") or get_tree().paused:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		var statue := nearest_statue()
		if statue == null:
			return
		open_choices(statue)
		get_viewport().set_input_as_handled()
