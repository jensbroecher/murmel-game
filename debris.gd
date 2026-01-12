extends RigidBody3D

func _ready():
	# Lifetime: 10 seconds
	get_tree().create_timer(10.0).timeout.connect(_start_fade)

func _start_fade():
	var tween = create_tween()
	var mesh = $MeshInstance3D
	if mesh:
		var mat = mesh.get_active_material(0)
		if mat:
			# Clone material to allow unique fading
			var new_mat = mat.duplicate()
			mesh.material_override = new_mat
			new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tween.tween_property(new_mat, "albedo_color:a", 0.0, 1.0)
	
	tween.tween_callback(queue_free)
