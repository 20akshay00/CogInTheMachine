shader_type canvas_item;

uniform float shake_intensity : hint_range(0.0, 0.1) = 0.0;
uniform float shake_speed : hint_range(0.0, 100.0) = 20.0;
uniform bool pixel_perfect = true;
uniform float pixel_size = 32.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

float random(float seed) {
	return fract(sin(seed) * 43758.5453123);
}

void fragment() {
	float time_step = floor(TIME * shake_speed);
	vec2 offset = vec2(
		random(time_step) * 2.0 - 1.0,
		random(time_step + 1.0) * 2.0 - 1.0
	) * shake_intensity;

	if (pixel_perfect) {
		offset = floor(offset * pixel_size) / pixel_size;
	}

	COLOR = texture(SCREEN_TEXTURE, SCREEN_UV + offset);
}