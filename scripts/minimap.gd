extends Control
## Radar local com norte fixo. Não cria câmera ou renderização 3D extra.
const Rarity = preload("res://scripts/buff_rarity.gd")
const WORLD_RADIUS = 65.0
const MAP_RADIUS = 86.0
const CENTER = Vector2(110, 112)
var player: CharacterBody3D
var statues: Array[Node] = []
var altars: Array[Node] = []
var refresh_left := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	statues = get_tree().get_nodes_in_group("buff_statues")
	altars = get_tree().get_nodes_in_group("boss_altars")

func _process(delta: float) -> void:
	refresh_left -= delta
	if refresh_left <= 0:
		refresh_left = 0.05
		queue_redraw()

func map_offset(world: Vector3) -> Vector2:
	return Vector2(world.x - player.global_position.x, world.z - player.global_position.z) * MAP_RADIUS / WORLD_RADIUS

func nearby_statues() -> Array[Node]:
	var nearby: Array[Node] = []
	if not is_instance_valid(player):
		return nearby
	for statue in statues:
		if is_instance_valid(statue) and map_offset(statue.global_position).length() <= MAP_RADIUS - 5:
			nearby.append(statue)
	return nearby

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.025, 0.06, 0.065, 0.94)
	background.border_color = Color("536d66")
	background.set_border_width_all(2)
	background.set_corner_radius_all(14)
	draw_style_box(background, Rect2(Vector2.ZERO, size))
	draw_string(font, Vector2(68, 21), "MINIMAPA", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d5e3d9"))
	draw_circle(CENTER, MAP_RADIUS, Color("1c332e"))
	for radius in [MAP_RADIUS / 2, MAP_RADIUS]:
		draw_arc(CENTER, radius, 0, TAU, 64, Color("496357"), 1.0, true)
	draw_line(CENTER - Vector2(MAP_RADIUS, 0), CENTER + Vector2(MAP_RADIUS, 0), Color("365145"))
	draw_line(CENTER - Vector2(0, MAP_RADIUS), CENTER + Vector2(0, MAP_RADIUS), Color("365145"))
	draw_string(font, Vector2(105, 39), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e0e9df"))
	if not is_instance_valid(player):
		return
	# Direção da câmera e cone correspondentes ao FOV de 70 graus.
	var pivot: Node3D = player.get("pivot")
	var yaw := pivot.global_rotation.y if is_instance_valid(pivot) else player.global_rotation.y
	var forward := Vector2(-sin(yaw), -cos(yaw))
	var angle := forward.angle()
	var cone := PackedVector2Array([CENTER])
	for i in range(13):
		cone.append(CENTER + Vector2.from_angle(angle - deg_to_rad(35) + i * deg_to_rad(70) / 12) * 38)
	draw_colored_polygon(cone, Color(0.55, 0.85, 0.78, 0.13))
	for statue in nearby_statues():
		var point := CENTER + map_offset(statue.global_position)
		var used: bool = statue.get("purchased")
		var color: Color = Color("78817b") if used else Rarity.COLORS[statue.get("rarity")]
		draw_circle(point, 7, Color("0c1915"))
		draw_circle(point, 5, color)
		draw_rect(Rect2(point + Vector2(-3, 2), Vector2(6, 4)), color)
		for x in [-2, 2]:
			draw_circle(point + Vector2(x, -1), 1.3, Color("15221d"))
		if used:
			draw_line(point + Vector2(-5, 5), point + Vector2(5, -5), Color("d6c7a6"), 1.5, true)
	for altar in altars:
		if not is_instance_valid(altar) or map_offset(altar.global_position).length() > MAP_RADIUS - 6:
			continue
		var point := CENTER + map_offset(altar.global_position)
		var color := Color("78817b") if altar.get("activated") else Color("ffd15b")
		draw_colored_polygon(PackedVector2Array([point + Vector2(0, -7), point + Vector2(7, 0), point + Vector2(0, 7), point + Vector2(-7, 0)]), color)
		draw_circle(point, 2, Color("15221d"))
	draw_circle(CENTER, 7, Color("0a1815"))
	var side := forward.orthogonal()
	draw_colored_polygon(PackedVector2Array([CENTER + forward * 9, CENTER - forward * 5 + side * 5, CENTER - forward * 3, CENTER - forward * 5 - side * 5]), Color("b5fff0"))
	draw_string(font, Vector2(12, 220), "Você • Totens / Altar • 65 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c3d4c8"))
