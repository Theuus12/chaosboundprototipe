extends CanvasLayer

var player: CharacterBody3D
var overlay: ColorRect
var text: Label
var previous_mouse_mode: int
var item_labels: Array[Label] = []
var buff_labels: Array[Label] = []
var crystal_slots: Array[VBoxContainer] = []
var weapon_icons: Array[TextureRect] = []
const Rarity = preload("res://scripts/buff_rarity.gd")

func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.045, 0.075, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var layout := HBoxContainer.new()
	layout.custom_minimum_size = Vector2(1060, 620)
	layout.add_theme_constant_override("separation", 40)
	center.add_child(layout)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 570
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 24)
	layout.add_child(column)
	text = Label.new()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 18)
	scroll.add_child(text)
	var close := Button.new()
	close.text = "Voltar ao jogo (Esc)"
	close.pressed.connect(toggle)
	column.add_child(close)
	var inventory := VBoxContainer.new()
	inventory.custom_minimum_size.x = 420
	inventory.add_theme_constant_override("separation", 16)
	layout.add_child(inventory)
	var hint := Label.new()
	hint.text = "INVENTARIO\nCtrl + clique: melhorar arma ou cristal"
	hint.add_theme_font_size_override("font_size", 18)
	inventory.add_child(hint)
	for category in ["ITENS — 4 SLOTS", "CRISTAIS — 4 SLOTS"]:
		var title := Label.new()
		title.text = category
		title.add_theme_font_size_override("font_size", 22)
		inventory.add_child(title)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		inventory.add_child(grid)
		for i in range(4):
			var panel := PanelContainer.new()
			panel.custom_minimum_size = Vector2(200, 88)
			var style := StyleBoxFlat.new()
			style.bg_color = Color("25364b")
			style.set_corner_radius_all(8)
			style.content_margin_left = 10
			style.content_margin_right = 10
			panel.add_theme_stylebox_override("panel", style)
			grid.add_child(panel)
			if category.begins_with("CRISTAIS"):
				var crystal := VBoxContainer.new()
				crystal.set_script(preload("res://scripts/crystal_slot.gd"))
				panel.add_child(crystal)
				crystal_slots.append(crystal)
				buff_labels.append(crystal.get("level_label"))
				panel.gui_input.connect(buff_click.bind(i))
				continue
			var label := Label.new()
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 15)
			label.add_theme_color_override("font_color", Color.WHITE)
			var content := VBoxContainer.new()
			content.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(content)
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(40, 40)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			content.add_child(icon)
			weapon_icons.append(icon)
			content.add_child(label)
			if category.begins_with("ITENS"):
				item_labels.append(label)
				panel.gui_input.connect(item_click.bind(i))
				label.mouse_filter = Control.MOUSE_FILTER_IGNORE
				panel.tooltip_text = "Ctrl + clique esquerdo: +1 nivel na arma (melhora todos os atributos)"
			else:
				buff_labels.append(label)
				panel.gui_input.connect(buff_click.bind(i))
				label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("stats") and not event.is_echo():
		toggle()
		get_viewport().set_input_as_handled()

func toggle() -> void:
	if overlay.visible:
		overlay.hide()
		get_tree().paused = false
		Input.mouse_mode = previous_mouse_mode
	elif not get_tree().paused and not player.get("dead"):
		refresh_inventory()
		previous_mouse_mode = Input.mouse_mode
		refresh_stats()
		overlay.show()
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func refresh_stats() -> void:
	var tenths: int = player.get("projectile_bonus_tenths")
	text.text = "STATUS DO PERSONAGEM\n\nNivel: %d | XP: %d/100\nVida: %d/%d\nVelocidade de ataque: +%d%%\nIntervalo de disparo: %.2f s\nProjetil acumulado: +%.1f\nFlechas por disparo: %d (1 base + %d adicionais)\nFracao guardada: %.1f / 1.0\nBônus nas chances de drop e orb maior: %d%%\nBonus amarelos: %d" % [player.get("level"), player.get("xp"), player.get("health"), player.get("max_health"), player.get("attack_speed_bonus"), player.call("effective_attack_interval"), tenths / 10.0, player.call("projectile_count"), int(tenths / 10.0), (tenths % 10) / 10.0, player.get("extra_xp_chance"), player.get("bonus_orbs")]
	var difficulty: int = player.get("difficulty_bonus")
	text.text += "\nEscudo: %.1f/%.1f | Moedas: %.1f" % [player.get("shield"), player.call("max_shield"), player.get("coins")]
	for kind in preload("res://scripts/tomes.gd").catalog():
		if kind < 6 or player.call("tome_bonus", kind) <= 0.0:
			continue
		text.text += "\n%s: %s" % [player.BUFF_NAMES[kind], player.call("buff_value", kind)]
	for kind in player.get("chaos_results"):
		text.text += "\n  Caos → %s: +%.0f%%" % [player.BUFF_NAMES[kind], player.get("chaos_results")[kind]]
	text.text += "\nMovimento: +%d%% (%.1f m/s) | Kills: %d" % [player.get("movement_speed_bonus"), player.call("effective_move_speed"), player.get("kills")]
	var chances := Rarity.probabilities(player.get("luck_bonus"))
	text.text += "\nSorte: +%d%% | Dourado: %.1f%%" % [player.get("luck_bonus"), chances[4] * 100.0]
	text.text += "\nDificuldade acumulada: +%d%%\nMonstros: %.1f m/s | %d vida\nLimite de monstros: %d | Spawn: %.2f s" % [difficulty, minf(player.get("move_speed"), player.get("move_speed") * 0.5 * (1.0 + difficulty / 100.0) * get_tree().current_scene.call("overtime_multiplier")), roundi((100 + difficulty) * get_tree().current_scene.call("overtime_multiplier")), get_tree().current_scene.call("effective_enemy_limit"), get_tree().current_scene.call("effective_spawn_interval")]

	text.text += "\nDano da arma: %d | Monstros por grupo: %d" % [player.get("weapon_damage"), get_tree().current_scene.call("effective_wave_size")]

	for weapon in [10, 11, 12, 26]:
		var data: Dictionary = player.get("weapons")[weapon]
		var title: String = preload("res://scripts/weapon_upgrades.gd").NAMES[weapon]
		if data.unlocked:
			text.text += "\n%s Nv.%d | Dano %d" % [title, data.level, player.call("effective_weapon_damage", weapon)]
			if weapon == 26:
				text.text += " | %d projéteis | %d alvos | Ricochete %d dano | %.2fs" % [player.call("dagger_count"), player.call("dagger_hits"), player.call("dagger_bounce_damage"), player.call("effective_dagger_interval")]
			elif weapon == 10:
				text.text += " | %d flechas | %.2fs" % [player.call("projectile_count"), player.call("effective_attack_interval")]
			else:
				text.text += " | Area +%.0f%%" % data.area
				if weapon == 11:
					text.text += " | %.2fs | %d cortes" % [player.call("effective_slash_interval"), player.call("slash_count")]
				else:
					text.text += " | %.2fs" % player.call("effective_aura_interval")
		else:
			text.text += "\n%s: bloqueado" % title

