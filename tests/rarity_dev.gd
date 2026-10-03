extends SceneTree
const Rarity = preload("res://scripts/buff_rarity.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var counts := [0, 0, 0, 0, 0]
	for ticket in range(100):
		counts[Rarity.roll_rarity(ticket)] += 1
	assert(counts == Rarity.WEIGHTS)
	for rarity in range(5):
		for i in range(100):
			var percent := Rarity.roll_amount(0, rarity)
			var amount := Rarity.roll_amount(1, rarity)
			assert(percent >= Rarity.PERCENT_RANGES[rarity].x and percent <= Rarity.PERCENT_RANGES[rarity].y)
			assert(amount >= Rarity.QUANTITY_TENTHS[rarity].x / 10.0 and amount <= Rarity.QUANTITY_TENTHS[rarity].y / 10.0)
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var player := arena.get("player") as CharacterBody3D
	player.call("apply_upgrade", 0, 13.0, 4)
	player.call("apply_upgrade", 1, 2.5, 4)
	assert(player.get("attack_speed_bonus") == 13)
	assert(player.get("projectile_bonus_tenths") == 25)
	var stats := arena.get_node("StatsMenu")
	stats.call("toggle")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	stats.call("buff_click", click, 0)
	assert(player.get("attack_speed_bonus") == 13)
	click.ctrl_pressed = true
	stats.call("buff_click", click, 0)
	assert(player.get("attack_speed_bonus") == 14 and player.get("buff_stacks")[0] == 2)
	stats.call("buff_click", click, 1)
	assert(player.get("projectile_bonus_tenths") == 35 and player.get("buff_stacks")[1] == 2)
	assert(paused and stats.get("overlay").visible)
	stats.call("toggle")
	stats.call("buff_click", click, 0)
	assert(player.get("attack_speed_bonus") == 14)
	print("Rarity developer: PASS")
	quit(0)
