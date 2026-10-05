extends RefCounted
## Extracted base values; rarity scaling is a prototype adaptation.
const WEAPON_BASE_DAMAGE = {10: 9.0, 11: 11.0, 12: 6.0, 26: 9.0}
const WEAPON_UPGRADES = {
	10: {"damage": 1.75, "projectiles": 1.0, "projectile_speed": 20.0, "area": 15.0, "crit_chance": 8.0, "crit_damage": 18.0},
	11: {"damage": 2.0, "projectiles": 1.0, "area": 20.0, "knockback": 25.0},
	12: {"damage": 1.4, "area": 14.0},
	26: {"damage": 2.0, "projectiles": 1.0, "bounces": 1.0, "projectile_speed": 15.0}}
const CRYSTAL_BASE = {0: 7.5, 1: 1.0, 2: 7.0, 3: 3.5, 4: 15.0, 5: 8.0, 6: 25.0, 7: 40.0, 8: 25.0, 9: 10.0, 13: 12.0, 14: 15.0, 15: 8.0, 16: 7.0, 17: 10.0, 18: 15.0, 19: 20.0, 20: 10.0, 21: 15.0, 22: 12.0, 23: 12.0, 24: 75.0}
const FLAT_CRYSTALS = [1, 6, 7, 8, 14]
# Todos os cristais concedem 10% do bonus anterior (reducao de 90%).
const CRYSTAL_EFFECT_SCALE = 0.1
const RARITY_MULTIPLIERS = [1.0, 1.25, 1.5, 2.0, 3.0]
static func crystal_amount(kind: int, rarity: int) -> float:
	return float(CRYSTAL_BASE.get(kind, 8.0)) * RARITY_MULTIPLIERS[rarity] * CRYSTAL_EFFECT_SCALE
static func describe_crystal(kind: int, amount: float) -> String:
	return "+%.2f%s" % [amount, "" if kind in FLAT_CRYSTALS else "%"]
