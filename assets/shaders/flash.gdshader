shader_type canvas_item;

uniform float flash_intensity : hint_range(0, 1) = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    COLOR = vec4(mix(color.rgb, vec3(1.0), flash_intensity), color.a);
}