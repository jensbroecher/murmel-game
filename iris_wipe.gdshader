shader_type canvas_item;

uniform float radius : hint_range(-0.5, 1.5) = 1.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = FRAGCOORD.xy / resolution.xy;
	
	float aspect = resolution.x / resolution.y;
	vec2 diff = uv - center;
	diff.x *= aspect;
	
	float dist = length(diff);
	
	// smoothstep for anti-aliasing
	// If dist < radius, alpha is 0 (transparent hole)
	// If dist > radius, alpha is 1 (black mask)
	float alpha = smoothstep(radius, radius + 0.2, dist);
	
	COLOR = vec4(color.rgb, alpha);
}
