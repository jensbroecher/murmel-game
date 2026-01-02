@tool
extends SceneTree

func _init():
	var points = PackedVector3Array()
	
	# Configuration
	var radius = 2.0
	var loop_width = 1.0 # Offset in X to avoid self-collision
	var loop_length = 4.0 # Distance covered in Z during loop
	var segments = 16
	
	# Start at origin (Entrance of loop)
	add_point(points, Vector3(0, 0, 0))
	
	# Loop (Helix)
	var start_angle = -PI / 2.0
	var total_angle = 2.0 * PI
	
	for i in range(1, segments + 1):
		var t = float(i) / segments
		var angle = start_angle - t * total_angle
		
		# Helix progression
		var current_x = lerp(0.0, loop_width, t)
		var current_z_center = lerp(0.0, -loop_length, t)
		
		var y = radius + radius * sin(angle)
		var z_local = radius * cos(angle)
		
		var pos = Vector3(current_x, y, current_z_center + z_local)
		add_point(points, pos)
		
	print_curve_data(points)
	quit()

func add_point(points: PackedVector3Array, pos: Vector3):
	points.append(pos)

func print_curve_data(points: PackedVector3Array):
	var curve_data = PackedVector3Array()
	
	for i in range(points.size()):
		var p = points[i]
		var p_prev = points[max(0, i-1)]
		var p_next = points[min(points.size()-1, i+1)]
		
		var tangent = (p_next - p_prev).normalized() * 1.5
		
		if i == 0:
			tangent = (p_next - p).normalized() * 2.0
		if i == points.size() - 1:
			tangent = (p - p_prev).normalized() * 2.0
			
		var in_handle = -tangent
		var out_handle = tangent
		
		if i == 0:
			in_handle = Vector3.ZERO
		if i == points.size() - 1:
			out_handle = Vector3.ZERO
			
		curve_data.append(in_handle)
		curve_data.append(out_handle)
		curve_data.append(p)
		
	var output = "\"points\": PackedVector3Array("
	for i in range(curve_data.size()):
		var v = curve_data[i]
		output += str(v.x) + ", " + str(v.y) + ", " + str(v.z)
		if i < curve_data.size() - 1:
			output += ", "
	output += ")"
	print(output)
