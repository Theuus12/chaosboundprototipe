extends Control

const Options = preload("res://scripts/game_options.gd")
const Records = preload("res://scripts/personal_ranking.gd")
var settings: PanelContainer
var play_button: Button

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var backdrop := Control.new()
	backdrop.set_script(preload("res://scripts/menu_backdrop.gd"))
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var title := label("CHAOSBOUND", 76, Color("fff3ce"))
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-390, 64)
	title.size = Vector2(780, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var subtitle := label("Uma flecha. Uma horda. Seu próximo recorde!", 20, Color("ffe08a"))
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-390, 164)
	subtitle.size.x = 780
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	play_button = button("JOGAR", Color("ffc34d"), func(): get_tree().change_scene_to_file("res://scenes/arena.tscn"))
	play_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	play_button.position = Vector2(-155, -30)
	play_button.size = Vector2(310, 90)
	add_child(play_button)
	var navigation := VBoxContainer.new()
	navigation.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	navigation.position = Vector2(36, -176)
	navigation.add_theme_constant_override("separation", 14)
	add_child(navigation)
	navigation.add_child(button("SETTINGS", Color("d7e9dd"), func(): settings.show(); settings.get_child(0).get_child(1).grab_focus()))
	navigation.add_child(button("SAIR", Color("eda18d"), func(): get_tree().quit()))
	build_ranking()
	build_settings()
	play_button.grab_focus()

func style(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = Color("17272a")
	box.set_border_width_all(4)
	box.set_corner_radius_all(18)
	box.shadow_color = Color(0.03, 0.08, 0.09, 0.7)
	box.shadow_size = 7
	box.shadow_offset = Vector2(0, 7)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	return box

func label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color("15292c"))
	node.add_theme_constant_override("outline_size", 8 if font_size > 40 else 3)
	return node

func button(text: String, color: Color, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(210, 62)
	node.add_theme_font_size_override("font_size", 26)
	for state in ["normal", "hover", "pressed", "focus"]:
		node.add_theme_stylebox_override(state, style(color.lightened(0.15) if state in ["hover", "focus"] else color.darkened(0.12) if state == "pressed" else color))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(state, Color("183239"))
	node.pressed.connect(action)
	return node

func build_ranking() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	panel.position = Vector2(-370, -112)
	panel.size = Vector2(334, 370)
	panel.add_theme_stylebox_override("panel", style(Color("213e40")))
	add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	panel.add_child(rows)
	rows.add_child(label("RANKING PESSOAL", 24, Color("ffe08a")))
	rows.add_child(label("Suas melhores partidas · KILLS", 15, Color("b8d8ce")))
	var data := Records.read_data()
	var runs: Array = data.get("runs", [])
	for i in range(5):
		var entry := HBoxContainer.new()
		rows.add_child(entry)
		var name_label := label("#%d   %s" % [i + 1, str(runs[i].get("date", "Partida")) if i < runs.size() else "—"], 18)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.add_child(name_label)
		entry.add_child(label(str(runs[i].get("kills", 0)) if i < runs.size() else "—", 22, Color("ffe08a")))
	rows.add_child(HSeparator.new())
	rows.add_child(label("TOTAL DE KILLS   %d" % int(data.get("total", 0)), 18, Color("9fe5ae")))
	if runs.is_empty():
		rows.add_child(label("Jogue para marcar seu primeiro recorde!", 13))

func build_settings() -> void:
	settings = PanelContainer.new()
	settings.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings.position = Vector2(-235, -190)
	settings.size = Vector2(470, 380)
	settings.add_theme_stylebox_override("panel", style(Color("294e4e")))
	add_child(settings)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 20)
	settings.add_child(rows)
	rows.add_child(label("SETTINGS", 32, Color("ffe08a")))
	var fullscreen := CheckButton.new()
	fullscreen.text = "Tela cheia"
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(func(enabled: bool): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	rows.add_child(fullscreen)
	rows.add_child(label("Sensibilidade do mouse", 20))
	var slider := HSlider.new()
	slider.min_value = 0.001
	slider.max_value = 0.008
	slider.step = 0.00025
	slider.value = Options.mouse_sensitivity
	slider.value_changed.connect(func(value: float): Options.mouse_sensitivity = value)
	rows.add_child(slider)
	rows.add_child(button("VOLTAR", Color("ffc34d"), func(): settings.hide(); play_button.grab_focus()))
	settings.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and settings.visible:
		settings.hide()
		play_button.grab_focus()
