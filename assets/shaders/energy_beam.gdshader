shader_type canvas_item;

uniform vec4 beam_color : source_color = vec4(0.3, 0.5, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float thickness : hint_range(0.0, 1.5) = 0.8;
uniform float speed : hint_range(0.0, 50.0) = 15.0;
uniform float wave_freq : hint_range(0.0, 50.0) = 10.0;
uniform float wave_amp : hint_range(0.0, 0.5) = 0.1;
uniform float pulse_freq : hint_range(0.0, 20.0) = 5.0;
uniform float pixel_size = 32.0;

void fragment() {
	vec2 uv = floor(UV * pixel_size) / pixel_size;
	float time_step = floor(TIME * speed) / speed;
	
	float wave = sin(uv.x * wave_freq - time_step * speed) * wave_amp;
	float dist = abs(uv.y - 0.5 + wave) * 2.0;
	
	float pulse = step(0.6, sin(uv.x * pulse_freq - time_step * speed * 1.5));
	float beam_mask = step(dist, thickness);
	float core_mask = step(dist, thickness * 0.3);
	
	vec4 final_color = mix(beam_color, core_color, core_mask);
	final_color = mix(final_color, core_color, pulse * beam_mask * 0.5);
	
	float alpha = beam_mask * texture(TEXTURE, uv).a;
	COLOR = vec4(final_color.rgb, alpha);
}