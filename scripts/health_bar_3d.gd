extends Node3D
## Barra que acompanha a camera sem participar da colisao.
var fill: MeshInstance3D
var width: float = 0.9

func _ready() -> void:
	var background := make_quad(Vector2(width + 0.06, 0.14), Color("222733"))
	add_child(background)
	fill = make_quad(Vector2(width, 0.09), Color("73df82"))
	fill.position.z = 0.01
	add_child(fill)

func set_health(value: float, maximum: float) -> void:
	if fill == null:
		return
	var ratio := clampf(value / maxf(maximum, 1.0), 0.0, 1.0)
	fill.scale.x = maxf(ratio, 0.001)
	fill.position.x = -width * (1.0 - ratio) * 0.5
	fill.visible = ratio > 0.0
	var material := fill.material_override as StandardMaterial3D
	material.albedo_color = Color("ed605c") if ratio < 0.3 else Color("73df82")

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_basis = camera.global_basis.orthonormalized()

func make_quad(size: Vector2, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
