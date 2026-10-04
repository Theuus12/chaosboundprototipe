extends SceneTree

func _initialize() -> void:
	var cloth := Node.new()
	cloth.set_script(load("res://scripts/cape_cloth.gd"))
	root.add_child(cloth)
	for i in range(120):
		cloth.call("simulate", 1.0 / 60.0, Vector3(0, 0, -9), 0.0, false)
	assert(cloth.get("bends")[4].x > 0.1)
	cloth.call("simulate", 1.0 / 60.0, Vector3(8, 5, 0), 1.0, true)
	for i in range(60):
		cloth.call("simulate", 1.0 / 60.0, Vector3(8, 5, 0), 1.0, true)
	for bend in cloth.get("bends"):
		assert(bend.is_finite())
		assert(absf(bend.y) <= 0.55 and bend.x <= 1.0)
	for i in range(300):
		cloth.call("simulate", 1.0 / 60.0, Vector3.ZERO, 1.0, false)
	assert(absf(cloth.get("bends")[4].x) < 0.05)
	print("Cape cloth: motion response, stability and settling PASS")
	quit()
