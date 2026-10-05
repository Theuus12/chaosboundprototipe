extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var eye = load("res://scenes/infernal_eye.tscn").instantiate()
	root.add_child(eye)
	assert(eye.health == 45)
	assert(eye.is_in_group("enemies"))
	assert(eye.is_in_group("infernal_eyes"))
	assert(eye.visual.parts.size() > 25)
	for part in eye.visual.parts:
		assert(absf(part.position.x) < 0.8)
	eye.visual.animate(0.1, 0.0, false, true)
	eye.visual.animate(0.1, 0.0, false, false)
	assert(eye.visual.iris.material_override.emission_enabled)
	print("Infernal eye scene, compact silhouette, animation and hit feedback PASS")
	quit()
