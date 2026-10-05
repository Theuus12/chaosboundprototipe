extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var arena = load("res://scenes/arena.tscn").instantiate()
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	arena.player.set_physics_process(false)
	for base in [9, 15]:
		var enemy := CharacterBody3D.new()
		enemy.set_script(load("res://scripts/enemy.gd"))
		enemy.set("max_health", base)
		enemy.set("target", arena.player)
		arena.add_child(enemy)
		enemy.set_physics_process(false)
		arena.elapsed_time = 0
		enemy.apply_difficulty(0)
		assert(enemy.health == base)
		assert(ceili(float(base) / arena.player.effective_weapon_damage(10)) == (1 if base == 9 else 2))
		enemy.take_damage(3)
		arena.elapsed_time = 600
		enemy.apply_difficulty(0)
		assert(enemy.max_health == base * 2)
		assert(enemy.health == (base - 3) * 2)
		enemy.free()
	print("Goblin 9 HP, skeleton 15 HP; growth preserves damage and species base PASS")
	quit()
