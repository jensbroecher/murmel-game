shader_type canvas_item;

uniform float lod: hint_range(0.0, 5.0) = 2.0;
uniform vec4 tint_color: source_color = vec4(1.0, 1.0, 1.0, 0.1);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	vec4 final_color = mix(color, tint_color, tint_color.a);
	// Apply the alpha from the node's texture/stylebox to clip the blur
	COLOR = vec4(final_color.rgb, COLOR.a);
}
