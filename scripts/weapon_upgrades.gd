extends RefCounted
const Rarity = preload("res://scripts/buff_rarity.gd")
const NAMES = {10: "Arco", 11: "Espada", 12: "Aura", 26: "Adaga reversa"}
const ATTRIBUTES = {10: ["projectiles", "speed", "damage"], 11: ["projectiles", "area", "speed", "damage"], 12: ["area", "speed", "damage"], 26: ["projectiles", "projectile_speed", "damage", "bounces"]}
const LABELS = {"projectiles": "Quantidade de projetil", "speed": "Velocidade de ataque", "damage": "Dano", "area": "Area", "projectile_speed": "Velocidade do projétil", "bounces": "Ricochetes"}
const AREA_UPGRADE_MULTIPLIER = 3.0
const ICON_PATHS = {10: "res://assets/ui/weapons/bow.svg", 11: "res://assets/ui/weapons/slash.svg", 12: "res://assets/ui/weapons/aura.svg", 26: "res://assets/ui/weapons/dagger.svg"}

static func roll_stats(weapon: int, rarity: int, count: int = 2) -> Dictionary:
	var pool: Array = ATTRIBUTES[weapon].duplicate()
	pool.shuffle()
	var result := {}
	for i in range(count):
		var attribute: String = pool[i]
		result[attribute] = Rarity.roll_amount(1 if attribute == "projectiles" else 0, rarity)
		if attribute == "area":
			result[attribute] *= AREA_UPGRADE_MULTIPLIER
		if attribute == "bounces":
			result[attribute] = 1.0
	return result

static func describe(stats: Dictionary) -> String:
	var lines: PackedStringArray = []
	for attribute in stats:
		var value := "+%.1f" % stats[attribute] if attribute == "projectiles" else "+%d%%" % int(stats[attribute])
		if attribute == "bounces":
			value = "+%d" % int(stats[attribute])
		lines.append("%s %s" % [LABELS[attribute], value])
	return "\n".join(lines)
