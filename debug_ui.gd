extends Label

var camera_controller: Node3D

func _ready():
	# Find camera controller by type or path
	await get_tree().process_frame
	var root = get_tree().current_scene
	# In stage_1.tscn, the node is named "CameraRig" and has script "camera_controller.gd"
	camera_controller = root.get_node_or_null("CameraRig")

func _process(delta):
	if not camera_controller:
		return
		
	var pivot = camera_controller.get_node_or_null("CameraPivot")
	if pivot:
		# Get the actual camera node to show global position
		var cam = pivot.get_node_or_null("Camera3D")
		var cam_pos = Vector3.ZERO
		if cam:
			cam_pos = cam.global_position
			
		text = "Camera Pivot Rotation (X/Y): %.2f, %.2f\nCamera Global Pos: %.1v" % [
			rad_to_deg(pivot.rotation.x), 
			rad_to_deg(pivot.rotation.y), 
			cam_pos
		]
