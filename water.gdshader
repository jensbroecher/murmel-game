shader_type spatial;

uniform vec4 albedo : source_color = vec4(0.0, 0.2, 0.4, 0.8);
uniform float metallic : hint_range(0.0, 1.0) = 0.8;
uniform float roughness : hint_range(0.0, 1.0) = 0.2;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;

uniform float fade_start : hint_range(0.0, 500.0) = 150.0;
uniform float fade_range : hint_range(0.0, 500.0) = 100.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	
	vec3 normal_blend = mix(texture(texture_normal, UV * 125.0 + time).rgb, texture(texture_normal2, UV * 125.0 + time2).rgb, 0.5);
	
	ALBEDO = albedo.rgb;
	METALLIC = 1.0; // High metallic for strong reflections
	ROUGHNESS = 0.02; // Very low roughness for sharp sky reflection
	NORMAL_MAP = normal_blend;
	
	// Distance fade logic calculated per pixel
	float world_dist = distance(CAMERA_POSITION_WORLD, world_pos);
	float fade = clamp((world_dist - fade_start) / fade_range, 0.0, 1.0);
	ALPHA = mix(1.0, min_alpha, fade);
}
