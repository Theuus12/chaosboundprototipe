extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var hud := CanvasLayer.new()
	hud.set_script(load("res://scripts/boss_health_hud.gd"))
	root.add_child(hud)
	var boss := Node.new()
	boss.set_script(load("res://tests/boss_health_stub.gd"))
	root.add_child(boss)
	boss.add_to_group("bosses")
	hud.call("_process", 0.0)
	assert(hud.rows.size() == 1)
	var row = hud.rows[boss.get_instance_id()]
	assert(row.get_child(1).value == 100)
	boss.health = 35
	hud.call("_process", 0.0)
	assert(row.get_child(1).value == 35)
	boss.health = 0
	hud.call("_process", 0.0)
	assert(hud.rows.is_empty())
	assert(not row.visible)
	print("Boss health tracks damage and disappears on death PASS")
	quit()
