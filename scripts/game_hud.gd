extends CanvasLayer

var player: CharacterBody3D
var xp_bar: ProgressBar
var level_label: Label
var kills_label: Label
var timer_label: Label
var death_label: Label
var slots: Array[Label] = []
var crystal_slots: Array[VBoxContainer] = []
var weapon_slots: Array[VBoxContainer] = []
var announcement_label: Label
var boss_label: Label

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
	kills_label.offset_left = -300
	kills_label.offset_right = -24
	kills_label.offset_top = 70
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(kills_label)
	announcement_label = Label.new()
	announcement_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	announcement_label.offset_top = 130
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.add_theme_font_size_override("font_size", 34)
	announcement_label.add_theme_color_override("font_color", Color("ffb45c"))
	announcement_label.add_theme_color_override("font_outline_color", Color.BLACK)
	announcement_label.add_theme_constant_override("outline_size", 8)
	root.add_child(announcement_label)
	boss_label = Label.new()
	boss_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_label.offset_top = 95
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_size_override("font_size", 24)
	boss_label.add_theme_color_override("font_color", Color("ff7060"))
	root.add_child(boss_label)
	var inventory := VBoxContainer.new()
	inventory.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	inventory.offset_left = 24
	inventory.offset_top = -156
	inventory.offset_bottom = -20
	root.add_child(inventory)
	for category in ["ITENS", "CRISTAIS"]:
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
			if category == "CRISTAIS":
				var crystal := VBoxContainer.new()
				crystal.set_script(preload("res://scripts/crystal_slot.gd"))
				panel.add_child(crystal)
				crystal_slots.append(crystal)
				continue
			var weapon := VBoxContainer.new()
			weapon.set_script(preload("res://scripts/weapon_slot.gd"))
			panel.add_child(weapon)
			weapon_slots.append(weapon)
			slots.append(weapon.get("level_label"))
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
	kills_label.text = "Kills: %d | Moedas: %.1f" % [player.get("kills"), player.get("coins")]
	var elapsed: float = get_tree().current_scene.get("elapsed_time")
	var arena := get_tree().current_scene
	announcement_label.text = arena.get("announcement") if elapsed < arena.get("announcement_until") else ""
	var boss: Node = arena.get("boss")
	boss_label.text = "CHEFE ORC — %d / 100000" % boss.get("health") if is_instance_valid(boss) and not boss.is_queued_for_deletion() else ""
	var seconds := ceili(600.0 - elapsed) if elapsed < 600.0 else int(elapsed - 600.0)
	timer_label.text = "%s%02d:%02d" % ["+" if elapsed >= 600.0 else "", int(seconds / 60.0), seconds % 60]
	death_label.visible = player.get("dead")
	var items: Array = player.get("item_slots")
	var buffs: Array = player.get("buff_slots")
	for i in range(4):
		weapon_slots[i].call("update_item", player, items[i])
		crystal_slots[i].call("update_buff", player, buffs[i] if i < buffs.size() else -1)
