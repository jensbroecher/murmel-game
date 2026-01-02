extends Node3D

@export var target_path: NodePath
@export var follow_speed: float = 10.0
@export var mouse_sensitivity: float = 0.005

@onready var pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

var _rotation_x: float = deg_to_rad(-30.0) # Start at -30 degrees
var _rotation_y: float = deg_to_rad(45.0) # Start at 45 degrees (Isometric)

var target_node: Node3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Apply initial isometric rotation
	pivot.rotation.x = _rotation_x
	pivot.rotation.y = _rotation_y
	
	if target_path:
		target_node = get_node(target_path)
		if target_node:
			global_position = target_node.global_position

func _input(event):
	# Removed mouse camera control
	pass

func _process(delta):
	# Keyboard Camera Control
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var cam_rot_speed = 2.0
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
			_rotation_y += cam_rot_speed * delta
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
			_rotation_y -= cam_rot_speed * delta
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
			_rotation_x += cam_rot_speed * delta
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
			_rotation_x -= cam_rot_speed * delta
			
		_rotation_x = clamp(_rotation_x, deg_to_rad(-60.0), deg_to_rad(-20.0))
		
		pivot.rotation.x = _rotation_x
		pivot.rotation.y = _rotation_y

	if target_node:
		# Smooth follow
		var target_pos = target_node.global_position
		# Offset pivot up to avoid floor collision at shallow angles
		target_pos.y += 2.0 
		
		# Clamp Y to not go below water level
		if target_pos.y < -16.0:
			target_pos.y = -16.0
			
		global_position = global_position.lerp(target_pos, follow_speed * delta)
