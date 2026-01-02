extends Area3D

@onready var audio_player = $AudioStreamPlayer3D
@onready var model = $Model
@onready var particles = $CPUParticles3D

var collected = false
@export var rotation_speed = 1.0

func _ready():
	add_to_group("diamonds")
	
	# Check if already collected
	if GlobalGameState.is_collected(name):
		queue_free()

func _process(delta):
	if not collected:
		model.rotate_y(rotation_speed * delta)

func _on_body_entered(body):
	if collected:
		return
		
	if body is RigidBody3D: # Assuming marble is RigidBody3D
		collect()

func collect():
	collected = true
	model.visible = false
	audio_player.play()
	particles.emitting = true
	
	# Mark as collected in global state
	GlobalGameState.register_collected(name)
	
	# Notify Game Manager
	if get_tree().current_scene.has_method("collect_diamond"):
		get_tree().current_scene.collect_diamond()
	
	# Wait for sound to finish before freeing
	await audio_player.finished
	queue_free()
