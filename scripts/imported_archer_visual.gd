extends Node3D
## Blender character exported to glTF; gameplay faces negative Z.

var model: Node3D
var phase: float = 0.0
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var cape: Node3D
var stride: float = 0.0
var air_pose: float = 0.0
var target_speed: float = 0.0
var target_grounded: bool = true
var target_dashing: bool = false
var cadence: float = 5.0
var elapsed: float = 0.0
var landing: float = 0.0
var was_grounded: bool = true
var left_elbow: Node3D
var right_elbow: Node3D
var left_knee: Node3D
var right_knee: Node3D
var vertical_speed: float = 0.0
var animation_state: String = "idle"
var falling_blend: float = 0.0
var cloth: Node

func joint(joint_name: String, origin: Vector3, prefixes: Array[String], parent_joint: Node3D = null) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = joint_name
	model.add_child(pivot)
	pivot.position = origin
	for child in model.get_children():
		if child == pivot:
			continue
		for prefix in prefixes:
			if String(child.name).begins_with(prefix.replace(".", "_")):
				child.reparent(pivot, true)
				break
	if parent_joint != null:
		pivot.reparent(parent_joint, true)
	return pivot

func _ready() -> void:
	model = preload("res://assets/characters/archer/archer.glb").instantiate()
	model.rotation.y = PI
	add_child(model)
	left_arm = joint("LeftShoulder", Vector3(-0.24, 1.42, 0), ["Sleeve.L", "Sleeve trim.L", "Sleeve trim leather.L", "Arm.L"])
	right_arm = joint("RightShoulder", Vector3(0.24, 1.42, 0), ["Sleeve.R", "Sleeve trim.R", "Sleeve trim leather.R", "Arm.R"])
	left_elbow = joint("LeftElbow", Vector3(-0.59, 1.42, 0), ["Elbow.L", "Forearm.L", "Bracer.L", "Glove.L", "Fingers.L", "Thumb.L"], left_arm)
	right_elbow = joint("RightElbow", Vector3(0.59, 1.42, 0), ["Elbow.R", "Forearm.R", "Bracer.R", "Glove.R", "Fingers.R", "Thumb.R"], right_arm)
	left_leg = joint("LeftHip", Vector3(-0.17, 0.91, 0), ["Thigh.L"])
	right_leg = joint("RightHip", Vector3(0.17, 0.91, 0), ["Thigh.R"])
	left_knee = joint("LeftKnee", Vector3(-0.20, 0.54, 0), ["Knee.L", "Shin.L", "Shin ankle band.L", "Boot cuff.L", "Boot cuff flap.L", "Boot.L", "Sole.L"], left_leg)
	right_knee = joint("RightKnee", Vector3(0.20, 0.54, 0), ["Knee.R", "Shin.R", "Shin ankle band.R", "Boot cuff.R", "Boot cuff flap.R", "Boot.R", "Sole.R"], right_leg)
	cape = joint("CapeShoulders", Vector3(0, 1.52, -0.15), ["Jagged cape"])
	cloth = Node.new()
	cloth.set_script(preload("res://scripts/cape_cloth.gd"))
	add_child(cloth)
	for child in cape.get_children():
		if child is MeshInstance3D:
			cloth.call("setup", child)
	left_arm.rotation.z = 1.28
	right_arm.rotation.z = -1.28

func animate(_delta: float, speed: float, grounded: bool, dashing: bool, rise_speed: float = 0.0) -> void:
	target_speed = speed
	target_grounded = grounded
	target_dashing = dashing
	vertical_speed = rise_speed
	if grounded and not was_grounded:
		landing = 1.0
	was_grounded = grounded
	if not grounded:
		animation_state = "jump" if vertical_speed > 0.1 else "fall"
	elif landing > 0.12:
		animation_state = "land"
	else:
		animation_state = "run" if speed > 0.2 else "idle"

func _process(delta: float) -> void:
	if not is_instance_valid(model):
		return
	# Pose updates follow rendered frames; exponential damping works at any FPS.
	var blend := 1.0 - exp(-delta * 10.0)
	var pose_blend := 1.0 - exp(-delta * 15.0)
	elapsed += delta
	cadence = lerpf(cadence, 5.0 + minf(target_speed, 14.0) * 0.65, blend)
	phase = fmod(phase + delta * cadence, TAU)
	stride = lerpf(stride, minf(target_speed / 7.0, 1.0) if target_grounded else 0.0, blend)
	air_pose = lerpf(air_pose, 0.0 if target_grounded else 1.0, blend)
	falling_blend = lerpf(falling_blend, 1.0 if vertical_speed <= 0.1 and not target_grounded else 0.0, blend)
	landing *= exp(-delta * 14.0)
	var swing := sin(phase) * stride
	left_leg.rotation.x = lerpf(left_leg.rotation.x, swing * 0.90 - air_pose * 1.00 + falling_blend * 0.25 - landing * 0.38, pose_blend)
	right_leg.rotation.x = lerpf(right_leg.rotation.x, -swing * 0.90 - air_pose * 0.65 + falling_blend * 0.22 - landing * 0.38, pose_blend)
	# Knees fold during recovery, then extend for the next footfall.
	var left_fold := pow(maxf(0.0, sin(phase - 0.6)), 2.0) * stride
	var right_fold := pow(maxf(0.0, sin(phase + PI - 0.6)), 2.0) * stride
	left_knee.rotation.x = lerpf(left_knee.rotation.x, 0.04 + left_fold * 1.35 + air_pose * 1.10 - falling_blend * 0.40 + landing * 0.65, pose_blend)
	right_knee.rotation.x = lerpf(right_knee.rotation.x, 0.04 + right_fold * 1.35 + air_pose * 0.85 - falling_blend * 0.30 + landing * 0.65, pose_blend)
	var arm_swing := sin(phase - 0.22) * stride
	left_arm.rotation.x = lerpf(left_arm.rotation.x, -arm_swing * 0.65 - air_pose * 0.65, pose_blend)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, arm_swing * 0.65 - air_pose * 0.65, pose_blend)
	left_arm.rotation.z = lerpf(left_arm.rotation.z, 1.28 - air_pose * 0.55, pose_blend)
	right_arm.rotation.z = lerpf(right_arm.rotation.z, -1.28 + air_pose * 0.55, pose_blend)
	left_elbow.rotation.y = lerpf(left_elbow.rotation.y, 0.14 + stride * 0.85 + arm_swing * 0.12 + air_pose * 0.45, pose_blend)
	right_elbow.rotation.y = lerpf(right_elbow.rotation.y, -(0.14 + stride * 0.85 - arm_swing * 0.12 + air_pose * 0.45), pose_blend)
	# A cosine bounce has no sharp cusp at each footfall.
	var bounce := (1.0 - cos(phase * 2.0)) * stride * 0.032
	var breathing := sin(elapsed * 2.2) * (1.0 - stride) * (1.0 - air_pose) * 0.004
	model.position.y = lerpf(model.position.y, bounce + breathing - landing * 0.060, pose_blend)
	model.rotation.x = lerpf(model.rotation.x, stride * 0.14 - air_pose * 0.06 + landing * 0.04, blend)
	model.rotation.z = lerpf(model.rotation.z, sin(phase) * stride * 0.032, blend)
	var body := get_parent() as CharacterBody3D
	var cloth_velocity := body.velocity if body != null else Vector3(0.0, vertical_speed, -target_speed)
	cloth.call("simulate", delta, cloth_velocity, global_rotation.y, not target_grounded)
	rotation.x = lerpf(rotation.x, -0.3 if target_dashing else 0.0, blend)
