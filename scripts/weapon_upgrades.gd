extends RefCounted
const Rarity = preload("res://scripts/buff_rarity.gd")
const NAMES = {10: "Arco", 11: "Espada", 12: "Aura", 26: "Adaga reversa"}
const Balance = preload("res://scripts/megabonk_balance.gd")
const ATTRIBUTES = {10: ["damage", "projectiles", "projectile_speed", "area", "crit_chance", "crit_damage"], 11: ["damage", "projectiles", "area", "knockback"], 12: ["area", "damage"], 26: ["projectiles", "projectile_speed", "damage", "bounces"]}
const LABELS = {"projectiles": "Quantidade de projetil", "speed": "Velocidade de ataque", "damage": "Dano", "area": "Area", "projectile_speed": "Velocidade do projétil", "bounces": "Ricochetes"}
const AREA_UPGRADE_MULTIPLIER = 3.0
const ICON_PATHS = {10: "res://assets/ui/weapons/bow.svg", 11: "res://assets/ui/weapons/slash.svg", 12: "res://assets/ui/weapons/aura.svg", 26: "res://assets/ui/weapons/dagger.svg"}

static func roll_stats(weapon: int, rarity: int, count: int = 2) -> Dictionary:
	var pool: Array = ATTRIBUTES[weapon].duplicate()
	pool.shuffle()
	var result := {}
	for i in range(count):
		var attribute: String = pool[i]
		result[attribute] = Balance.WEAPON_UPGRADES[weapon][attribute] * Balance.RARITY_MULTIPLIERS[rarity]
	return result

static func describe(stats: Dictionary) -> String:
	var lines: PackedStringArray = []
	for attribute in stats:
		var value := "+%.2f%s" % [stats[attribute], "" if attribute in ["projectiles", "damage", "bounces"] else "%"]
		if attribute == "bounces":
			value = "+%d" % int(stats[attribute])
		lines.append("%s %s" % [LABELS.get(attribute, {"crit_chance": "Chance crítica", "crit_damage": "Dano crítico", "knockback": "Empurrão"}.get(attribute, attribute)), value])
	return "\n".join(lines)
