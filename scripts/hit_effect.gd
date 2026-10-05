extends Node3D

const HIT_SOUND = preload("res://assets/audio/hit.wav")
const MAX_EFFECTS: int = 18
const MAX_SOUNDS: int = 6
static var spark_mesh: SphereMesh
static var spark_material: StandardMaterial3D

static func show_hit(enemy: Node3D) -> void:
	var tree := enemy.get_tree()
	if tree.get_nodes_in_group("hit_effects").size() >= MAX_EFFECTS:
		return
	var effect := Node3D.new()
	effect.set_script(load("res://scripts/hit_effect.gd"))
	var position := enemy.global_position + Vector3.UP * 0.85
	var player = enemy.get("target")
	if is_instance_valid(player):
		var direction: Vector3 = player.global_position - enemy.global_position
		direction.y = 0.0
		var radius := 0.3
		for child in enemy.get_children():
			if child is CollisionShape3D and child.shape is CapsuleShape3D:
				radius = child.shape.radius
		position += direction.normalized() * radius
	enemy.get_parent().add_child(effect)
	effect.global_position = position

func _ready() -> void:
	add_to_group("hit_effects")
	if spark_material == null:
		spark_material = StandardMaterial3D.new()
		spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark_material.albedo_color = Color("ffdc85")
		spark_material.emission_enabled = true
		spark_material.emission = Color("ffc15c")
		spark_mesh = SphereMesh.new()
		spark_mesh.radius = 0.045
		spark_mesh.height = 0.09
		spark_mesh.radial_segments = 6
		spark_mesh.rings = 3
		spark_mesh.material = spark_material
	var particles := CPUParticles3D.new()
	particles.mesh = spark_mesh
	particles.amount = 9
	particles.lifetime = 0.23
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 1.0
	particles.initial_velocity_max = 2.8
	particles.gravity = Vector3(0, -3.5, 0)
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.2
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var size_curve := Curve.new()
	size_curve.add_point(Vector2(0, 1))
	size_curve.add_point(Vector2(1, 0))
	particles.scale_amount_curve = size_curve
	add_child(particles)
	particles.emitting = true
	if get_tree().get_nodes_in_group("hit_sounds").size() < MAX_SOUNDS:
		var sound := AudioStreamPlayer3D.new()
		sound.stream = HIT_SOUND
		sound.volume_db = -13.0
		sound.pitch_scale = randf_range(0.90, 1.12)
		sound.max_distance = 35.0
		sound.unit_size = 5.0
		sound.add_to_group("hit_sounds")
		add_child(sound)
		sound.finished.connect(sound.queue_free)
		sound.play()
	var timer := Timer.new()
	timer.wait_time = 0.45
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
