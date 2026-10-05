extends "res://scripts/enemy.gd"

var display_name := "Rei Ossuario"
var slam_left := 4.0
var slam_windup := 0.0
var body_height := 10.9

func _ready() -> void:
	max_health = 50000
	contact_damage = 35
	move_speed = 2.8
	super._ready()
	add_to_group("bosses")
	add_to_group("final_bosses")
	visual.free()
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/final_boss_visual.gd"))
	visual.scale = Vector3.ONE * (body_height / 2.86)
	add_child(visual)
	health_bar.position.y = body_height + 0.5
	health_bar.scale = Vector3.ONE * 3.0
	for child in get_children():
		if child is CollisionShape3D:
			child.shape.radius = 2.0
			child.shape.height = body_height
			child.position.y = body_height / 2.0
	agent.avoidance_enabled = false
	collision_mask = 2

func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target) or target.get("dead"):
		return
	hit_flash = maxf(0, hit_flash - delta)
	var direction := target.global_position - global_position
	direction.y = 0
	velocity = direction.normalized() * move_speed
	if direction.length() < 2.6:
		velocity = Vector3.ZERO
		if target.global_position.y < global_position.y + body_height:
			target.call("take_damage", contact_damage, self)
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 3, 1))
	move_and_slide()
	global_position.y = preload("res://scripts/forest.gd").ground_height(global_position.x, global_position.z)
	visual.call("animate", delta, velocity.length(), false, hit_flash > 0)
	slam_left -= delta
	if slam_left <= 0.0 and global_position.distance_to(target.global_position) < 5.0:
		slam_windup += delta
		visual.call("animate", 0.0, 0.0, false, true)
		if slam_windup >= 0.8:
			if global_position.distance_to(target.global_position) < 4.0:
				target.call("take_damage", 45, self)
			slam_left = 4.0
			slam_windup = 0.0
	else:
		slam_windup = 0.0

func take_damage(amount: int) -> void:
	var was_alive := health > 0
	super.take_damage(amount)
	if was_alive and health <= 0:
		var arena := get_tree().current_scene
		if arena and arena.has_method("final_boss_defeated"):
			arena.call("final_boss_defeated")

func apply_difficulty(_percent: float, _overtime: float = 1.0) -> void:
	pass

func apply_knockback(_origin: Vector3, _force: float) -> void:
	pass
