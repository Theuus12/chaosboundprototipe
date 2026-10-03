extends CanvasLayer

var player: CharacterBody3D
var xp_bar: ProgressBar
var level_label: Label
var kills_label: Label
var timer_label: Label
var death_label: Label
var slots: Array[Label] = []
const Rarity = preload("res://scripts/buff_rarity.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := HBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 16
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)
	var circle := PanelContainer.new()
	circle.custom_minimum_size = Vector2(44, 44)
	var circle_style := StyleBoxFlat.new()
	circle_style.bg_color = Color("2584ce")
	circle_style.set_corner_radius_all(22)
	circle.add_theme_stylebox_override("panel", circle_style)
	top.add_child(circle)
	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 22)
	circle.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xp_bar.custom_minimum_size.y = 14
	xp_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("40a4ff")
	fill.set_corner_radius_all(7)
	xp_bar.add_theme_stylebox_override("fill", fill)
	top.add_child(xp_bar)
	timer_label = Label.new()
	timer_label.custom_minimum_size.x = 120
	timer_label.add_theme_font_size_override("font_size", 22)
	top.add_child(timer_label)
	kills_label = Label.new()
	kills_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	kills_label.offset_left = -160
	kills_label.offset_right = -24
	kills_label.offset_top = 70
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(kills_label)
	var inventory := VBoxContainer.new()
	inventory.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	inventory.offset_left = 24
	inventory.offset_top = -156
	inventory.offset_bottom = -20
	root.add_child(inventory)
	for category in ["ITENS", "BUFFS"]:
		var row := HBoxContainer.new()
		inventory.add_child(row)
		var title := Label.new()
		title.text = category
		title.custom_minimum_size.x = 52
		row.add_child(title)
		for i in range(4):
			var panel := PanelContainer.new()
			panel.custom_minimum_size = Vector2(76, 60)
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.08, 0.13, 0.2, 0.85)
			style.set_corner_radius_all(6)
			panel.add_theme_stylebox_override("panel", style)
			row.add_child(panel)
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 12)
			panel.add_child(label)
			slots.append(label)
	death_label = Label.new()
	death_label.text = "VOCE MORREU\nEnter para reiniciar"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	death_label.offset_left = -220
	death_label.offset_right = 220
	death_label.add_theme_font_size_override("font_size", 28)
	root.add_child(death_label)
	# Toda a interface passiva deixa os cliques chegarem ao jogo.
	ignore_mouse(root)

func ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		ignore_mouse(child)

func _process(_delta: float) -> void:
	xp_bar.value = player.get("xp")
	level_label.text = str(player.get("level"))
	kills_label.text = "Kills: %d" % player.get("kills")
	var elapsed: float = get_tree().current_scene.get("elapsed_time")
	var seconds := ceili(600.0 - elapsed) if elapsed < 600.0 else int(elapsed - 600.0)
	timer_label.text = "%s%02d:%02d" % ["+" if elapsed >= 600.0 else "", int(seconds / 60.0), seconds % 60]
	death_label.visible = player.get("dead")
	var items: Array = player.get("item_slots")
	var buffs: Array = player.get("buff_slots")
	var short_names := ["Ataque", "Flechas", "XP", "Dificuldade", "Movimento", "Sorte"]
	for i in range(4):
		slots[i].text = "—" if items[i].is_empty() else items[i]
		slots[i + 4].text = "—" if i >= buffs.size() else "%s\n%s" % [short_names[buffs[i]], player.call("buff_value", buffs[i]).split(" ")[0]]
		if i < buffs.size():
			var kind: int = buffs[i]
			slots[i + 4].text += " x%d" % player.get("buff_stacks").get(kind, 0)
			slots[i + 4].add_theme_color_override("font_color", Rarity.COLORS[player.get("buff_rarities").get(kind, 0)])
