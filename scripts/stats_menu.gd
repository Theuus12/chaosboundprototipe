extends CanvasLayer

var player: CharacterBody3D
var overlay: ColorRect
var text: Label
var bonus_text: Label
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
	text.add_theme_font_size_override("font_size", 16)
	var stats_column := VBoxContainer.new()
	stats_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_column.add_theme_constant_override("separation", 20)
	scroll.add_child(stats_column)
	stats_column.add_child(text)
	bonus_text = Label.new()
	bonus_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus_text.add_theme_font_size_override("font_size", 16)
	bonus_text.add_theme_color_override("font_color", Color("83e69d"))
	stats_column.add_child(bonus_text)
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
	for category in ["ITENS — %d SLOTS" % player.get("item_slots").size(), "CRISTAIS — 4 SLOTS"]:
		var title := Label.new()
		title.text = category
		title.add_theme_font_size_override("font_size", 22)
		inventory.add_child(title)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		inventory.add_child(grid)
		for i in range(player.get("item_slots").size() if category.begins_with("ITENS") else 4):
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
	player.inventory_changed.connect(refresh_open_inventory)

func refresh_open_inventory() -> void:
	if overlay.visible:
		refresh_inventory()
		refresh_stats()

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
	text.text = "STATUS DO PERSONAGEM\n\nNivel: %d | XP: %d/%d\nVida: %d/%d | Vida base: %d\nVelocidade de ataque base: 100%% | Intervalo: %.2f s\nMovimento base: %.1f m/s\nFlechas por disparo base: 1\nEscudo: %.1f/%.1f | Pulos: %d\nKills: %d | Moedas: %.1f" % [player.get("level"), player.get("xp"), player.call("xp_required"), player.get("health"), player.get("max_health"), player.get("base_max_health"), player.get("attack_interval"), player.get("move_speed"), player.get("shield"), player.call("max_shield"), player.call("max_jumps"), player.get("kills"), player.get("coins")]
	var lines := PackedStringArray()
	var names := {0: "Velocidade de ataque", 1: "Projeteis adicionais", 2: "Drop e orb de XP maior", 3: "Dificuldade", 4: "Velocidade de movimento", 5: "Sorte", 6: "Vida maxima", 7: "Regeneracao de vida / minuto", 8: "Escudo", 9: "Desvio", 13: "Armadura", 14: "Espinhos", 15: "Dano global", 16: "Acerto critico", 17: "Tamanho dos ataques", 18: "Duracao dos ataques", 19: "Impacto", 20: "Roubo de vida", 21: "Velocidade dos projeteis", 22: "Ouro", 23: "Metal prateado", 24: "Magnetismo"}
	for kind in names:
		var amount: float = 0.0
		match kind:
			0: amount = player.get("attack_speed_bonus")
			1: amount = player.get("projectile_bonus_tenths") / 10.0 - float(player.get("character_buffs").get(1, 0))
			2: amount = player.get("extra_xp_chance")
			3: amount = player.get("difficulty_bonus") - float(player.get("character_buffs").get(3, 0))
			4: amount = player.get("movement_speed_bonus") - float(player.get("character_buffs").get(4, 0))
			5: amount = player.get("luck_bonus") - float(player.get("character_buffs").get(5, 0))
			_: amount = player.call("tome_bonus", kind)
		if amount > 0.0:
			var suffix := "" if kind in [1, 6, 7, 8, 14] else "%"
			lines.append("%s: +%.1f%s" % [names[kind], amount, suffix])
	bonus_text.text = "BÔNUS DOS CRISTAIS\n\n" + ("\n".join(lines) if not lines.is_empty() else "Nenhum cristal adquirido ainda.")
	var rewards := preload("res://scripts/shrine_rewards.gd")
	var direct: Dictionary = player.get("character_buffs")
	var direct_lines := PackedStringArray()
	for kind in direct:
		direct_lines.append("%s: %s" % [rewards.NAMES[kind], rewards.describe(kind, direct[kind])])
	bonus_text.text += "\n\nBUFFS DOS TOTENS\n" + ("\n".join(direct_lines) if not direct_lines.is_empty() else "Nenhum buff de totem adquirido.")

func refresh_inventory() -> void:
	var items: Array = player.get("item_slots")
	var buffs: Array = player.get("buff_slots")
	for i in range(item_labels.size()):
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
					var title: String = preload("res://scripts/weapon_upgrades.gd").LABELS.get(attribute, attribute)
					var value := "+%.2f%s" % [data.get(attribute, 0.0), "" if attribute in ["damage", "projectiles", "bounces"] else "%"]
					if attribute == "bounces":
						value = "+%d" % int(data[attribute])
					details.append("%s: %s" % [title, value])
				# Detalhes completos ficam no tooltip para manter os slots compactos.
				item_labels[i].get_parent().tooltip_text = "\n".join(details) + "\nCtrl + clique: melhorar"
	for i in range(crystal_slots.size()):
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
