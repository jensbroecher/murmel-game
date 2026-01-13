extends RigidBody3D

@export var lifetime: float = 20.0

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	if global_position.y < -50:
		queue_free()
