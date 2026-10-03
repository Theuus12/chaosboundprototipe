extends RefCounted

const NAMES = ["Branco", "Verde", "Azul", "Roxo", "Dourado"]
const COLORS = [Color("eeeeee"), Color("68d983"), Color("5baeff"), Color("bc80ff"), Color("ffd15b")]
# Pesos separados dos intervalos para permitir um futuro buff de sorte.
const WEIGHTS = [45, 28, 16, 8, 3]
const PERCENT_RANGES = [Vector2i(1, 3), Vector2i(2, 4), Vector2i(4, 6), Vector2i(5, 8), Vector2i(8, 13)]
const QUANTITY_TENTHS = [Vector2i(3, 6), Vector2i(5, 10), Vector2i(8, 13), Vector2i(10, 17), Vector2i(15, 25)]

static func probabilities(luck: float = 0.0) -> Array[float]:
	var result: Array[float] = []
	var total: float = 0.0
	var multiplier := 1.0 + maxf(luck, 0.0) / 100.0
	for i in range(WEIGHTS.size()):
		var weight: float = WEIGHTS[i] * pow(multiplier, i)
		result.append(weight)
		total += weight
	for i in range(result.size()):
		result[i] /= total
	return result

static func roll_rarity(ticket: int = -1, luck: float = 0.0) -> int:
	var roll: float = ticket / 100.0 if ticket >= 0 else randf()
	var cumulative: float = 0.0
	var chances := probabilities(luck)
	for i in range(chances.size()):
		cumulative += chances[i]
		if roll < cumulative - 0.0000001:
			return i
	return 4

static func base_roll_rarity(ticket: int = -1) -> int:
	if ticket < 0:
		ticket = randi_range(0, 99)
	var cumulative := 0
	for i in range(WEIGHTS.size()):
		cumulative += WEIGHTS[i]
		if ticket < cumulative:
			return i
	return 4

static func roll_amount(kind: int, rarity: int) -> float:
	var bounds: Vector2i = QUANTITY_TENTHS[rarity] if kind == 1 else PERCENT_RANGES[rarity]
	var value := randi_range(bounds.x, bounds.y)
	return value / 10.0 if kind == 1 else float(value)
