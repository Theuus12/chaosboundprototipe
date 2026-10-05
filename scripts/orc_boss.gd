extends "res://scripts/enemy.gd"
@export var orc_rank: int = 2
var display_name: String = "Chefe Orc"
var body_height: float = 10.9

func _ready() -> void:
	max_health = [2500, 7500, 15000][orc_rank]
	display_name = ["Soldado Orc", "Comandante Orc", "Chefe Orc"][orc_rank]
	body_height = 10.9 * [0.25, 0.5, 1.0][orc_rank]
	contact_damage = 30
	move_speed = 2.8
	super._ready()
	add_to_group("bosses")
	visual.queue_free()
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/goblin_visual.gd"))
	visual.set("model_path", ["res://assets/characters/orc_soldier/orc_soldier.glb", "res://assets/characters/orc_commander/orc_commander.glb", "res://assets/characters/orc_boss/orc_boss.glb"][orc_rank])
	visual.scale = Vector3.ONE * (body_height / 1.89)
	add_child(visual)
	for child in get_children():
		if child is CollisionShape3D:
			child.shape = child.shape.duplicate()
			child.shape.radius = body_height * 2.0 / 10.9
			child.shape.height = body_height
			child.position.y = body_height / 2.0
	# Giant can traverse the forest without using narrow goblin navigation paths.
	collision_mask = 2 | 4
	health_bar.position.y = body_height + 0.5
	health_bar.scale = Vector3.ONE * (1.0 + orc_rank)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or target.get("dead"):
		return
	hit_flash = maxf(0.0, hit_flash - delta)
	var direction := target.global_position - global_position
	direction.y = 0.0
	velocity = direction.normalized() * move_speed
	if direction.length() < 0.6 + body_height * 2.0 / 10.9:
		velocity = Vector3.ZERO
		if target.global_position.y < body_height:
			target.call("take_damage", contact_damage, self)
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 3.0, 1.0))
	move_and_slide()
	global_position.y = 0.0
	visual.call("animate", delta, velocity.length(), false, hit_flash > 0.0)

func apply_difficulty(_total_percent: float, _overtime_multiplier: float = 1.0) -> void:
	pass

func apply_knockback(_origin: Vector3, _force: float) -> void:
	pass
