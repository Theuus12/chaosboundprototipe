extends Control

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var s := size / Vector2(1280, 720)
	draw_set_transform(Vector2.ZERO, 0, s)
	draw_rect(Rect2(0, 0, 1280, 720), Color("258fa3"))
	for cloud in [Vector2(90, 96), Vector2(410, 38), Vector2(1030, 100)]:
		for i in range(4):
			draw_circle(cloud + Vector2(i * 38, -sin(i) * 15), 39, Color("65b6bd"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 450), Vector2(230, 225), Vector2(470, 440), Vector2(720, 265), Vector2(1050, 470), Vector2(1280, 310), Vector2(1280, 720), Vector2(0, 720)]), Color("326e72"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 550), Vector2(280, 475), Vector2(580, 560), Vector2(930, 460), Vector2(1280, 530), Vector2(1280, 720), Vector2(0, 720)]), Color("42784a"))
	draw_rect(Rect2(0, 640, 1280, 80), Color("305c3b"))
	for tree in [Vector2(80, 390), Vector2(310, 460), Vector2(1120, 410), Vector2(1240, 345)]:
		draw_style_box(trunk(), Rect2(tree.x - 15, tree.y, 30, 170))
		for offset in [Vector2(-42, 0), Vector2(40, -9), Vector2(0, -55)]:
			draw_circle(tree + offset, 67, Color("193e36"))
			draw_circle(tree + offset + Vector2(-3, -7), 59, Color("61a055"))
			draw_circle(tree + offset + Vector2(-18, -25), 24, Color("7cb35e"))
	# A little cartoon archery camp in the foreground.
	draw_line(Vector2(345, 582), Vector2(315, 657), Color("292f32"), 14)
	draw_line(Vector2(345, 582), Vector2(380, 657), Color("292f32"), 14)
	for radius in [62, 48, 33, 16]:
		draw_circle(Vector2(345, 561), radius, Color("f0d9a0") if radius in [62, 33] else Color("ca6450"))
	for x in [477, 792]:
		draw_line(Vector2(x, 570), Vector2(x, 652), Color("573e30"), 12)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 16, 570), Vector2(x - 22, 543), Vector2(x - 5, 507), Vector2(x + 5, 538), Vector2(x + 17, 523), Vector2(x + 22, 557), Vector2(x + 12, 578)]), Color("ffb840"))
		draw_circle(Vector2(x, 556), 11, Color("fff09b"))

func trunk() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("78563d")
	box.border_color = Color("283d32")
	box.set_border_width_all(4)
	box.set_corner_radius_all(7)
	return box
