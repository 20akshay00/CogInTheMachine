shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0);
uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_thickness : hint_range(0, 10) = 0.3;
uniform bool active = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	if (!active) {
		COLOR = tex_color * tint_color;
	} else {
		vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
		
		float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
		outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
		
		if (tex_color.a <= 0.0) {
			COLOR = vec4(line_color.rgb, clamp(outline, 0.0, 1.0) * line_color.a * tint_color.a);
		} else {
			COLOR = tex_color * tint_color;
		}
	}
}