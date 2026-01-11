shader_type spatial;

uniform vec4 albedo : source_color = vec4(0.0, 0.4, 0.8, 0.6);
uniform float metallic : hint_range(0.0, 1.0) = 0.5;
uniform float roughness : hint_range(0.0, 1.0) = 0.1;
uniform sampler2D texture_normal;
uniform sampler2D texture_normal2;
uniform vec2 wave_direction = vec2(2.0, 0.0);
uniform vec2 wave_direction2 = vec2(0.0, 1.0);
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.025;
uniform float uv_scale = 125.0;

void fragment() {
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	
	vec3 normal_blend = mix(texture(texture_normal, UV * uv_scale + time).rgb, texture(texture_normal2, UV * uv_scale + time2).rgb, 0.5);
	
	ALBEDO = albedo.rgb;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal_blend;
	ALPHA = albedo.a;
}
