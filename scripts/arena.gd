extends Node3D

var player: CharacterBody3D
var navigation: NavigationRegion3D
var spawn_left: float = 1.0
var elapsed_time: float = 0.0
var overtime_stage: int = 0
@export var spawn_interval: float = 1.8
@export var max_enemies: int = 25
@export var horde_enemy_limit: int = 24
@export var spawn_min_distance: float = 16.0
@export var spawn_max_distance: float = 26.0
var pending_spawns: int = 12
const HORDE_TIMES = [120.0, 240.0, 360.0, 540.0]
var hordes_announced: Array[int] = []
var horde_until: float = -1.0
var horde_spawn_left: float = 0.0
var boss_spawned: bool = false
var boss: CharacterBody3D
var announcement: String = ""
var announcement_until: float = 0.0

func horde_active() -> bool:
	return elapsed_time < horde_until

func announce(message: String) -> void:
	announcement = message
	announcement_until = elapsed_time + 5.0

func update_events() -> void:
	for i in range(HORDE_TIMES.size()):
		if elapsed_time >= HORDE_TIMES[i] and i not in hordes_announced:
			hordes_announced.append(i)
			if elapsed_time < HORDE_TIMES[i] + 30.0:
				horde_until = HORDE_TIMES[i] + 30.0
				horde_spawn_left = 0.0
				announce("Uma horda está a caminho")
	# Ten-minute countdown: 180 seconds elapsed means 7:00 remaining.
	if elapsed_time >= 180.0 and not boss_spawned:
		spawn_boss()

func spawn_boss() -> void:
	if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) == 0:
		return
	boss = CharacterBody3D.new()
	boss.set_script(preload("res://scripts/orc_boss.gd"))
	boss.set("target", player)
	var desired := player.global_position + Vector3(25, 0, 0)
	desired.x = clampf(desired.x, -48.0, 48.0)
	desired.z = clampf(desired.z, -48.0, 48.0)
	desired.y = 0.0
	boss.position = desired
	add_child(boss)
	boss_spawned = true
	announce("O Chefe Orc chegou!")

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
	preload("res://scripts/forest.gd").populate(self)
	navigation.bake_navigation_mesh(false)
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(0, 2, 0)
	player.mouse_sensitivity = preload("res://scripts/game_options.gd").mouse_sensitivity
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
	elapsed_time += delta
	update_events()
	if horde_active():
		horde_spawn_left -= delta
		if horde_spawn_left <= 0.0:
			horde_spawn_left += effective_spawn_interval() / 3.0
			if get_tree().get_nodes_in_group("enemies").size() + pending_spawns < horde_enemy_limit:
				pending_spawns += 1
	var next_stage := maxi(0, int((elapsed_time - 600.0) / 300.0))
	if next_stage != overtime_stage:
		overtime_stage = next_stage
		update_difficulty(player.get("difficulty_bonus"))
	# Retry failed placements when navigation is ready; one replacement per kill.
	# Spread instantiation across frames instead of building twelve models at once.
	var room := horde_enemy_limit - get_tree().get_nodes_in_group("enemies").size()
	for i in range(mini(pending_spawns, mini(1, maxi(0, room)))):
		if not spawn_enemy():
			break
		pending_spawns -= 1

func enemy_defeated() -> void:
	if horde_active():
		var room := horde_enemy_limit - get_tree().get_nodes_in_group("enemies").size() - pending_spawns + 1
		pending_spawns += clampi(room, 0, 3)
	else:
		pending_spawns += 1

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

func spawn_enemy() -> bool:
	var map := navigation.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
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
		return true
	return false

func add_box(pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
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
	return body

func add_structure(pos: Vector3, size: Vector3, color: Color, direction: Vector3) -> void:
	add_box(pos, size, color)
	var height := pos.y + size.y * 0.5
	var edge := pos + direction * (size.x * 0.5 if absf(direction.x) > 0.5 else size.z * 0.5)
	edge.y = 0.0
	var run := height * 1.8
	var width := 2.6
	var vertices := PackedVector3Array([
		Vector3(-width / 2, 0, 0), Vector3(width / 2, 0, 0),
		Vector3(-width / 2, height, 0), Vector3(width / 2, height, 0),
		Vector3(-width / 2, 0, run), Vector3(width / 2, 0, run)
	])
	var body := StaticBody3D.new()
	body.name = "ClimbRamp"
	body.add_to_group("climb_routes")
	body.position = edge
	body.rotation.y = atan2(direction.x, direction.z)
	var collision := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	shape.points = vertices
	collision.shape = shape
	body.add_child(collision)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Godot usa faces em sentido horario: o topo precisa apontar para fora.
	# A ordem invertida ocultava a superficie inclinada pelo backface culling.
	for index in [2, 3, 5, 2, 5, 4, 0, 2, 4, 1, 5, 3, 0, 1, 3, 0, 3, 2, 0, 4, 5, 0, 5, 1]:
		surface.add_vertex(vertices[index])
	surface.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = color.lightened(0.15)
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
