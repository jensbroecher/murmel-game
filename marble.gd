extends RigidBody3D

@export var reset_threshold: float = -50.0
@onready var start_position: Vector3 = global_position

func _ready() -> void:
	# Enable Continuous Collision Detection (CCD) to prevent tunneling
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 3

func _process(delta: float) -> void:
	if global_position.y < reset_threshold:
		reset_game()

func reset_game() -> void:
	# Reload the current scene
	get_tree().reload_current_scene()
