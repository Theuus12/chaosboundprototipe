extends Node3D
var health := 10000

func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)
