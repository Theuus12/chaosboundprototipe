extends Node3D
## Barra que acompanha a camera sem participar da colisao.
var fill: MeshInstance3D
var width: float = 0.9
var bar_material: ShaderMaterial
@export var fill_color := Color("73df82")
@export var low_fill_color := Color("ed605c")

func _ready() -> void:
	fill = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width + 0.06, 0.14)
	fill.mesh = mesh
	bar_material = ShaderMaterial.new()
	bar_material.shader = preload("res://scripts/health_bar.gdshader")
	fill.material_override = bar_material
	fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fill.visibility_range_end = 65.0
	add_child(fill)

func set_health(value: float, maximum: float) -> void:
	if fill == null:
		return
	var ratio := clampf(value / maxf(maximum, 1.0), 0.0, 1.0)
	fill.visible = ratio > 0.0
	bar_material.set_shader_parameter("health_ratio", ratio)
	bar_material.set_shader_parameter("fill_color", low_fill_color if ratio < 0.3 else fill_color)
