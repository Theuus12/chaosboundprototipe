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
var banned: Array[int] = []
var ban_mode: bool = false
var ban_button: Button

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
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 64)
		button.add_theme_constant_override("h_separation", 18)
		button.pressed.connect(choose.bind(i))
		column.add_child(button)
		buttons.append(button)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(actions)
	ban_button = Button.new()
	ban_button.text = "Banir"
	ban_button.pressed.connect(toggle_ban)
	actions.add_child(ban_button)
	var skip := Button.new()
	skip.text = "Passar"
	skip.pressed.connect(skip_level)
	actions.add_child(skip)
	var reroll := Button.new()
	reroll.text = "Atualizar"
	reroll.pressed.connect(reroll_choices)
	actions.add_child(reroll)
	for action in actions.get_children():
		action.custom_minimum_size = Vector2(160, 44)
	overlay.hide()
	player.connect("level_reached", queue_level)

func queue_level(new_level: int) -> void:
	pending_levels.append(new_level)
	if not choosing:
		show_next()

func show_next() -> void:
	ban_mode = false
	ban_button.text = "Banir"
	choosing = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	heading.text = "NIVEL %d ALCANCADO!" % pending_levels[0]
	rolls.clear()
	rarities.clear()
	weapon_rolls.clear()
	var catalog: Array[int] = preload("res://scripts/tomes.gd").catalog()
	offered.assign(player.call("eligible_buffs", catalog))
	for weapon in [10, 11, 12, 26]:
		if player.get("weapons")[weapon].unlocked or "" in player.get("item_slots"):
			offered.append(weapon)
	for kind in banned:
		offered.erase(kind)
	offered.shuffle()
	if offered.size() > 3:
		offered.resize(3)
	var names: Dictionary = player.BUFF_NAMES
	var descriptions: Dictionary = preload("res://scripts/tomes.gd").DESCRIPTIONS
	for i in range(3):
		buttons[i].visible = i < offered.size()
		if i >= offered.size():
			continue
		var kind := offered[i]
		var icon_path: String = Weapons.ICON_PATHS[kind] if Weapons.ICON_PATHS.has(kind) else "res://assets/ui/crystals/crystal_%d.svg" % kind
		buttons[i].icon = load(icon_path)
		var rarity := Rarity.roll_rarity(-1, player.get("luck_bonus"))
		rarities.append(rarity)
		if preload("res://scripts/tomes.gd").is_weapon(kind):
			var first: bool = not player.get("weapons")[kind].unlocked
			var stats := Weapons.roll_stats(kind, rarity, 1 if first else 2)
			weapon_rolls.append(stats)
			rolls.append(0.0)
			var action := "Melhorar" if player.get("weapons")[kind].unlocked else "Desbloquear"
			buttons[i].text = "%s %s\n%s" % [action, Weapons.NAMES[kind], Weapons.describe(stats)]
			if kind == 26:
				buttons[i].text += "\nAtinge %d inimigos em sequência" % (player.call("dagger_hits") + 1 + int(stats.get("bounces", 0)))
			for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				buttons[i].add_theme_color_override(state, Rarity.COLORS[rarity])
			continue
		weapon_rolls.append({})
		rolls.append(Rarity.roll_amount(kind, rarity))
		var value := "+%.1f" % rolls[i] if kind == 1 else "+%d%%" % int(rolls[i])
		var slot_hint := "Melhorar cristal equipado" if kind in player.get("buff_slots") else "Equipar em um slot de cristal"
		buttons[i].text = "%s %s\n%s\n%s" % [names[kind], value, descriptions[kind], slot_hint]
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			buttons[i].add_theme_color_override(state, Rarity.COLORS[rarity])
	overlay.show()
	if not offered.is_empty():
		buttons[0].grab_focus()
	else:
		heading.text += "\nSem melhorias disponíveis — use Passar"

func toggle_ban() -> void:
	ban_mode = not ban_mode
	ban_button.text = "Cancelar banimento" if ban_mode else "Banir"
	heading.text = "Escolha a melhoria para banir" if ban_mode else "NIVEL %d ALCANCADO!" % pending_levels[0]

func reroll_choices() -> void:
	if choosing:
		show_next()

func skip_level() -> void:
	if choosing:
		finish_level()

func choose(index: int) -> void:
	if not choosing or index < 0 or index >= offered.size():
		return
	if ban_mode:
		banned.append(offered[index])
		show_next()
		return
	if preload("res://scripts/tomes.gd").is_weapon(offered[index]):
		if not player.call("apply_weapon_upgrade", offered[index], weapon_rolls[index]):
			return
	elif not player.call("apply_upgrade", offered[index], rolls[index], rarities[index]):
		return
	finish_level()

func finish_level() -> void:
	ban_mode = false
	pending_levels.pop_front()
	if not pending_levels.is_empty():
		show_next()
	else:
		choosing = false
		overlay.hide()
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
