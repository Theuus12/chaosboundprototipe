extends "res://scripts/enemy.gd"
## Antigo primeiro boss, agora uma elite comum do trecho de 3 a 5 minutos.

func _ready() -> void:
	max_health = 150
	model_path = "res://assets/characters/orc_soldier/orc_soldier.glb"
	super._ready()
	add_to_group("orc_soldiers")
	add_to_group("elites")
	visual.scale = Vector3.ONE * (2.725 / 1.89)
	health_bar.position.y = 3.0
	for child in get_children():
		if child is CollisionShape3D:
			child.shape.height = 2.725
			child.shape.radius = 0.5
			child.position.y = 2.725 / 2.0
