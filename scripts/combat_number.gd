extends Label3D

static func show_number(target: Node3D, amount: int, healing: bool = false) -> void:
	if amount <= 0:
		return
	var number := Label3D.new()
	number.set_script(load("res://scripts/combat_number.gd"))
	number.text = ("+" if healing else "-") + str(amount)
	number.modulate = Color("6bff98") if healing else Color("ff7169")
	number.font_size = 48
	number.outline_size = 10
	number.outline_modulate = Color("15202b")
	number.pixel_size = 0.007
	number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	number.no_depth_test = true
	number.add_to_group("combat_numbers")
	number.set_meta("amount", amount)
	number.set_meta("healing", healing)
	target.get_tree().root.add_child(number)
	number.global_position = target.global_position + Vector3(randf_range(-0.18, 0.18), 2.15, 0)
	var tween := number.create_tween().set_parallel(true)
	tween.tween_property(number, "position:y", number.position.y + 0.9, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(number, "modulate:a", 0.0, 0.45).set_delay(0.4)
	tween.chain().tween_callback(number.queue_free)
