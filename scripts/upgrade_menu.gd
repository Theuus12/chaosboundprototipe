extends CanvasLayer

var player: CharacterBody3D
var overlay: ColorRect
var heading: Label
var buttons: Array[Button] = []
var rolls: Array[float] = []
var offered: Array[int] = []
var rarities: Array[int] = []
const Rarity = preload("res://scripts/buff_rarity.gd")
const Weapons = preload("res://scripts/weapon_upgrades.gd")
var weapon_rolls: Array[Dictionary] = []
var pending_levels: Array[int] = []
var choosing: bool = false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.045, 0.075, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 30)
	column.add_child(heading)
	var help := Label.new()
	help.text = "Escolha uma melhoria para continuar"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)
	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(540, 88)
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(choose.bind(i))
		column.add_child(button)
		buttons.append(button)
	overlay.hide()
	player.connect("level_reached", queue_level)

func queue_level(new_level: int) -> void:
	pending_levels.append(new_level)
	if not choosing:
		show_next()

func show_next() -> void:
	choosing = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	heading.text = "NIVEL %d ALCANCADO!" % pending_levels[0]
	rolls.clear()
	rarities.clear()
	weapon_rolls.clear()
	var catalog: Array[int] = [0, 1, 2, 3, 4, 5]
	offered.assign(player.call("eligible_buffs", catalog))
	for weapon in [10, 11, 12]:
		if player.get("weapons")[weapon].unlocked or "" in player.get("item_slots"):
			offered.append(weapon)
	offered.shuffle()
	offered.resize(3)
	var names: Array = player.BUFF_NAMES
	var descriptions := ["Aumenta a frequencia dos disparos", "Cada unidade acumulada adiciona uma flecha simultanea", "Aumenta a chance de um fragmento azul extra", "Aumenta velocidade, vida e quantidade dos monstros", "Aumenta a velocidade ao andar", "Aumenta a chance de raridades maiores"]
	for i in range(3):
		var kind := offered[i]
		var rarity := Rarity.roll_rarity(-1, player.get("luck_bonus"))
		rarities.append(rarity)
		if kind >= 10:
			var first: bool = not player.get("weapons")[kind].unlocked
			var stats := Weapons.roll_stats(kind, rarity, 1 if first else 2)
			weapon_rolls.append(stats)
			rolls.append(0.0)
			var action := "Melhorar" if player.get("weapons")[kind].unlocked else "Desbloquear"
			buttons[i].text = "%s %s\n%s" % [action, Weapons.NAMES[kind], Weapons.describe(stats)]
			for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				buttons[i].add_theme_color_override(state, Rarity.COLORS[rarity])
			continue
		weapon_rolls.append({})
		rolls.append(Rarity.roll_amount(kind, rarity))
		var value := "+%.1f" % rolls[i] if kind == 1 else "+%d%%" % int(rolls[i])
		var slot_hint := "Melhorar buff equipado" if kind in player.get("buff_slots") else "Equipar em um slot de buff"
		buttons[i].text = "%s %s\n%s\n%s" % [names[kind], value, descriptions[kind], slot_hint]
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			buttons[i].add_theme_color_override(state, Rarity.COLORS[rarity])
	overlay.show()
	buttons[0].grab_focus()

func choose(index: int) -> void:
	if not choosing or index < 0 or index >= 3:
		return
	if offered[index] >= 10:
		if not player.call("apply_weapon_upgrade", offered[index], weapon_rolls[index]):
			return
	elif not player.call("apply_upgrade", offered[index], rolls[index], rarities[index]):
		return
	pending_levels.pop_front()
	if not pending_levels.is_empty():
		show_next()
	else:
		choosing = false
		overlay.hide()
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
