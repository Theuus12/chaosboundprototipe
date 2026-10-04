extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var arena := load("res://scenes/arena.tscn").instantiate() as Node3D
	root.add_child(arena)
	current_scene = arena
	var player: Node = arena.get("player")
	player.set_physics_process(false)
	var slot := VBoxContainer.new()
	slot.set_script(load("res://scripts/crystal_slot.gd"))
	root.add_child(slot)
	for kind in preload("res://scripts/tomes.gd").catalog():
		assert(player.BUFF_NAMES[kind].begins_with("Cristal do "))
		player.get("buff_stacks")[kind] = 2
		slot.call("update_buff", player, kind)
		assert(slot.get("icon").texture != null)
		assert(slot.get("level_label").text == "Nv. 2")
		assert(slot.tooltip_text.contains(player.BUFF_NAMES[kind]))
	slot.call("update_buff", player, -1)
	assert(slot.get("icon").texture == null)
	for path in preload("res://scripts/weapon_upgrades.gd").ICON_PATHS.values():
		assert(load(path) is Texture2D)
	var hud := arena.get_node("GameHUD")
	player.call("apply_weapon_upgrade", 11, {"damage": 5.0})
	player.call("apply_weapon_upgrade", 12, {"damage": 5.0})
	hud.call("_process", 0.0)
	for i in range(3):
		assert(hud.get("weapon_slots")[i].get("icon").texture != null)
		assert(hud.get("slots")[i].text.begins_with("Nv. "))
	var stats := arena.get_node("StatsMenu")
	stats.call("refresh_inventory")
	for i in range(3):
		assert(stats.get("weapon_icons")[i].texture != null)
	var menu := arena.get_node("UpgradeMenu")
	menu.call("queue_level", 2)
	for button in menu.get("buttons"):
		assert(button.icon != null)
		assert(button.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT)
	print("Crystal slots: all 23 names, icons, levels and empty slots PASS")
	quit()
