extends Node3D
const Forest = preload("res://scripts/forest.gd")

var player: CharacterBody3D
var navigation: NavigationRegion3D
var spawn_left: float = 2.0
var elapsed_time: float = 0.0
var difficulty_refresh_left: float = 0.0
var population_stage: int = 0
var overtime_stage: int = 0
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 50
@export var horde_enemy_limit: int = 100
const NORMAL_SPAWN_BATCH = 6
const HORDE_SPAWN_BATCH = 6
var horde_was_active := false
@export var spawn_min_distance: float = 16.0
@export var spawn_max_distance: float = 26.0
var pending_spawns: int = 0
var goblins_since_skeleton: int = 0
var enemies_since_lich: int = 0
var final_boss_spawned := false
var infernal_eyes_unlocked := false
var enemies_since_eye := 0
var enemies_since_soldier := 0
var boss_altar: StaticBody3D
const HORDE_TIMES = [120.0, 240.0, 360.0, 540.0]
var hordes_announced: Array[int] = []
var horde_until: float = -1.0
var horde_spawn_left: float = 0.0
var boss_spawned: bool = false
var boss: CharacterBody3D
var orcs_spawned: Array[int] = []
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
				horde_spawn_left = effective_spawn_interval()
				announce("Uma horda está a caminho")
	for rank in range(1, 3):
		if elapsed_time >= [180.0, 300.0, 480.0][rank] and rank not in orcs_spawned:
			spawn_boss(rank)

func spawn_final_boss(origin: Vector3 = Vector3.ZERO) -> bool:
	if final_boss_spawned or NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) == 0:
		return false
	var final_enemy = preload("res://scenes/final_boss.tscn").instantiate()
	final_enemy.set("target", player)
	var desired := origin + Vector3(0, 0, 9)
	desired.x = clampf(desired.x, -Forest.PLAYABLE_LIMIT, Forest.PLAYABLE_LIMIT)
	desired.z = clampf(desired.z, -Forest.PLAYABLE_LIMIT, Forest.PLAYABLE_LIMIT)
	final_enemy.position = NavigationServer3D.map_get_closest_point(navigation.get_navigation_map(), desired)
	reserve_boss_slot()
	add_child(final_enemy)
	final_boss_spawned = true
	announce("O REI OSSUARIO chegou! Boss final!")
	return true

func final_boss_defeated() -> void:
	if infernal_eyes_unlocked:
		return
	infernal_eyes_unlocked = true
	enemies_since_eye = 6
	announce("Boss final derrotado! Os Olhos Infernais despertaram!")

func spawn_boss(rank: int = 2) -> void:
	if rank == 0:
		return
	if NavigationServer3D.map_get_iteration_id(navigation.get_navigation_map()) == 0:
		return
	boss = CharacterBody3D.new()
	boss.set_script(preload("res://scripts/orc_boss.gd"))
	boss.set("orc_rank", rank)
	boss.set("target", player)
	var desired := player.global_position + Vector3(25, 0, 0)
	desired.x = clampf(desired.x, -Forest.PLAYABLE_LIMIT, Forest.PLAYABLE_LIMIT)
	desired.z = clampf(desired.z, -Forest.PLAYABLE_LIMIT, Forest.PLAYABLE_LIMIT)
	desired.y = 0.0
	boss.position = desired
	reserve_boss_slot()
	add_child(boss)
	boss_spawned = true
	orcs_spawned.append(rank)
	announce("O %s chegou!" % boss.get("display_name"))

