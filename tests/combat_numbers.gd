extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	arena.set_physics_process(false)
	var player: Node = arena.get("player")
	player.set_physics_process(false)
	player.call("take_damage", 15, null, 1.0)
	assert(get_nodes_in_group("combat_numbers").back().get_meta("amount") == 15)
	player.call("heal", 100)
	var healing: Node = get_nodes_in_group("combat_numbers").back()
	assert(healing.get_meta("healing") and healing.get_meta("amount") == 15)
	var count := get_nodes_in_group("combat_numbers").size()
	player.call("heal", 100)
	assert(get_nodes_in_group("combat_numbers").size() == count)
	var enemy := CharacterBody3D.new()
	enemy.set_script(load("res://scripts/enemy.gd"))
	enemy.set("target", player)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.call("take_damage", 1000)
	var damage: Node = get_nodes_in_group("combat_numbers").back()
	assert(damage.get_meta("amount") == 100 and not damage.get_meta("healing"))
	assert(damage.get_parent() == root)
	await create_timer(1.0).timeout
	assert(get_nodes_in_group("combat_numbers").is_empty())
	print("Combat numbers: actual damage, capped healing, lethal hits and cleanup PASS")
	quit()
