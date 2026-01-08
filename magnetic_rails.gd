extends Path3D

@export var magnet_strength: float = 80.0
@export var damping: float = 10.0
@export var max_distance: float = 3.0
@export var enabled: bool = true

func _physics_process(delta):
	if not enabled:
		return
		
	var marbles = get_tree().get_nodes_in_group("marble")
	for marble in marbles:
		if not (marble is RigidBody3D):
			continue
			
		var marble_pos = marble.global_position
		# Find closest point on the curve (in local space)
		var local_pos = to_local(marble_pos)
		var closest_offset = curve.get_closest_offset(local_pos)
		var curve_len = curve.get_baked_length()
		
		# Stop applying force if we are near the end of the rail (allow falling off)
		if closest_offset > curve_len - 0.5:
			continue
			
		var target_local = curve.sample_baked(closest_offset)
		
		# Check if marble is hanging underneath
		# Get the up vector at this point on the curve
		var up_vector = curve.sample_baked_up_vector(closest_offset, true)
		var vec_to_marble = local_pos - target_local
		var height_rel = vec_to_marble.dot(up_vector)
		
		# If marble is significantly below the rail center (e.g. > 0.2 units down), let it fall
		# The marble radius is 0.5, so -0.2 allows it to sit slightly low but not hang
		if height_rel < -0.2:
			continue
			
		var target_pos = to_global(target_local)
		var dist = marble_pos.distance_to(target_pos)
		
		if dist < max_distance:
			# Vector from marble to rail center
			var diff = target_pos - marble_pos
			
			# Calculate the rail tangent at this point to know "forward"
			var look_ahead = 0.1
			var next_offset = min(closest_offset + look_ahead, curve_len)
			var prev_offset = max(closest_offset - look_ahead, 0.0)
			
			var p_next = to_global(curve.sample_baked(next_offset))
			var p_prev = to_global(curve.sample_baked(prev_offset))
			var tangent = (p_next - p_prev).normalized()
			
			if tangent.length_squared() < 0.001:
				tangent = Vector3.FORWARD # Fallback
				
			var velocity = marble.linear_velocity
			
			# Decompose velocity into parallel (along rail) and perpendicular (away/towards rail)
			var v_parallel = velocity.project(tangent)
			var v_perpendicular = velocity - v_parallel
			
			# Apply forces
			# 1. Spring force: Pull towards the line
			# 2. Damping force: Resist perpendicular velocity
			
			var force = (diff * magnet_strength) - (v_perpendicular * damping)
			
			marble.apply_central_force(force)
