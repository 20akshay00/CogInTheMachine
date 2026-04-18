shader_type canvas_item;

uniform float fill_level : hint_range(0.0, 1.0) = 0.5;
uniform float slosh_amount : hint_range(-1.0, 1.0) = 0.0;
uniform float wave_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(0.0, 30.0) = 15.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;
uniform float phase_offset : hint_range(0.0, 100.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);
	
	float tilt = slosh_amount * (uv.x - 0.5);
	
	// Apply phase_offset to TIME so instances aren't synchronized
	float time_val = TIME + phase_offset;
	
	float wave = sin(uv.x * wave_frequency + time_val * wave_speed) * wave_intensity;
	wave += sin(uv.x * wave_frequency * 0.5 - time_val * wave_speed * 0.8) * (wave_intensity * 0.5);
	
	float surface_line = (1.0 - fill_level) + tilt + wave;
	float mask = smoothstep(surface_line, surface_line + 0.01, uv.y);
	
	COLOR = vec4(tex.rgb * tint_color.rgb, mask * tex.a);
}