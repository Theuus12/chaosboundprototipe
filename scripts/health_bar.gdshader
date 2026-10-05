shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float health_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.45, 0.87, 0.51, 1.0);

void vertex() {
	// Uma única superfície orientada para a câmera, sem planos sobrepostos.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz),
		INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz),
		INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz),
		MODEL_MATRIX[3]);
}

void fragment() {
	bool inside = UV.x > 0.03 && UV.x < 0.97 && UV.y > 0.18 && UV.y < 0.82;
	bool filled = inside && UV.x < 0.03 + 0.94 * health_ratio;
	ALBEDO = filled ? fill_color.rgb : vec3(0.13, 0.15, 0.20);
}
