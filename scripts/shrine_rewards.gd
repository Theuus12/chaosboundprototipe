extends RefCounted
const Balance = preload("res://scripts/megabonk_balance.gd")
const CATALOG: Array[int] = [15, 8, 24, 27, 5, 1, 7, 19, 3, 20, 28, 29, 18, 30, 4, 31]
const NAMES = {15: "Dano", 8: "Escudo", 24: "Raio de coleta", 27: "Dano crítico", 5: "Sorte", 1: "Projétil extra", 7: "Regeneração de vida", 19: "Empurrão", 3: "Dificuldade", 20: "Roubo de vida", 28: "Power-up", 29: "Dano em elites", 18: "Duração", 30: "Altura do pulo", 4: "Velocidade de movimento", 31: "Pulo extra"}
const DESCRIPTIONS = {15: "Aumenta o dano de todas as armas", 8: "Absorve dano antes da vida", 24: "Aumenta o alcance de coleta", 27: "Aumenta o dano dos acertos críticos", 5: "Favorece raridades maiores", 1: "Adiciona projéteis às armas", 7: "Regenera HP por minuto", 19: "Aumenta a força de empurrão", 3: "Aumenta a dificuldade dos inimigos", 20: "Cura uma porcentagem do dano causado", 28: "Aumenta a XP recolhida pelo ímã", 29: "Aumenta o dano contra elites e bosses", 18: "Aumenta a duração dos efeitos", 30: "Aumenta a altura de cada salto", 4: "Aumenta a velocidade do personagem", 31: "Adiciona um salto no ar; recarrega ao pousar"}
const AMOUNTS = {8: 5.0, 24: 20.0, 27: 10.0, 5: 5.0, 1: 1.0, 7: 20.0, 19: 10.0, 3: 8.0, 20: 6.0, 28: 10.0, 29: 10.0, 18: 8.0, 30: 10.0, 4: 8.0}

static func roll(kind: int, rarity: int) -> float:
	if kind == 31:
		return 1.0
	var amount: float = randf_range(10.0, 12.0) if kind == 15 else AMOUNTS[kind]
	# Projéteis são sempre unidades inteiras.
	return float(maxi(1, floori(Balance.RARITY_MULTIPLIERS[rarity]))) if kind == 1 else amount * Balance.RARITY_MULTIPLIERS[rarity]

static func describe(kind: int, amount: float) -> String:
	return "+%.2f%s" % [amount, "" if kind in [1, 7, 8, 31] else "%"]
