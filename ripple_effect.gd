extends Node3D

var target_scale_size: float = 8.0

func _ready():
	var tween = create_tween()
	
	var mesh = $MeshInstance3D
	# Start mesh small and flat (local scale)
	mesh.scale = Vector3(0.1, 0.2, 0.1)
	
	var mat = mesh.get_surface_override_material(0)
	if mat:
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)
		
		# Animate Mesh Scale (Expand) - Keep Y scale small
		tween.tween_property(mesh, "scale", Vector3(target_scale_size, 0.2, target_scale_size), 1.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		# Animate Alpha (Fade out)
		# For ShaderMaterial, we need to tween the shader parameter "color" alpha
		tween.parallel().tween_method(
			func(alpha): 
				var c = mat.get_shader_parameter("color")
				c.a = alpha
				mat.set_shader_parameter("color", c),
			0.5, 0.0, 1.5).set_ease(Tween.EASE_IN)
		
		tween.tween_callback(queue_free)
	else:
		queue_free()

	# Start Particles
	var particles = $SplashParticles
	if particles:
		particles.emitting = true
