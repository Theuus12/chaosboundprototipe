extends RefCounted

# IDs 10–12 permanecem reservados para as armas.
const NAMES = {
	0: "Cristal do Ataque",
	1: "Cristal do Projétil",
	2: "Cristal do Conhecimento",
	3: "Cristal do Desafio",
	4: "Cristal do Movimento",
	5: "Cristal do Destino",
	6: "Cristal do Vigor",
	7: "Cristal do Renascimento",
	8: "Cristal do Escudo",
	9: "Cristal do Desvio",
	13: "Cristal do Defensor",
	14: "Cristal do Espinho",
	15: "Cristal do Dano",
	16: "Cristal do Acerto Crítico",
	17: "Cristal do Tamanho",
	18: "Cristal do Tempo",
	19: "Cristal do Impacto",
	20: "Cristal do Sangue",
	21: "Cristal do Projétil Veloz",
	22: "Cristal do Ouro",
	23: "Cristal do Metal Prateado",
	24: "Cristal do Magnetismo",
	25: "Cristal do Caos"
}
const DESCRIPTIONS = {
	0: "Aumenta a frequência dos ataques", 1: "Adiciona flechas à salva simultânea do arco e projéteis às outras armas",
	2: "Aumenta as chances de drop e de uma orb maior com o dobro de XP", 3: "Aumenta vida, velocidade e quantidade de monstros",
	4: "Aumenta a velocidade de movimento", 5: "Favorece raridades maiores",
	6: "Adiciona vida máxima e cura a vida adicionada",
	7: "Regenera esta quantidade de vida por minuto",
	8: "Adiciona pontos de escudo; recarrega após 5 segundos sem dano",
	9: "Chance de evitar completamente um ataque (máximo 75%)",
	13: "Armadura: redução = armadura / (100 + armadura)",
	14: "Causa esta quantidade de dano ao agressor quando atingido",
	15: "Multiplica o dano de todas as armas; bônus acumulam multiplicativamente", 16: "Chance de crítico; acima de 100% permite críticos de níveis maiores",
	17: "Aumenta a área dos ataques e o tamanho das flechas",
	18: "Aumenta a duração das flechas e do efeito visual dos cortes",
	19: "Aumenta o empurrão dos ataques; concede empurrão inicial",
	20: "Recupera esta porcentagem do dano efetivamente causado",
	21: "Aumenta a velocidade das flechas", 22: "Aumenta o valor das moedas coletadas",
	23: "Aumenta o valor das moedas coletadas", 24: "Aumenta o raio de atração de XP e moedas",
	25: "Melhora um atributo aleatório a cada escolha; resultado visível no Esc",
	27: "Aumenta o multiplicador de dano dos acertos críticos",
	28: "Aumenta a XP das orbes recolhidas pelo power-up ímã",
	29: "Aumenta o dano contra elites e bosses",
	30: "Aumenta a altura do salto"
}

static func catalog() -> Array[int]:
	var result: Array[int] = []
	result.assign(NAMES.keys())
	return result

static func is_weapon(kind: int) -> bool:
	return kind in [10, 11, 12, 26]
