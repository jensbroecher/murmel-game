extends StaticBody3D

@export var bump_force: float = 200.0

@onready var audio = $AudioStreamPlayer3D
@onready var mesh = $MeshInstance3D

func bump(body: RigidBody3D):
	var direction = (body.global_position - global_position).normalized()
	direction.y = 0 # Keep it horizontal to avoid launching marble into space
	direction = direction.normalized()
	
	# Apply impulse at the contact point would be better, but center-to-center is reliable for bumpers
	body.apply_impulse(direction * bump_force)
	
	if audio:
		audio.play()
		print("Bumper sound played")
		
	# Visual feedback (simple scale tween)
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.2, 0.8, 1.2), 0.05) # Squish out
		tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.05) # Return

func _on_area_3d_body_entered(body):
	if body is RigidBody3D:
		bump(body)
