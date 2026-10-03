extends RefCounted
const Rarity = preload("res://scripts/buff_rarity.gd")
const NAMES = {10: "Arco", 11: "Corte frontal", 12: "Aura"}
const ATTRIBUTES = {10: ["projectiles", "speed", "damage"], 11: ["projectiles", "area", "speed", "damage"], 12: ["area", "speed", "damage"]}
const LABELS = {"projectiles": "Quantidade de projetil", "speed": "Velocidade de ataque", "damage": "Dano", "area": "Area"}

static func roll_stats(weapon: int, rarity: int, count: int = 2) -> Dictionary:
	var pool: Array = ATTRIBUTES[weapon].duplicate()
	pool.shuffle()
	var result := {}
	for i in range(count):
		var attribute: String = pool[i]
		result[attribute] = Rarity.roll_amount(1 if attribute == "projectiles" else 0, rarity)
	return result

static func describe(stats: Dictionary) -> String:
	var lines: PackedStringArray = []
	for attribute in stats:
		var value := "+%.1f" % stats[attribute] if attribute == "projectiles" else "+%d%%" % int(stats[attribute])
		lines.append("%s %s" % [LABELS[attribute], value])
	return "\n".join(lines)
