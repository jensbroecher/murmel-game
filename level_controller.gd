extends Node3D

@export var tilt_speed: float = 3.0
@export var max_tilt_degrees: float = 10.0
@export var accel_force: float = 80.0
@export var gamepad_tilt_speed: float = 1.2
@export var gamepad_deadzone: float = 0.2

var input_enabled: bool = true
var marble: RigidBody3D
var camera_rig: Node3D

# Store accumulated target rotation to be applied in physics process
var _target_rotation_x: float = 0.0
var _target_rotation_z: float = 0.0

func set_marble(body: RigidBody3D) -> void:
	marble = body

func set_camera(camera: Node3D) -> void:
	camera_rig = camera

func set_input_enabled(enabled: bool) -> void:
	print("LevelController: set_input_enabled called with ", enabled)
	input_enabled = enabled
	if not enabled:
		pass

func _physics_process(delta: float) -> void:
	if input_enabled:
		var joypads = Input.get_connected_joypads()
		if joypads.size() > 0:
			var id = joypads[0]
			var use_left = GlobalGameState.tilt_uses_left_stick
			var ax_x_axis = 0 if use_left else 2
			var ax_y_axis = 1 if use_left else 3
			var ax_x = Input.get_joy_axis(id, ax_x_axis)
			var ax_y = Input.get_joy_axis(id, ax_y_axis)
			var vec_len = Vector2(ax_x, ax_y).length()
			if vec_len > gamepad_deadzone:
				var relative_x = ax_x
				var relative_y = ax_y
				if camera_rig and "pivot" in camera_rig and camera_rig.pivot:
					var cam_y_rot = camera_rig.pivot.rotation.y
					var rotated_x = relative_x * cos(cam_y_rot) - relative_y * sin(cam_y_rot)
					var rotated_y = relative_x * sin(cam_y_rot) + relative_y * cos(cam_y_rot)
					relative_x = rotated_x
					relative_y = rotated_y
				if GlobalGameState.tilt_inverted:
					relative_x = -relative_x
					relative_y = -relative_y
				_target_rotation_x -= relative_y * gamepad_tilt_speed * delta
				_target_rotation_z -= relative_x * gamepad_tilt_speed * delta
	
	var max_rad = deg_to_rad(max_tilt_degrees)
	_target_rotation_x = clamp(_target_rotation_x, -max_rad, max_rad)
	_target_rotation_z = clamp(_target_rotation_z, -max_rad, max_rad)
	
	var smooth_speed = 2.0 
	
	rotation.x = lerp_angle(rotation.x, _target_rotation_x, smooth_speed * delta)
	rotation.z = lerp_angle(rotation.z, _target_rotation_z, smooth_speed * delta)

	if marble and input_enabled:
		# Apply additional force based on tilt
		# Tilt Forward (Neg X) -> Push -Z
		# Tilt Right (Neg Z) -> Push +X
		var force_vector = Vector3(-sin(rotation.z), 0, sin(rotation.x))
		# Transform to global space if needed (assuming LevelPivot might be rotated)
		# Since rotation.x/z are local Euler, and we constructed a local vector,
		# we should apply it relative to the parent's orientation?
		# Actually, LevelPivot is the one rotating.
		# The force should be applied in the "horizontal plane" direction that corresponds to the tilt.
		# If the parent is not rotated, Global = Local.
		
		marble.apply_central_force(force_vector * accel_force)

