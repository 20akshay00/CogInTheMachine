shader_type canvas_item;

uniform float fill_level : hint_range(0.0, 1.0) = 0.5;
uniform float slosh_amount : hint_range(-1.0, 1.0) = 0.0;
uniform float wave_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(0.0, 30.0) = 15.0;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;
uniform float phase_offset : hint_range(0.0, 100.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pixel_resolution : hint_range(10.0, 200.0, 1.0) = 48.0;

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);
	
	float stepped_x = floor(uv.x * pixel_resolution) / pixel_resolution;
	float stepped_y = floor(uv.y * pixel_resolution) / pixel_resolution;
	
	float tilt = slosh_amount * (stepped_x - 0.5);
	float time_val = TIME + phase_offset;
	
	float wave = sin(stepped_x * wave_frequency + time_val * wave_speed) * wave_intensity;
	wave += sin(stepped_x * wave_frequency * 0.5 - time_val * wave_speed * 0.8) * (wave_intensity * 0.5);
	
	float surface_line = (1.0 - fill_level) + tilt + wave;
	float mask = step(surface_line, stepped_y);
	
	COLOR = vec4(tex.rgb * tint_color.rgb, mask * tex.a);
}