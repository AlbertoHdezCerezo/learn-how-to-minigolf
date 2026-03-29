shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_test_disabled;

uniform vec4 albedo : source_color = vec4(1.0, 1.0, 1.0, 0.9);

void fragment() {
	ALBEDO = albedo.rgb;
	ALPHA = albedo.a;
}
