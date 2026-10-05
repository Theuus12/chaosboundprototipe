extends "res://scripts/enemy.gd"

@export var attack_range: float = 12.0
@export var attack_interval: float = 2.5
var cast_left := 1.5
var cast_windup := 0.0

func _ready() -> void:
	max_health = 30
	super._ready()
	add_to_group("liches")
	visual.free()
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/lich_visual.gd"))
	add_child(visual)
	health_bar.position.y = 2.9

func has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.8, target.global_position + Vector3.UP, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(delta: float) -> void:
	if health <= 0 or not is_instance_valid(target) or target.get("dead"):
		return
	var offset := target.global_position - global_position
	offset.y = 0
	var distance := offset.length()
	var can_cast := distance <= attack_range and has_line_of_sight()
	if not can_cast:
		cast_windup = 0.0
		visual.set("casting", false)
		super._physics_process(delta)
		return
	hit_flash = maxf(0.0, hit_flash - delta)
	velocity.x = knockback.x
	velocity.z = knockback.z
	if distance < 6.0:
		velocity += -offset.normalized() * move_speed * 0.6
	knockback = knockback.move_toward(Vector3.ZERO, delta * 18.0)
	if not is_on_floor():
		velocity.y -= 28.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if offset.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-offset.x, -offset.z), minf(delta * 6.0, 1.0))
	cast_left -= delta
	if cast_left <= 0.0:
		cast_windup += delta
		visual.set("casting", true)
		if cast_windup >= 0.65:
			fire()
			cast_left = attack_interval
			cast_windup = 0.0
	else:
		visual.set("casting", false)
	visual.call("animate", delta, velocity.length(), false, hit_flash > 0.0)

func fire() -> void:
	var origin := global_position + Vector3.UP * 1.8 + (-global_basis.z) * 0.65
	var projectile := Node3D.new()
	projectile.set_script(preload("res://scripts/lich_fireball.gd"))
	projectile.set("direction", (target.global_position + Vector3.UP * 0.9 - origin).normalized())
	projectile.set("damage", contact_damage)
	projectile.set("target", target)
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