func _ready() -> void:
	var boss_hud := CanvasLayer.new()
	boss_hud.set_script(preload("res://scripts/boss_health_hud.gd"))
	add_child(boss_hud)
	var record := Node.new()
	record.set_script(preload("res://scripts/run_record.gd"))
	call_deferred("add_child", record)
	configure_input()
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("637c73")
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color("637c73")
	environment.fog_depth_begin = 24.0
	environment.fog_depth_end = 65.0
	environment.fog_density = 1.0
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
	navmesh.cell_size = 0.5
	navmesh.cell_height = 0.25
	navmesh.agent_radius = 0.5
	navmesh.agent_height = 1.5
	navmesh.agent_max_climb = 0.25
	navmesh.agent_max_slope = 45.0
	navmesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation.navigation_mesh = navmesh
	add_child(navigation)
	preload("res://scripts/forest.gd").populate(self)
	var statue_shops := Node.new()
	statue_shops.name = "StatueShops"
	statue_shops.set_script(preload("res://scripts/statue_shops.gd"))
	add_child(statue_shops)
	statue_shops.call("populate", self)
	place_boss_altar()
	navigation.bake_navigation_mesh(false)
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(0, 2, 0)
	player.mouse_sensitivity = preload("res://scripts/game_options.gd").mouse_sensitivity
	add_child(player)
	statue_shops.call("setup", player)
	boss_altar.call("setup", player)
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

func place_boss_altar() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 93127
	var point := Vector3(48, 0, -40)
	for attempt in range(200):
		if attempt > 0:
			point = Vector3(rng.randf_range(25, 75), 0, rng.randf_range(-65, -25))
		var clear := true
		for obstacle in get_tree().get_nodes_in_group("trees") + get_tree().get_nodes_in_group("buff_statues"):
			if Vector2(point.x, point.z).distance_to(Vector2(obstacle.global_position.x, obstacle.global_position.z)) < 7.0:
				clear = false
				break
		if clear:
			break
	point.y = Forest.ground_height(point.x, point.z)
	boss_altar = StaticBody3D.new()
	boss_altar.name = "BossAltar"
	boss_altar.set_script(preload("res://scripts/boss_altar.gd"))
	boss_altar.position = point
	navigation.add_child(boss_altar)

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
	difficulty_refresh_left -= delta
	if difficulty_refresh_left <= 0.0:
		difficulty_refresh_left = 5.0
		update_difficulty(player.get("difficulty_bonus"))
	update_events()
	if horde_was_active and not horde_active():
		while regular_enemy_count() > population_limit():
			remove_farthest_regular_enemy()
		pending_spawns = 0
		spawn_left = effective_spawn_interval()
	horde_was_active = horde_active()
	if horde_active():
		horde_spawn_left -= delta
		if horde_spawn_left <= 0.0:
			horde_spawn_left = effective_spawn_interval()
			queue_monsters(HORDE_SPAWN_BATCH)
	else:
		spawn_left -= delta
		if spawn_left <= 0.0:
			spawn_left = effective_spawn_interval()
			queue_monsters(NORMAL_SPAWN_BATCH)
	var next_stage := maxi(0, int((elapsed_time - 600.0) / 300.0))
	if next_stage != overtime_stage:
		overtime_stage = next_stage
		update_difficulty(player.get("difficulty_bonus"))
	# Hordas não dependem de mortes. Crie no máximo o grupo de três por frame.
	var room := population_limit() - regular_enemy_count()
	pending_spawns = mini(pending_spawns, maxi(0, room))
	for i in range(mini(pending_spawns, mini(3, maxi(0, room)))):
		if not spawn_enemy():
			break
		pending_spawns -= 1

func enemy_defeated() -> void:
	# A reposição acontece nos intervalos dos grupos, sem filas extras por morte.
	pass

func regular_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_in_group("bosses") and not enemy.is_queued_for_deletion():
			count += 1
	return count

func population_limit() -> int:
	var total_limit := horde_enemy_limit if horde_active() else max_enemies
	return maxi(0, total_limit - get_tree().get_nodes_in_group("bosses").size())

func reserve_boss_slot() -> void:
	# Preserve os bosses agendados mesmo se a horda anterior ainda estiver viva.
	var total_limit := horde_enemy_limit if horde_active() else max_enemies
	if get_tree().get_nodes_in_group("enemies").size() < total_limit:
		return
	remove_farthest_regular_enemy()

