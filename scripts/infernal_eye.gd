extends "res://scripts/enemy.gd"
## Reservado para a fase apos a morte do boss final. Sem spawn automatico.

func _ready() -> void:
	max_health = 45
	super._ready()
	add_to_group("infernal_eyes")
	visual.free()
	visual = Node3D.new()
	visual.set_script(preload("res://scripts/infernal_eye_visual.gd"))
	add_child(visual)
	visual.call("animate", 0.0, 0.0, false, false)
	health_bar.position.y = 2.75

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		visual.call("animate", delta, 0.0, false, hit_flash > 0.0)
		return
	super._physics_process(delta)
