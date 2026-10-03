extends Node3D

var player: CharacterBody3D
var status: Label
var health_ui: ProgressBar
var xp_ui: ProgressBar
var xp_label: Label
var death_message: Label
var navigation: NavigationRegion3D
var spawn_left: float = 1.0
@export var spawn_interval: float = 1.8
@export var max_enemies: int = 25
@export var spawn_min_distance: float = 8.0
@export var spawn_max_distance: float = 13.0

func _ready() -> void:
	configure_input()
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("182438")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b7cfeb")
	environment.ambient_light_energy = 0.65
	environment_node.environment = environment
	add_child(environment_node)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	navigation = NavigationRegion3D.new()
	var navmesh := NavigationMesh.new()
	navmesh.cell_size = 0.25
	navmesh.cell_height = 0.25
	navmesh.agent_radius = 0.5
	navmesh.agent_height = 1.5
	navmesh.agent_max_climb = 0.25
	navmesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation.navigation_mesh = navmesh
	add_child(navigation)
	add_box(Vector3(0, -0.5, 0), Vector3(60, 1, 60), Color("31485a"))
	for i in range(6):
		add_box(Vector3(-12, 0.5 + i * 0.3, -3 - i * 3), Vector3(5, 1 + i * 0.6, 2.5), Color("4e918d"))
	for pos in [Vector3(9, 1, -7), Vector3(15, 2, -12), Vector3(8, 3, -18)]:
		add_box(pos, Vector3(4, pos.y * 2, 4), Color("687bc0"))
	for i in range(5):
		add_box(Vector3(-8 + i * 4, 0.1, 9), Vector3(2, 0.2, 2), Color("e4ad56"))
	navigation.bake_navigation_mesh(false)
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(0, 2, 0)
	add_child(player)
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	hud.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	var title := Label.new()
	title.text = "ARENA RUSH | Laboratorio de movimento"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	var controls := Label.new()
	controls.text = "WASD: mover | Mouse: camera | Espaco: saltar\nShift: correr | Q: dash | R: voltar ao inicio\nEsc: soltar/capturar mouse | Clique: capturar mouse"
	column.add_child(controls)
	status = Label.new()
	column.add_child(status)
	health_ui = ProgressBar.new()
	health_ui.custom_minimum_size = Vector2(360, 24)
	health_ui.max_value = player.get("max_health")
	health_ui.show_percentage = false
	column.add_child(health_ui)
	xp_label = Label.new()
	column.add_child(xp_label)
	xp_ui = ProgressBar.new()
	xp_ui.custom_minimum_size = Vector2(360, 18)
	xp_ui.max_value = 100
	xp_ui.show_percentage = false
	var xp_style := StyleBoxFlat.new()
	xp_style.bg_color = Color("40a4ff")
	xp_style.set_corner_radius_all(4)
	xp_ui.add_theme_stylebox_override("fill", xp_style)
	column.add_child(xp_ui)
	death_message = Label.new()
	death_message.text = "VOCE MORREU — pressione Enter para reiniciar"
	death_message.add_theme_color_override("font_color", Color("ff7979"))
	death_message.visible = false
	column.add_child(death_message)

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		status.text = "Vida: %d/%d | Inimigos: %d\nVelocidade: %.1f m/s | Dash: %.1f s" % [player.get("health"), player.get("max_health"), get_tree().get_nodes_in_group("enemies").size(), Vector2(player.velocity.x, player.velocity.z).length(), player.get("cooldown_left")]
		health_ui.value = player.get("health")
		xp_ui.value = player.get("xp")
		xp_label.text = "Nivel %d | XP: %d/100 | Bonus amarelos: %d" % [player.get("level"), player.get("xp"), player.get("bonus_orbs")]
		death_message.visible = player.get("dead")

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.get("dead"):
		return
	spawn_left -= delta
	if spawn_left <= 0.0:
		spawn_left = spawn_interval
		if get_tree().get_nodes_in_group("enemies").size() < max_enemies:
			spawn_enemy()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(player) and player.get("dead") and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func spawn_enemy() -> void:
	var map := navigation.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return
	for attempt in range(16):
		var angle := randf() * TAU
		var radius := randf_range(spawn_min_distance, spawn_max_distance)
		var desired := player.global_position + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		desired.y = 0.0
		var point := NavigationServer3D.map_get_closest_point(map, desired)
		var distance := Vector2(point.x - player.global_position.x, point.z - player.global_position.z).length()
		if distance < spawn_min_distance or distance > spawn_max_distance:
			continue
		var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point - Vector3.UP * 3.0, 1)
		var ground := get_world_3d().direct_space_state.intersect_ray(query)
		if ground.is_empty() or ground.position.y > 0.3:
			continue
		point = ground.position
		var occupied := false
		for other in get_tree().get_nodes_in_group("enemies"):
			if other.global_position.distance_to(point) < 1.2:
				occupied = true
				break
		if occupied:
			continue
		var enemy := CharacterBody3D.new()
		enemy.set_script(preload("res://scripts/enemy.gd"))
		enemy.set("target", player)
		enemy.position = point + Vector3.UP * 0.1
		add_child(enemy)
		return

func add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	body.add_child(visual)
	navigation.add_child(body)

func configure_input() -> void:
	var bindings := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "sprint": KEY_SHIFT, "dash": KEY_Q, "reset": KEY_R, "release_mouse": KEY_ESCAPE, "restart": KEY_ENTER}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)
