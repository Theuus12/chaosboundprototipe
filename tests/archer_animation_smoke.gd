extends SceneTree

func _initialize() -> void:
	call_deferred("check_animation")

func check_animation() -> void:
	var visual := Node3D.new()
	visual.set_script(load("res://scripts/imported_archer_visual.gd"))
	root.add_child(visual)
	for key in ["left_arm", "right_arm", "left_leg", "right_leg", "left_elbow", "right_elbow", "left_knee", "right_knee", "cape"]:
		var pivot: Node3D = visual.get(key)
		if pivot.get_child_count() == 0:
			push_error("No imported geometry attached to " + key)
			quit(1)
			return
	assert(visual.get("left_elbow").get_parent() == visual.get("left_arm"))
	assert(visual.get("right_elbow").get_parent() == visual.get("right_arm"))
	assert(visual.get("left_knee").get_parent() == visual.get("left_leg"))
	assert(visual.get("right_knee").get_parent() == visual.get("right_leg"))
	var max_knee_bend := 0.0
	for i in range(60):
		visual.call("animate", 1.0 / 60.0, 7.0, true, false)
		visual.call("_process", 1.0 / 60.0)
		max_knee_bend = maxf(max_knee_bend, visual.get("left_knee").rotation.x)
	assert(max_knee_bend > 0.4)
	assert(absf(visual.get("left_elbow").rotation.y) > 0.5)
	if visual.get("stride") < 0.9:
		quit(1)
		return
	for i in range(30):
		visual.call("animate", 1.0 / 60.0, 7.0, false, false, 5.0)
		visual.call("_process", 1.0 / 60.0)
	if visual.get("air_pose") < 0.9:
		quit(1)
		return
	assert(visual.get("animation_state") == "jump")
	visual.call("animate", 1.0 / 60.0, 7.0, false, false, -5.0)
	visual.call("_process", 1.0 / 60.0)
	assert(visual.get("animation_state") == "fall")
	visual.call("animate", 1.0 / 60.0, 0.0, true, false, 0.0)
	assert(visual.get("animation_state") == "land")
	for i in range(60):
		visual.call("animate", 1.0 / 60.0, 0.0, true, false)
		visual.call("_process", 1.0 / 60.0)
	if visual.get("air_pose") > 0.01 or visual.get("stride") > 0.01:
		quit(1)
		return
	print("Archer animation: joint hierarchy, knee/elbow motion, run, rise, fall, landing and idle passed.")
	visual.free()
	quit()
