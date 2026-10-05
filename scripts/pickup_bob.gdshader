shader_type spatial;
uniform vec4 orb_color : source_color;
void vertex() {
	VERTEX.y += sin(TIME * 3.0 + INSTANCE_CUSTOM.x) * 0.06;
}
void fragment() {
	ALBEDO = orb_color.rgb;
	EMISSION = orb_color.rgb * 0.7;
	ROUGHNESS = 1.0;
}
