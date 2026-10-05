extends Node

var saved := false
var player: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = get_parent().get("player")

func save_run() -> void:
	if saved or not is_instance_valid(player):
		return
	saved = true
	preload("res://scripts/personal_ranking.gd").record_run(int(player.get("kills")))

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not player.get("dead") or saved:
		return
	save_run()
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	var button := Button.new()
	button.text = "VOLTAR AO MENU · VER RANKING"
	button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	button.position = Vector2(-230, -100)
	button.size = Vector2(460, 62)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(func(): get_tree().paused = false; get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	layer.add_child(button)
	button.grab_focus()

func _exit_tree() -> void:
	save_run()
