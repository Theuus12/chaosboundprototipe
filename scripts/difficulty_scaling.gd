extends RefCounted
## CombatScaling native constants: HP .10, damage .028, speed .025 per minute.
## Stage, curse and spawn adaptations belong to our single ten-minute map.
static func multipliers(elapsed: float, curse_percent: float = 0.0) -> Dictionary:
	var minutes := maxf(0.0, elapsed) / 60.0
	var overtime := maxf(0.0, minutes - 10.0)
	var curse := 1.0 + maxf(0.0, curse_percent) / 100.0
	return {
		"health": (1.0 + minutes * 0.10 * curse + (pow(4.0, minf(overtime, 10.0)) - 1.0)) * curse,
		"damage": (1.0 + minutes * 0.028 * curse + (pow(2.0, minf(overtime, 10.0)) - 1.0)) * curse,
		"speed": (1.0 + minutes * 0.025 * curse) * curse,
		"knockback": 1.0 + minutes * 0.028 * curse
	}
