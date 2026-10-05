extends CanvasLayer

var rows: Dictionary = {}
var column: VBoxContainer

func _ready() -> void:
	layer = 6
	var anchor := CenterContainer.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	anchor.offset_top = 90
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(anchor)
	column = VBoxContainer.new()
	column.custom_minimum_size.x = 460
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 8)
	anchor.add_child(column)

func _process(_delta: float) -> void:
	var active: Array[int] = []
	for boss in get_tree().get_nodes_in_group("bosses"):
		if not is_instance_valid(boss) or boss.is_queued_for_deletion() or int(boss.get("health")) <= 0:
			continue
		var id := boss.get_instance_id()
		active.append(id)
		if not rows.has(id):
			var row := VBoxContainer.new()
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			column.add_child(row)
			var title := Label.new()
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.add_theme_font_size_override("font_size", 18)
			title.add_theme_color_override("font_color", Color("ffe7a1"))
			title.add_theme_color_override("font_outline_color", Color("16202c"))
			title.add_theme_constant_override("outline_size", 5)
			row.add_child(title)
			var bar := ProgressBar.new()
			bar.custom_minimum_size = Vector2(460, 22)
			bar.show_percentage = false
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for part in ["background", "fill"]:
				var style := StyleBoxFlat.new()
				style.bg_color = Color("ce534d") if part == "fill" else Color("202833")
				style.set_corner_radius_all(7)
				style.set_border_width_all(2)
				style.border_color = Color("41252d") if part == "fill" else Color("efc778")
				bar.add_theme_stylebox_override(part, style)
			row.add_child(bar)
			rows[id] = row
		var row: VBoxContainer = rows[id]
		var title: Label = row.get_child(0)
		var bar: ProgressBar = row.get_child(1)
		title.text = "%s   %d / %d" % [boss.get("display_name"), boss.get("health"), boss.get("max_health")]
		bar.max_value = boss.get("max_health")
		bar.value = boss.get("health")
	for id in rows.keys():
		if id not in active:
			rows[id].hide()
			rows[id].queue_free()
			rows.erase(id)
