extends Node3D

@export var transport_duration: float = 1.0
@export var camera_catchup_delay: float = 0.8
@export var exit_location: Node3D
@export var entrance_area: Area3D
@export var suction_area: Area3D
@export var ejection_force: float = 50.0
@export var suction_force: float = 500.0
@export var centering_force: float = 600.0
@export var side_damping: float = 20.0

var marble_in_suction: RigidBody3D = null

# Optional: sound or particles

func _ready():
	if entrance_area:
		entrance_area.body_entered.connect(_on_body_entered)
	if suction_area:
		suction_area.body_entered.connect(_on_suction_entered)
		suction_area.body_exited.connect(_on_suction_exited)

func _on_suction_entered(body):
	if body is RigidBody3D and body.name == "Marble":
		print("Tunnel: Marble entered suction area")
		marble_in_suction = body

func _on_suction_exited(body):
	if body == marble_in_suction:
		print("Tunnel: Marble exited suction area")
		marble_in_suction = null

func _physics_process(delta):
	if marble_in_suction and is_instance_valid(marble_in_suction):
		# Calculate forces relative to suction area
		
		# Get local position of marble in suction area space
		var local_pos = suction_area.to_local(marble_in_suction.global_position)
		
		# Centering: Force towards (0, 0, local_pos.z) - i.e. eliminate X and Y offset
		var center_axis_pos = Vector3(0, 0, local_pos.z)
		var offset_from_axis = local_pos - center_axis_pos
		var center_dir_local = -offset_from_axis.normalized()
		
		# Suction: Force along -Z (into the tunnel hole)
		var suction_dir_local = Vector3(0, 0, -1) 
		
		# Global Directions
		var global_center_dir = (suction_area.to_global(center_dir_local) - suction_area.global_position).normalized()
		# For suction dir, we must be careful with to_global direction vs point
		var global_suction_dir = (suction_area.to_global(suction_dir_local) - suction_area.to_global(Vector3.ZERO)).normalized()
		
		# Apply Forces
		marble_in_suction.apply_central_force(global_center_dir * centering_force)
		marble_in_suction.apply_central_force(global_suction_dir * suction_force)
		
		# Side Damping (Stabilization)
		var velocity = marble_in_suction.linear_velocity
		var vel_along_axis = velocity.project(global_suction_dir)
		var side_vel = velocity - vel_along_axis
		
		# Apply force opposite to side velocity to reduce it (like friction/drag)
		marble_in_suction.apply_central_force(-side_vel * side_damping * marble_in_suction.mass)

func _on_body_entered(body):
	print("Tunnel: Body entered transport trigger: ", body.name)
	# Require marble to be "in suction" (entering from front) to trigger transport
	if body is RigidBody3D and body.name == "Marble" and body == marble_in_suction:
		_teleport_marble(body)

func _teleport_marble(marble: RigidBody3D):
	# Disable physics/visuals
	marble.process_mode = Node.PROCESS_MODE_DISABLED
	marble.visible = false
	
	print("Tunnel: Teleporting marble...")
	
	# Wait for transport
	await get_tree().create_timer(transport_duration).timeout
	
	# Teleport (set position, but keep hidden/disabled)
	if exit_location:
		marble.global_position = exit_location.global_position
		marble.linear_velocity = Vector3.ZERO
		marble.angular_velocity = Vector3.ZERO
	
	print("Tunnel: Marble at top. Waiting for camera...")
	# Wait for camera to catch up
	await get_tree().create_timer(camera_catchup_delay).timeout
	
	print("Tunnel: Ejection!")
	
	# Apply forward push 
	if exit_location:
		marble.apply_central_impulse(exit_location.global_transform.basis.z * ejection_force)
	
	# Re-enable
	marble.visible = true
	marble.process_mode = Node.PROCESS_MODE_PAUSABLE
