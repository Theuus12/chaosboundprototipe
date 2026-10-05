extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	var player = arena.player
	player.set_physics_process(false)
	var balance = preload("res://scripts/megabonk_balance.gd")
	for weapon in balance.WEAPON_BASE_DAMAGE:
		assert(player.effective_weapon_damage(weapon) == int(balance.WEAPON_BASE_DAMAGE[weapon]))
		for attribute in preload("res://scripts/weapon_upgrades.gd").ATTRIBUTES[weapon]:
			assert(balance.WEAPON_UPGRADES[weapon].has(attribute))
	assert(player.apply_weapon_upgrade(10, {"damage": 1.75, "projectile_speed": 20.0}))
	assert(player.effective_weapon_damage(10) == 11)
	assert(player.apply_upgrade(15, 8.0))
	assert(is_equal_approx(player.tome_bonus(15), 8.0))
	assert(player.apply_upgrade(15, 8.0))
	assert(is_equal_approx(player.tome_bonus(15), 16.64))
	assert(player.effective_weapon_damage(10) == 13)
	assert(player.dagger_bounce_damage() == player.effective_weapon_damage(26))
	assert(player.apply_upgrade(6, 25.0))
	assert(player.max_health == 125)
	assert(player.apply_upgrade(8, 25.0))
	assert(player.max_shield() == 25)
	assert(is_equal_approx(balance.crystal_amount(0, 0), 0.75))
	assert(is_equal_approx(balance.crystal_amount(24, 0), 7.5))
	for kind in preload("res://scripts/tomes.gd").catalog():
		for rarity in range(5):
			assert(is_equal_approx(balance.crystal_amount(kind, rarity), float(balance.CRYSTAL_BASE.get(kind, 8.0)) * balance.RARITY_MULTIPLIERS[rarity] * 0.1))
	player.buff_slots.clear()
	assert(player.apply_upgrade(2, balance.crystal_amount(2, 0)))
	assert(is_equal_approx(player.extra_xp_chance, 0.7))
	assert(player.apply_upgrade(1, balance.crystal_amount(1, 1)))
	assert(player.apply_upgrade(1, balance.crystal_amount(1, 1)))
	assert(is_equal_approx(player.projectile_bonus_tenths / 10.0, 0.25))
	var stats = arena.get_node("StatsMenu")
	stats.refresh_inventory()
	print("Extracted weapon bases, flat upgrades, compound damage, health/shield and UI PASS")
	quit()
