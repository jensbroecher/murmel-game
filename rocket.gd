extends Node3D

@onready var audio_player = $AudioStreamPlayer3D
@onready var particles = $CPUParticles3D
@onready var model = $Model

var is_launching = false
var launch_speed = 0.0
var acceleration = 10.0

func _ready():
	# Ensure particles are off initially
	if particles:
		particles.emitting = false

func _process(delta):
	if is_launching:
		launch_speed += acceleration * delta
		# Move up relative to the rocket's orientation (perpendicular to the board)
		translate(Vector3.UP * launch_speed * delta)
		
		# Optional: Add some wobble or rotation
		rotate_y(1.0 * delta)

func launch():
	if is_launching:
		return
		
	is_launching = true
	
	if particles:
		particles.emitting = true
		
	if audio_player:
		audio_player.play()
		
	# Detach from parent to avoid moving with the level tilt if desired?
	# Or just move up in local/global space. 
	# If we are child of LevelPivot, moving Y up means moving up relative to the board.
	# If the board is tilted, the rocket will fly "up" relative to the board normal.
	# That might look cool.
