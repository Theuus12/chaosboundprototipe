extends Node3D

var player: CharacterBody3D
var navigation: NavigationRegion3D
var spawn_left: float = 1.0
var elapsed_time: float = 0.0
var overtime_stage: int = 0
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
	player.connect("difficulty_changed", update_difficulty)
	var hud := CanvasLayer.new()
	hud.name = "GameHUD"
	hud.set_script(preload("res://scripts/game_hud.gd"))
	hud.set("player", player)
	add_child(hud)
	var upgrade_menu := CanvasLayer.new()
	upgrade_menu.name = "UpgradeMenu"
	upgrade_menu.set_script(preload("res://scripts/upgrade_menu.gd"))
	upgrade_menu.set("player", player)
	add_child(upgrade_menu)
	var stats_menu := CanvasLayer.new()
	stats_menu.name = "StatsMenu"
	stats_menu.set_script(preload("res://scripts/stats_menu.gd"))
	stats_menu.set("player", player)
	add_child(stats_menu)

func spawn_magnet(pos: Vector3) -> void:
	var magnet := Node3D.new()
	magnet.set_script(preload("res://scripts/magnet.gd"))
	magnet.set("target", player)
	magnet.position = pos
	add_child(magnet)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.get("dead"):
		return
	spawn_left -= delta
	elapsed_time += delta
	var next_stage := maxi(0, int((elapsed_time - 600.0) / 300.0))
	if next_stage != overtime_stage:
		overtime_stage = next_stage
		update_difficulty(player.get("difficulty_bonus"))
	if spawn_left <= 0.0:
		spawn_left = effective_spawn_interval()
		spawn_wave()

func effective_wave_size() -> int:
	return 1 + int(player.get("difficulty_bonus") * 3 / 10.0)

func spawn_wave() -> void:
	var remaining := effective_enemy_limit() - get_tree().get_nodes_in_group("enemies").size()
	for i in range(mini(effective_wave_size(), remaining)):
		spawn_enemy()

func effective_spawn_interval() -> float:
	return spawn_interval / (1.0 + player.get("difficulty_bonus") / 100.0)

func effective_enemy_limit() -> int:
	return ceili(max_enemies * (1.0 + player.get("difficulty_bonus") / 100.0))

func update_difficulty(total_percent: int) -> void:
	spawn_left = minf(spawn_left, effective_spawn_interval())
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_queued_for_deletion():
			enemy.call("apply_difficulty", total_percent, overtime_multiplier())

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
		enemy.call("apply_difficulty", player.get("difficulty_bonus"), overtime_multiplier())
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
	if not InputMap.has_action("stats"):
		InputMap.add_action("stats")
		var tab := InputEventKey.new()
		tab.physical_keycode = KEY_ESCAPE
		InputMap.action_add_event("stats", tab)
	var bindings := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "reset": KEY_R, "restart": KEY_ENTER}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)

func overtime_multiplier() -> float:
	return pow(2.0, overtime_stage)