func _input(event):
	if not input_enabled:
		return
		
	if event is InputEventScreenDrag:
		var viewport_size = get_viewport().get_visible_rect().size
		# Right side of screen for Tilt
		if event.position.x >= viewport_size.x / 2:
			var sensitivity = 0.005
			var relative_x = event.relative.x
			var relative_y = event.relative.y
			
			if camera_rig and "pivot" in camera_rig and camera_rig.pivot:
				var cam_y_rot = camera_rig.pivot.rotation.y
				var rotated_x = relative_x * cos(cam_y_rot) - relative_y * sin(cam_y_rot)
				var rotated_y = relative_x * sin(cam_y_rot) + relative_y * cos(cam_y_rot)
				relative_x = rotated_x
				relative_y = rotated_y
			
			_target_rotation_x -= relative_y * sensitivity
			_target_rotation_z -= relative_x * sensitivity
			
			var max_rad = deg_to_rad(max_tilt_degrees)
			_target_rotation_x = clamp(_target_rotation_x, -max_rad, max_rad)
			_target_rotation_z = clamp(_target_rotation_z, -max_rad, max_rad)

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Map mouse movement to tilt target
		# Sensitivity factor
		var sensitivity = 0.005 
		
		var relative_x = event.relative.x
		var relative_y = event.relative.y
		
		if GlobalGameState.tilt_inverted:
			relative_x = -relative_x
			relative_y = -relative_y
		
		# Rotate input based on camera angle if available
		if camera_rig and "pivot" in camera_rig:
			# Get camera pivot Y rotation
			var cam_y_rot = camera_rig.pivot.rotation.y
			
			# We need to rotate the 2D mouse vector by this angle.
			# Standard 2D rotation:
			# x' = x cos(theta) - y sin(theta)
			# y' = x sin(theta) + y cos(theta)
			
			var rotated_x = relative_x * cos(cam_y_rot) - relative_y * sin(cam_y_rot)
			var rotated_y = relative_x * sin(cam_y_rot) + relative_y * cos(cam_y_rot)
			
			relative_x = rotated_x
			relative_y = rotated_y
		
		# Accumulate rotation target based on mouse movement
		_target_rotation_x -= relative_y * sensitivity
		_target_rotation_z -= relative_x * sensitivity
		
		# Clamp target rotation
		var max_rad = deg_to_rad(max_tilt_degrees)
		_target_rotation_x = clamp(_target_rotation_x, -max_rad, max_rad)
		_target_rotation_z = clamp(_target_rotation_z, -max_rad, max_rad)

	if Input.is_key_pressed(KEY_R):
		# GameManager is the parent node (Root of the scene)
		var game_manager = get_parent()
		if game_manager.has_method("respawn_marble"):
			game_manager.respawn_marble()

func _on_loop_boost_body_entered(body: Node3D) -> void:
	if body is RigidBody3D:
		# Force direction to be along -Z (local loop forward)
		# The Loop is rotated in the scene, but the Area3D is child of LoopDeLoop.
		# But body velocity is global.
		# The LoopDeLoop is at Y rotation 0?
		# Let's check stage_1.tscn transform.
		
		# Assuming the loop entrance is aligned with World -Z (or similar).
		# Instead of relying on current velocity (which might be slow/wrong direction),
		# let's push it towards the loop entrance direction.
		# The loop is extended, so the entrance is a straight tube along Z axis?
		# Let's check the generated points. 
		# Start extension: (0,0,6) -> (0,0,0). Direction: -Z.
		# So we should boost along Vector3.FORWARD * -1 = Vector3.BACK.
		
		# Convert Vector3.BACK to global space if LevelPivot is rotated?
		# LevelPivot rotates with user input.
		# So "Global Back" is relative to the camera, but the level rotates under it.
		# If the marble is on the level, and we want to push it "into the loop",
		# we need to push it in the local space of the LoopDeLoop node.
		
		# The boost area is a child of LoopDeLoop.
		# LoopDeLoop transform is (1,0,0, 0,1,0, 0,0,1, 0,0,0) (Identity relative to LevelPivot).
		# LevelPivot rotates.
		# So Local -Z of LoopDeLoop = Local -Z of LevelPivot.
		# We want to apply an impulse in the direction of the loop track.
		# That is -Z in the local space of the level.
		
		# Since the physics body is in Global Space, we need to apply Global Velocity.
		# Global Direction = LevelPivot.global_transform.basis * Vector3.BACK.
		
		var boost_dir_local = Vector3(0, 0, -1) # Into the loop (from +Z to -Z)
		var boost_dir_global = global_transform.basis * boost_dir_local
		
		print("Boost Triggered! Dir: ", boost_dir_global, " Speed: ", body.linear_velocity.length())
		
		var target_speed = 60.0 # Even faster
		
		body.sleeping = false
		body.linear_velocity = boost_dir_global * target_speed
