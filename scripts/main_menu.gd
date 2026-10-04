extends Control

var main: VBoxContainer
var options: VBoxContainer
const Options = preload("res://scripts/game_options.gd")

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := ColorRect.new()
	background.color = Color("142820")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	main = VBoxContainer.new()
	main.custom_minimum_size.x = 360
	main.add_theme_constant_override("separation", 18)
	center.add_child(main)
	var title := Label.new()
	title.text = "ARENA RUSH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	main.add_child(title)
	button(main, "Jogar", play)
	button(main, "Opções", func(): main.hide(); options.show())
	button(main, "Sair", func(): get_tree().quit())
	options = VBoxContainer.new()
	options.custom_minimum_size.x = 360
	options.add_theme_constant_override("separation", 18)
	center.add_child(options)
	var label := Label.new()
	label.text = "OPÇÕES"
	label.add_theme_font_size_override("font_size", 30)
	options.add_child(label)
	var fullscreen := CheckButton.new()
	fullscreen.text = "Tela cheia"
	fullscreen.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen.toggled.connect(func(enabled: bool): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	options.add_child(fullscreen)
	var sensitivity := Label.new()
	sensitivity.text = "Sensibilidade do mouse"
	options.add_child(sensitivity)
	var slider := HSlider.new()
	slider.min_value = 0.001
	slider.max_value = 0.008
	slider.step = 0.00025
	slider.value = Options.mouse_sensitivity
	slider.value_changed.connect(func(value: float): Options.mouse_sensitivity = value)
	options.add_child(slider)
	button(options, "Voltar", func(): options.hide(); main.show())
	options.hide()
	main.get_child(1).grab_focus()

func button(parent: Node, title: String, action: Callable) -> void:
	var control := Button.new()
	control.text = title
	control.custom_minimum_size = Vector2(360, 54)
	control.add_theme_font_size_override("font_size", 22)
	control.pressed.connect(action)
	parent.add_child(control)

func play() -> void:
	get_tree().change_scene_to_file("res://scenes/arena.tscn")
