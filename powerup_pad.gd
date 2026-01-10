extends Area3D

@export var size_multiplier: float = 2.0
@export var mass_multiplier: float = 5.0
@export var duration: float = 20.0

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("change_size_and_mass"):
		body.change_size_and_mass(size_multiplier, mass_multiplier, duration)
		# We don't disable monitoring here anymore. 
		# The marble handles the state logic (refreshing timer if already active).
