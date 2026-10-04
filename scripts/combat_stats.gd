extends RefCounted
## Weapon upgrades and global crystals belong to separate modifier layers.
static func damage(base: float, weapon_percent: float, global_percent: float) -> int:
	return maxi(0, roundi(base * maxf(0.0, 1.0 + weapon_percent / 100.0) * maxf(0.0, 1.0 + global_percent / 100.0)))

static func critical_multiplier(chance_percent: float, roll: float) -> float:
	var chance := maxf(0.0, chance_percent / 100.0)
	var tier := floori(chance)
	if roll < chance - tier:
		tier += 1
	if tier == 0:
		return 1.0
	if tier == 1:
		return 2.0
	return 1.0 + tier + pow(tier * 0.5, 2.0)
