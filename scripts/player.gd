extends CharacterBody3D
## Ajuste estes valores aqui; numa cena propria ficam disponiveis no Inspector.
@export var move_speed: float = 9.0
@export var sprint_speed: float = 14.0
@export var acceleration: float = 38.0
@export var air_acceleration: float = 12.0
@export var jump_speed: float = 11.0
@export var gravity: float = 28.0
@export var dash_speed: float = 25.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.8
@export var mouse_sensitivity: float = 0.003
@export var max_health: int = 100
@export var damage_grace: float = 0.75
@export var attack_interval: float = 2.0
var shot_left: float = 2.0
var level: int = 1
var xp: int = 0
var bonus_orbs: int = 0

func collect_xp() -> void:
	xp += 20
	if xp >= 100:
		xp -= 100
		level += 1

func collect_bonus() -> void:
	bonus_orbs += 1

var health: int = 100
var dead: bool = false
var damage_grace_left: float = 0.0
var health_bar: Node3D

var pivot: Node3D
var visual: Node3D
var dash_left: float = 0.0
var cooldown_left: float = 0.0
var coyote_left: float = 0.0
var jump_buffer: float = 0.0
var dash_direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	health = max_health
	shot_left = attack_interval
	collision_layer = 2
	collision_mask = 1 | 4
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/archer_visual.gd"))
	visual.name = "ArcherVisual"
	add_child(visual)
	health_bar = Node3D.new()
	health_bar.set_script(preload("res://scripts/health_bar_3d.gd"))
	health_bar.position.y = 2.2
	add_child(health_bar)
	health_bar.call("set_health", health, max_health)
	pivot = Node3D.new()
	pivot.position.y = 1.4
	pivot.rotation.x = -0.3
	add_child(pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 6.0
	arm.margin = 0.2
	pivot.add_child(arm)
	arm.add_excluded_object(get_rid())
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 80.0
	arm.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivot.rotation.y -= event.relative.x * mouse_sensitivity
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * mouse_sensitivity, -1.1, 0.35)

func _physics_process(delta: float) -> void:
	if dead:
		return
	shot_left -= delta
	if shot_left <= 0.0:
		shoot_arrow()
		shot_left += maxf(attack_interval, 0.05)
	damage_grace_left = maxf(0.0, damage_grace_left - delta)
	visual.visible = damage_grace_left <= 0.0 or int(damage_grace_left * 16.0) % 2 == 0
	cooldown_left = maxf(0.0, cooldown_left - delta)
	coyote_left = 0.12 if is_on_floor() else maxf(0.0, coyote_left - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.12
	if jump_buffer > 0.0 and coyote_left > 0.0:
		velocity.y = jump_speed
		jump_buffer = 0.0
		coyote_left = 0.0
	if not is_on_floor():
		velocity.y -= gravity * delta
	var input_axis := Input.get_vector("left", "right", "forward", "back")
	var direction := Basis(Vector3.UP, pivot.rotation.y) * Vector3(input_axis.x, 0.0, input_axis.y)
	if Input.is_action_just_pressed("dash") and cooldown_left <= 0.0:
		dash_direction = direction.normalized() if direction.length_squared() > 0.01 else -pivot.global_basis.z
		dash_direction.y = 0.0
		dash_direction = dash_direction.normalized()
		dash_left = dash_duration
		cooldown_left = dash_cooldown
	if dash_left > 0.0:
		dash_left = maxf(0.0, dash_left - delta)
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
	else:
		var speed := sprint_speed if Input.is_action_pressed("sprint") else move_speed
		var accel := acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.2:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-velocity.x, -velocity.z), minf(delta * 14.0, 1.0))
	visual.call("animate", delta, horizontal_speed, is_on_floor(), dash_left > 0.0)
	if global_position.y < -15.0 or Input.is_action_just_pressed("reset"):
		global_position = Vector3(0, 2, 0)
		velocity = Vector3.ZERO

func shoot_arrow() -> void:
	var origin := global_position + Vector3.UP * 0.9
	var nearest: Node3D = null
	var nearest_distance: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.get("health") <= 0:
			continue
		var distance: float = origin.distance_squared_to(enemy.global_position + Vector3.UP * 0.7)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	var aim := -visual.global_basis.z
	if nearest:
		aim = (nearest.global_position + Vector3.UP * 0.7 - origin).normalized()
	var arrow := Node3D.new()
	arrow.set_script(preload("res://scripts/arrow.gd"))
	arrow.set("direction", aim)
	# Na cena raiz, as flechas nao acompanham o movimento do jogador.
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = origin
	arrow.look_at(origin + aim, Vector3.UP if absf(aim.y) < 0.99 else Vector3.RIGHT)

func take_damage(amount: int) -> void:
	if dead or damage_grace_left > 0.0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	damage_grace_left = damage_grace
	health_bar.call("set_health", health, max_health)
	if health == 0:
		dead = true
		velocity = Vector3.ZERO
		visual.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
