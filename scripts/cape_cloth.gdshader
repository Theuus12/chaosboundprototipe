shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color : source_color = vec4(0.25, 0.42, 0.1, 1.0);
uniform vec2 bend_0 = vec2(0.0);
uniform vec2 bend_1 = vec2(0.0);
uniform vec2 bend_2 = vec2(0.0);
uniform vec2 bend_3 = vec2(0.0);
uniform vec2 bend_4 = vec2(0.0);

void vertex() {
    float distance_from_shoulder = max(0.0, 1.52 - VERTEX.y);
    vec2 bends[5] = vec2[5](bend_0, bend_1, bend_2, bend_3, bend_4);
    vec3 offset = vec3(0.0);
    for (int i = 0; i < 5; i++) {
        float length_here = clamp(distance_from_shoulder - float(i) * 0.22, 0.0, 0.22);
        offset.z -= sin(bends[i].x) * length_here;
        offset.x += sin(bends[i].y) * length_here;
        offset.y += (1.0 - cos(bends[i].x) * cos(bends[i].y)) * length_here;
    }
    VERTEX += offset;
    int section = int(clamp(floor(distance_from_shoulder / 0.22), 0.0, 4.0));
    float angle = bends[section].x;
    NORMAL.yz = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle))) * NORMAL.yz;
}

void fragment() {
    ALBEDO = cloth_color.rgb;
    ROUGHNESS = 0.95;
}
