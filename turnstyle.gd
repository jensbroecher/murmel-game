extends AnimatableBody3D

@export var rotation_speed: float = 2.0 # Radians per second

func _physics_process(delta):
	# Rotate around Y axis
	rotation.y += rotation_speed * delta
