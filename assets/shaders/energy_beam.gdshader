shader_type canvas_item;

uniform vec4 beam_color : source_color = vec4(0.3, 0.5, 1.0, 1.0);
uniform float flicker_speed : hint_range(0.0, 50.0) = 20.0;
uniform float core_width : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	float mask = 1.0 - abs(UV.y - 0.5) * 2.0;
	
	float flicker = sin(TIME * flicker_speed + UV.x * 10.0) * 0.1;
	float noise = sin(TIME * flicker_speed * 1.5 - UV.x * 5.0) * 0.05;
	
	float core = smoothstep(1.0 - core_width, 1.0, mask + noise);
	float glow = smoothstep(0.0, 0.8, mask + flicker);
	
	vec3 final_rgb = mix(beam_color.rgb, vec3(1.0), core);
	float final_a = glow * texture(TEXTURE, UV).a;
	
	COLOR = vec4(final_rgb, final_a);
}