extends Node
## Damped spring strips drive continuous vertex bending; shoulders stay pinned.
var bends: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var speeds: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var materials: Array[ShaderMaterial] = []
var previous_velocity := Vector3.ZERO
var previous_heading: float = 0.0
var initialized: bool = false
var elapsed: float = 0.0

func setup(cape_mesh: MeshInstance3D) -> void:
	# The dummy renderer cannot store shader parameters; simulation still runs.
	if DisplayServer.get_name() == "headless":
		return
	var shader := load("res://scripts/cape_cloth.gdshader") as Shader
	for surface in range(cape_mesh.mesh.get_surface_count()):
		var source := cape_mesh.get_active_material(surface) as StandardMaterial3D
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("cloth_color", source.albedo_color if source != null else Color("426a24"))
		cape_mesh.set_surface_override_material(surface, material)
		materials.append(material)

func simulate(delta: float, velocity: Vector3, heading: float, airborne: bool) -> void:
	if delta <= 0.0:
		return
	var dt := minf(delta, 0.05)
	if not initialized:
		previous_velocity = velocity
		previous_heading = heading
		initialized = true
	var acceleration := (velocity - previous_velocity) / maxf(delta, 0.001)
	var turn := clampf(wrapf(heading - previous_heading, -PI, PI) / maxf(delta, 0.001), -8.0, 8.0)
	previous_velocity = velocity
	previous_heading = heading
	var local_accel := Basis(Vector3.UP, heading).inverse() * acceleration
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var steps := ceili(dt / (1.0 / 120.0))
	var step := dt / steps
	for iteration in range(steps):
		elapsed += step
		for i in range(5):
			var softness := float(i + 1) / 5.0
			var trail := minf(horizontal_speed / 14.0, 1.0) * (0.35 + softness * 0.40)
			var gust := sin(elapsed * 4.2 - i * 0.9) * (0.025 + horizontal_speed * 0.012) * softness
			var target := Vector2(trail + gust + clampf(-local_accel.z * 0.006 + absf(velocity.y) * 0.008, -0.16, 0.22), clampf(-turn * 0.05 - local_accel.x * 0.006, -0.30, 0.30))
			if airborne:
				target.x += 0.24 * softness
			if i > 0:
				target = target.lerp(bends[i - 1], 0.22)
			var stiffness := lerpf(32.0, 10.0, softness)
			speeds[i] += ((target - bends[i]) * stiffness - speeds[i] * 3.3) * step
			bends[i] += speeds[i] * step
			bends[i].x = clampf(bends[i].x, -0.20, 1.0)
			bends[i].y = clampf(bends[i].y, -0.55, 0.55)
	for material in materials:
		for i in range(5):
			material.set_shader_parameter("bend_%d" % i, bends[i])
