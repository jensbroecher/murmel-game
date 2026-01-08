extends StaticBody3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("change_size_and_mass"): # Check if it's the marble
		if body.get("is_super_marble"):
			break_wall()

func break_wall() -> void:
	$AudioStreamPlayer3D.play()
	$MeshInstance3D.visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	
	# Optional: Spawn debris particles here
	if has_node("CPUParticles3D"):
		$CPUParticles3D.emitting = true
	
	# Wait for sound to finish before deleting
	await $AudioStreamPlayer3D.finished
	queue_free()
