extends VBoxContainer

var icon: TextureRect
var level_label: Label
static var textures: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 0)
	icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	level_label = Label.new()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color.WHITE)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(level_label)

func update_buff(player: Node, kind: int) -> void:
	if kind < 0:
		icon.texture = null
		level_label.text = "—"
		tooltip_text = "Slot de cristal vazio"
		return
	if not textures.has(kind):
		textures[kind] = load("res://assets/ui/crystals/crystal_%d.svg" % kind)
	icon.texture = textures[kind]
	level_label.text = "Nv. %d" % player.get("buff_stacks").get(kind, 0)
	tooltip_text = "%s\n%s\n%s" % [player.BUFF_NAMES[kind], player.call("buff_value", kind), preload("res://scripts/tomes.gd").DESCRIPTIONS[kind]]
