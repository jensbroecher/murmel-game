# hill_generator.gd
@tool
extends Node3D

@export var height: float = 30.0:
	set(value):
		height = value
		if is_inside_tree(): _generate_hill()

@export var top_radius: float = 2.0:
	set(value):
		top_radius = value
		if is_inside_tree(): _generate_hill()

@export var bottom_radius: float = 20.0:
	set(value):
		bottom_radius = value
		if is_inside_tree(): _generate_hill()

@export var turns: int = 3:
	set(value):
		turns = value
		if is_inside_tree(): _generate_hill()

@export var track_width: float = 4.0:
	set(value):
		track_width = value
		if is_inside_tree(): _generate_hill()

@export var wall_height: float = 2.0:
	set(value):
		wall_height = value
		if is_inside_tree(): _generate_hill()
		
@export var material: Material:
	set(value):
		material = value
		if is_inside_tree(): _generate_hill()

func _ready():
	_generate_hill()

func _generate_hill():
	# Clear existing children
	for child in get_children():
		child.queue_free()
		
	# Create Path3D
	var path_3d = Path3D.new()
	path_3d.name = "SpiralPath"
	add_child(path_3d)
	
	var curve = Curve3D.new()
	path_3d.curve = curve
	
	var points_per_turn = 32
	var total_points = turns * points_per_turn
	
	for i in range(total_points + 1):
		var t = float(i) / total_points # 0 to 1
		var current_height = height * (1.0 - t)
		var current_radius = lerp(top_radius, bottom_radius, t) # Top to bottom
		var angle = t * turns * TAU
		
		# In Godot, Y is up. We spiral in XZ plane.
		var x = cos(angle) * current_radius
		var z = sin(angle) * current_radius
		
		# NOTE: Reversed height logic in original script (bottom_radius was associated with 1.0 t?) 
		# Let's clean this up:
		# Start at TOP (height, top_radius) -> End at BOTTOM (0, bottom_radius)
		# Path should go DOWN so gravity works naturally? 
		# But CSGPolygon usually extrudes along path.
		# If user wants "marble can roll down on", we should probably ensure the path points DOWN or just rely on gravity.
		# Let's stick to generating points from Top to Bottom.
		
		curve.add_point(Vector3(x, current_height, z))
		
		# Explicitly set tilt to 0 to prevent banking issues, 
		# or ideally bank slightly INWARDS (negative tilt often)
		curve.set_point_tilt(i, 0.0) 
		
	# Create CSGPolygon3D for the track
	var csg_poly = CSGPolygon3D.new()
	csg_poly.name = "TrackGeometry"
	csg_poly.mode = CSGPolygon3D.MODE_PATH
	csg_poly.path_node = path_3d.get_path()
	csg_poly.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	csg_poly.path_interval = 0.5
	csg_poly.path_simplify_angle = 2.0
	csg_poly.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH # Try PATH to respect direct Up vector better? Or PATH_FOLLOW
	# Use standard path follow but rely on the flat 2D profile + flat curve points.
	csg_poly.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH
	csg_poly.use_collision = true
	
	# Create the U-shape profile (2D polygon)
	# Center is at (0,0). Width extends -2 to +2.
	# Walls go up.
	var half_width = track_width / 2.0
	# We want a "U" shape.
	# 0,0 is the center of the track floor.
	var polygon_points = PackedVector2Array([
		Vector2(-half_width - 1.0, wall_height), # Outer Top Left
		Vector2(-half_width - 1.0, -1.0),        # Outer Bottom Left
		Vector2(half_width + 1.0, -1.0),         # Outer Bottom Right
		Vector2(half_width + 1.0, wall_height),  # Outer Top Right
		Vector2(half_width, wall_height),        # Inner Top Right
		Vector2(half_width, 0),                  # Inner Bottom Right (Floor)
		Vector2(-half_width, 0),                 # Inner Bottom Left (Floor)
		Vector2(-half_width, wall_height)        # Inner Top Left
	])
	csg_poly.polygon = polygon_points
	
	if material:
		csg_poly.material = material
		
	add_child(csg_poly)
