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
	
	# Create a tween for the shrink animation
	var tween = create_tween()
	tween.tween_property(model, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	
	audio_player.play()
	particles.emitting = true
	
	# Mark as collected in global state
	GlobalGameState.register_collected(name)
	
	# Notify Game Manager
	if get_tree().current_scene.has_method("collect_diamond"):
		get_tree().current_scene.collect_diamond()
	
	# Calculate wait time: max of sound duration and particle lifetime
	var stream_length = 0.0
	if audio_player.stream:
		stream_length = audio_player.stream.get_length()
	
	# Add a buffer to ensure no race conditions (e.g. particles fading out last frame)
	var wait_time = max(stream_length, particles.lifetime) + 2.0
	
	# Disable collision immediately to prevent double collection
	$CollisionShape3D.set_deferred("disabled", true)
	
	# Wait for the effects to finish before freeing
	await get_tree().create_timer(wait_time).timeout
	queue_free()