func remove_farthest_regular_enemy() -> void:
	var farthest: Node3D
	var distance := -1.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_in_group("bosses") or enemy.is_queued_for_deletion():
			continue
		var current: float = enemy.global_position.distance_squared_to(player.global_position)
		if current > distance:
			distance = current
			farthest = enemy
	if farthest != null:
		farthest.remove_from_group("enemies")
		farthest.queue_free()

func queue_monsters(count: int, defeated_pending: int = 0) -> void:
	var room := population_limit() - regular_enemy_count() - pending_spawns + defeated_pending
	pending_spawns += clampi(room, 0, count)

func effective_wave_size() -> int:
	return HORDE_SPAWN_BATCH if horde_active() else NORMAL_SPAWN_BATCH

func spawn_wave() -> void:
	queue_monsters(effective_wave_size())

func effective_spawn_interval() -> float:
	return spawn_interval

func effective_enemy_limit() -> int:
	return max_enemies

func update_difficulty(total_percent: float) -> void:
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
		if ground.is_empty() or ground.normal.dot(Vector3.UP) < cos(deg_to_rad(45.0)):
			continue
		point = ground.position
		var occupied := false
		for other in get_tree().get_nodes_in_group("enemies"):
			if other.global_position.distance_to(point) < 1.2:
				occupied = true
				break
		if occupied:
			continue
		var eye_spawn := infernal_eyes_unlocked and enemies_since_eye >= 6
		var late_phase := elapsed_time >= 300.0
		var lich_spawn := not eye_spawn and elapsed_time >= 120.0 and enemies_since_lich >= (3 if late_phase else 12) and (late_phase or goblins_since_skeleton < 20)
		var soldier_spawn := not eye_spawn and not lich_spawn and not late_phase and elapsed_time >= 180.0 and enemies_since_soldier >= 9
		var enemy := CharacterBody3D.new()
		enemy.set_script(preload("res://scripts/infernal_eye.gd") if eye_spawn else (preload("res://scripts/lich.gd") if lich_spawn else (preload("res://scripts/orc_soldier.gd") if soldier_spawn else preload("res://scripts/enemy.gd"))))
		enemy.set("target", player)
		var skeleton_spawn := not eye_spawn and not lich_spawn and not soldier_spawn and (late_phase or goblins_since_skeleton >= 20)
		if lich_spawn or eye_spawn:
			enemy.add_to_group("elites")
		if skeleton_spawn:
			enemy.set("max_health", preload("res://scripts/enemy.gd").SKELETON_BASE_HEALTH)
			enemy.set("model_path", "res://assets/characters/skeleton/skeleton.glb")
			enemy.add_to_group("skeletons")
		elif not lich_spawn and not eye_spawn and not soldier_spawn:
			enemy.add_to_group("goblins")
		enemy.position = point + Vector3.UP * 0.1
		add_child(enemy)
		goblins_since_skeleton = 0 if skeleton_spawn else goblins_since_skeleton + (0 if lich_spawn or eye_spawn else 1)
		enemies_since_lich = 0 if lich_spawn else enemies_since_lich + 1
		enemies_since_eye = 0 if eye_spawn else enemies_since_eye + 1
		enemies_since_soldier = 0 if soldier_spawn else enemies_since_soldier + 1
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
	var bindings := {"forward": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "reset": KEY_R, "restart": KEY_ENTER, "interact": KEY_E}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = bindings[action]
		InputMap.action_add_event(action, event)

func overtime_multiplier() -> float:
	return pow(4.0, minf(10.0, maxf(0.0, elapsed_time - 600.0) / 60.0))

func enemy_multipliers(total_percent: float) -> Dictionary:
	return preload("res://scripts/difficulty_scaling.gd").multipliers(elapsed_time, total_percent)
