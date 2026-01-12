extends Node3D

@onready var audio_player = $AudioStreamPlayer3D
@onready var particles = $CPUParticles3D
@onready var model = $Model
@onready var trigger_area = $Area3D

var is_launching = false
var launch_speed = 0.0
var acceleration = 10.0

func _ready():
	# Ensure particles are off initially
	if particles:
		particles.emitting = false
	
	if trigger_area:
		trigger_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if is_launching:
		return
		
	if body.name == "Marble" or body is RigidBody3D:
		var game_manager = get_tree().current_scene
		if game_manager and "collected_diamonds" in game_manager and "total_diamonds" in game_manager:
			if game_manager.collected_diamonds >= game_manager.total_diamonds:
				launch(body)
			else:
				print("Not enough diamonds! Collected: ", game_manager.collected_diamonds, "/", game_manager.total_diamonds)

func _process(delta):
	if is_launching:
		launch_speed += acceleration * delta
		# Move up relative to the rocket's orientation (perpendicular to the board)
		translate(Vector3.UP * launch_speed * delta)
		
		# Optional: Add some wobble or rotation
		rotate_y(1.0 * delta)

func launch(marble_body = null):
	if is_launching:
		return
		
	is_launching = true
	
	if particles:
		particles.emitting = true
		
	if audio_player:
		audio_player.play()
	
	# Handle Marble
	if marble_body:
		# Disable physics/collision for marble and hide it (simulating it being inside)
		marble_body.process_mode = Node.PROCESS_MODE_DISABLED
		marble_body.visible = false
		
	# Camera Follow and Level Completion
	var game_manager = get_tree().current_scene
	if game_manager:
		# Stop rolling sound
		var sound_gen = game_manager.get_node_or_null("SoundGenerator")
		if sound_gen:
			sound_gen.set_marble(null)

		# Find CameraRig
		var camera_rig = game_manager.get_node_or_null("CameraRig")
		if camera_rig:
			camera_rig.target_node = self
			# Smooth follow for launch
			if "follow_speed" in camera_rig:
				camera_rig.follow_speed = 2.0 
			
		# Trigger Level Completion Sequence
		if game_manager.has_method("level_complete"):
			game_manager.level_complete()
