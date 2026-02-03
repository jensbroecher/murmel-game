shader_type spatial;
render_mode blend_add, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.0, 0.5, 1.0, 0.5);
uniform float fresnel_power : hint_range(0.1, 10.0) = 2.0;
uniform float energy_speed : hint_range(0.0, 5.0) = 1.0;
uniform float density : hint_range(1.0, 50.0) = 10.0;
uniform sampler2D noise_texture;

uniform float pulse_intensity = 0.0;

void fragment() {
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), fresnel_power);
    
    // Animate noise UVs
    vec2 uv_anim = UV + vec2(0.0, TIME * energy_speed * 0.1);
    float noise_val = texture(noise_texture, uv_anim * vec2(1.0, 0.5)).r;
    
    // Combine base color with fresnel and noise
    ALBEDO = base_color.rgb + vec3(pulse_intensity); // Whiten on pulse
    
    // Dynamic emission based on noise + pulse
    EMISSION = base_color.rgb * (1.0 + noise_val * 2.0) + vec3(pulse_intensity * 2.0); 
    
    // Alpha calc: Base alpha + fresnel intensity * noise + pulse
    float alpha = base_color.a * 0.1 + fresnel * noise_val * 1.5 + pulse_intensity * 0.5;
    ALPHA = clamp(alpha, 0.0, 1.0);
}
