extends SceneTree

func _initialize() -> void:
	var stats = preload("res://scripts/combat_stats.gd")
	assert(stats.damage(100, 0, 0) == 100)
	assert(stats.damage(30, 0, 0) == 30)
	assert(stats.damage(100, 50, 50) == 225)
	assert(stats.damage(30, 50, 50) == 68)
	assert(stats.critical_multiplier(0, 0) == 1.0)
	assert(stats.critical_multiplier(50, 0.49) == 2.0)
	assert(stats.critical_multiplier(50, 0.5) == 1.0)
	assert(stats.critical_multiplier(100, 0.99) == 2.0)
	assert(stats.critical_multiplier(150, 0.49) == 4.0)
	assert(stats.critical_multiplier(150, 0.5) == 2.0)
	assert(stats.critical_multiplier(200, 0.99) == 4.0)
	assert(stats.critical_multiplier(300, 0.99) == 6.25)
	print("Combat modifier layers and critical tiers PASS")
	quit()
