shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform vec4 overlay_color : source_color = vec4(0.2, 0.8, 0.2, 0.5);

void fragment() {
	ALBEDO = overlay_color.rgb;
	ALPHA = overlay_color.a;
}
