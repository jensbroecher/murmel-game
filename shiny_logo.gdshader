shader_type canvas_item;

// Uniforms for customization
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.5); // White shine with some transparency
uniform float shine_speed : hint_range(0.1, 10.0) = 3.0;
uniform float shine_size : hint_range(0.01, 1.0) = 0.15; // Width of the shine band
uniform float shine_interval : hint_range(0.0, 10.0) = 2.0; // Wait time between shines

void fragment() {
	vec4 curr_color = texture(TEXTURE, UV);
	
	// We want a diagonal line moving across: x + y = value
	// value moves with time.
	// UV.x + UV.y varies from 0.0 to 2.0
	
	float cycle_duration = (3.0 + shine_interval) / shine_speed; // Total time for one cycle including wait
	float progress = mod(TIME, cycle_duration) * shine_speed; // progress in spatial units?
	
	// Actually better:
	// The spatial range we need to cover is approx -0.5 to 2.5 to be safe off-screen
	float pattern_range = 4.0; 
	// The time it takes to cross pattern_range is pattern_range / shine_speed
	
	// We want to pause.
	// Let's use a simpler monotonic timer modulo.
	
	float combined_speed = shine_speed;
	float run_distance = 3.5; // Enough to clear 0.0 to 2.0 diagonal
	float start_offset = -1.0;
	
	// Calculate phase
	// A full cycle is: (time to run distance) + (interval)
	// Time to run distance = run_distance / shine_speed
	
	float active_time = run_distance / shine_speed;
	float total_cycle_time = active_time + shine_interval;
	
	float current_cycle_time = mod(TIME, total_cycle_time);
	
	float moving_pos = start_offset;
	
	if (current_cycle_time < active_time) {
		// We are in the moving phase
		moving_pos = start_offset + (current_cycle_time * shine_speed);
	} else {
		// We are waiting, keep it off screen
		moving_pos = start_offset + run_distance; 
	}
	
	float slope_pos = UV.x + UV.y;
	float dist = abs(slope_pos - moving_pos);
	
	// Create a soft band
	float float_shine = 1.0 - smoothstep(0.0, shine_size, dist);
	
	// Apply shine only where the texture exists (alpha > 0)
	vec3 new_color = mix(curr_color.rgb, shine_color.rgb, float_shine * shine_color.a);
	
	COLOR = vec4(new_color, curr_color.a);
}
