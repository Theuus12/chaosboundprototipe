extends "res://scripts/enemy.gd"

func _ready() -> void:
	max_health = 100000
	contact_damage = 30
	move_speed = 2.8
	super._ready()
	add_to_group("bosses")
	visual.queue_free()
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/goblin_visual.gd"))
	visual.set("model_path", "res://assets/characters/orc_boss/orc_boss.glb")
	visual.scale = Vector3.ONE * (10.9 / 1.89)
	add_child(visual)
	for child in get_children():
		if child is CollisionShape3D:
			child.shape = child.shape.duplicate()
			child.shape.radius = 2.0
			child.shape.height = 10.9
			child.position.y = 5.45
	# Giant can traverse the forest without using narrow goblin navigation paths.
	collision_mask = 2
	health_bar.position.y = 11.4
	health_bar.scale = Vector3.ONE * 3.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.get("dead"):
		return
	hit_flash = maxf(0.0, hit_flash - delta)
	var direction := target.global_position - global_position
	direction.y = 0.0
	velocity = direction.normalized() * move_speed
	if direction.length() < 3.0:
		velocity = Vector3.ZERO
		if target.global_position.y < 10.9:
			target.call("take_damage", contact_damage, self)
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 3.0, 1.0))
	move_and_slide()
	global_position.y = 0.0
	visual.call("animate", delta, velocity.length(), false, hit_flash > 0.0)

func apply_difficulty(_total_percent: int, _overtime_multiplier: float = 1.0) -> void:
	pass

func apply_knockback(_origin: Vector3, _force: float) -> void:
	pass