func refresh_inventory() -> void:
	var items: Array = player.get("item_slots")
	var buffs: Array = player.get("buff_slots")
	for i in range(4):
		weapon_icons[i].texture = null
		item_labels[i].text = "Item %d\n%s" % [i + 1, "Vazio" if items[i].is_empty() else items[i]]
		for weapon in [10, 11, 12, 26]:
			if items[i] == preload("res://scripts/weapon_upgrades.gd").NAMES[weapon]:
				weapon_icons[i].texture = load(preload("res://scripts/weapon_upgrades.gd").ICON_PATHS[weapon])
				item_labels[i].text += "\nNivel %d | Dano %d" % [player.get("weapons")[weapon].level, player.call("effective_weapon_damage", weapon)]
				if weapon == 26:
					item_labels[i].text += "\n%d alvos | Ricochete %d dano" % [player.call("dagger_hits"), player.call("dagger_bounce_damage")]
				var data: Dictionary = player.get("weapons")[weapon]
				var details: PackedStringArray = []
				for attribute in preload("res://scripts/weapon_upgrades.gd").ATTRIBUTES[weapon]:
					var title: String = preload("res://scripts/weapon_upgrades.gd").LABELS[attribute]
					var value := "+%.1f" % data[attribute] if attribute == "projectiles" else "+%.0f%%" % data[attribute]
					if attribute == "bounces":
						value = "+%d" % int(data[attribute])
					details.append("%s: %s" % [title, value])
				item_labels[i].text += "\n" + "\n".join(details)
				item_labels[i].get_parent().tooltip_text = "\n".join(details) + "\nCtrl + clique: melhorar"
		crystal_slots[i].call("update_buff", player, buffs[i] if i < buffs.size() else -1)
		crystal_slots[i].get_parent().tooltip_text = crystal_slots[i].tooltip_text + "\nCtrl + clique: melhorar"

func buff_click(event: InputEvent, slot: int) -> void:
	if not overlay.visible or not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT or not event.ctrl_pressed:
		return
	var buffs: Array = player.get("buff_slots")
	if slot >= buffs.size():
		return
	player.call("apply_upgrade", buffs[slot], 1.0, player.get("buff_rarities").get(buffs[slot], 0))
	# Atualiza o inventario e os valores de status enquanto a partida esta pausada.
	refresh_inventory()
	refresh_stats()
	get_viewport().set_input_as_handled()

func item_click(event: InputEvent, slot: int) -> void:
	if not overlay.visible or not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT or not event.ctrl_pressed:
		return
	var items: Array = player.get("item_slots")
	if slot < 0 or slot >= items.size():
		return
	const Weapons = preload("res://scripts/weapon_upgrades.gd")
	for weapon in [10, 11, 12, 26]:
		if items[slot] != Weapons.NAMES[weapon]:
			continue
		var stats := {}
		for attribute in Weapons.ATTRIBUTES[weapon]:
			stats[attribute] = 1.0
		player.call("apply_weapon_upgrade", weapon, stats, true)
		refresh_inventory()
		refresh_stats()
		get_viewport().set_input_as_handled()
		return
