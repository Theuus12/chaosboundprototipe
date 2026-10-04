extends "res://scripts/crystal_slot.gd"

func update_item(player: Node, item: String) -> void:
	for kind in preload("res://scripts/weapon_upgrades.gd").NAMES:
		if item == preload("res://scripts/weapon_upgrades.gd").NAMES[kind]:
			if not textures.has(kind):
				textures[kind] = load(preload("res://scripts/weapon_upgrades.gd").ICON_PATHS[kind])
			icon.texture = textures[kind]
			level_label.text = "Nv. %d" % player.get("weapons")[kind].level
			tooltip_text = "%s\nDano %d" % [item, player.call("effective_weapon_damage", kind)]
			return
	icon.texture = null
	level_label.text = "—" if item.is_empty() else item
	tooltip_text = "Slot de item vazio" if item.is_empty() else item
