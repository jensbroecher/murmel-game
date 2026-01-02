extends Node3D

@export var launch_force: float = 100.0
@export var spin_force: float = 200.0
@export var launch_delay: float = 1.0

@onready var launch_point: Marker3D = $LaunchPoint
@onready var particles: CPUParticles3D = $CPUParticles3D
@onready var area: Area3D = $Area3D
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

var held_marble: RigidBody3D = null

func _ready() -> void:
	# Connect the signal if not already connected in editor (it won't be if we build tscn manually)
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if held_marble != null:
		# Keep the marble synced with the cannon while it moves/rotates back to neutral
		held_marble.global_transform = launch_point.global_transform

func _on_body_entered(body: Node3D) -> void:
	if held_marble != null:
		return # Already holding a marble
		
	if body is RigidBody3D and body.name.to_lower().contains("marble"):
		_capture_marble(body)

func _capture_marble(marble: RigidBody3D) -> void:
	held_marble = marble
	
	# Stop the marble
	held_marble.linear_velocity = Vector3.ZERO
	held_marble.angular_velocity = Vector3.ZERO
	held_marble.freeze = true
	
	# Disable level controls
	var level = get_parent()
	
	# Try to find SoundGenerator and dampen sound
	var sound_gen = get_node_or_null("/root/Game/SoundGenerator")
	if sound_gen == null:
		# Try relative path if not found absolutely (fallback)
		sound_gen = get_tree().get_root().find_child("SoundGenerator", true, false)
	
	if sound_gen and sound_gen.has_method("set_dampened"):
		sound_gen.set_dampened(true)
	
	# The cannon is a child of LevelPivot in stage_1.tscn, so get_parent() should be LevelPivot (which has level_controller.gd)
	# But checking just in case
	if level.has_method("set_input_enabled"):
		print("Cannon: Disabling input on parent")
		level.set_input_enabled(false)
	elif level.get_parent().has_method("set_input_enabled"):
		# In case structure changes
		print("Cannon: Disabling input on grandparent")
		level.get_parent().set_input_enabled(false)
	else:
		print("Cannon: Could not find set_input_enabled method!")
	
	# Move to launch position
	held_marble.global_position = launch_point.global_position
	
	# Wait for delay
	await get_tree().create_timer(launch_delay).timeout
	
	_fire_marble()

func _fire_marble() -> void:
	if held_marble == null:
		return
	
	# Capture the marble locally and clear member variable to stop physics sync
	var marble = held_marble
	held_marble = null
	
	# Unfreeze
	marble.freeze = false
	
	# Undampen sound
	var sound_gen = get_node_or_null("/root/Game/SoundGenerator")
	if sound_gen == null:
		sound_gen = get_tree().get_root().find_child("SoundGenerator", true, false)
	
	if sound_gen and sound_gen.has_method("set_dampened"):
		sound_gen.set_dampened(false)
	
	# Wait a physics frame to ensure physics engine picks up the state change
	await get_tree().physics_frame
	
	# Enable level controls
	var level = get_parent()
	if level.has_method("set_input_enabled"):
		level.set_input_enabled(true)
	elif level.get_parent().has_method("set_input_enabled"):
		level.get_parent().set_input_enabled(true)
	
	# Calculate direction (Cannon's forward vector)
	# Assuming the cannon points along its local Z axis or similar.
	# Let's assume -Z is forward like standard Godot cameras/objects.
	var direction = -global_transform.basis.z.normalized()
	
	# Apply impulse
	marble.apply_central_impulse(direction * launch_force)
	
	# Apply spin (random spin)
	# Generate a random unit vector for the spin axis
	var spin_axis = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	
	# Assuming mass is around 1-5, and we want high speed.
	# spin_force was 200. If mass is 5, torque impulse 200 -> delta ang vel 40 rad/s.
	# Let's set angular velocity directly to ensure it sticks.
	# We'll use spin_force as the target angular speed magnitude for now, or scaled.
	# If spin_force is 200, that's very fast rotation (approx 30 rev/s).
	marble.angular_velocity = spin_axis * (spin_force / 5.0) # Scaling down a bit or using as raw speed
	
	# Effect
	if particles:
		particles.restart()
		particles.emitting = true
	
	if audio:
		audio.play()
