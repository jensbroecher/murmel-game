extends StaticBody3D

const DebrisScene = preload("res://debris.tscn")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("change_size_and_mass"): # Check if it's the marble
		if body.get("is_super_marble"):
			break_wall()

func break_wall() -> void:
	$AudioStreamPlayer3D.play()
	$MeshInstance3D.visible = false
	$CollisionShape3D.set_deferred("disabled", true)
	
	# Spawn Rigid Body Debris
	var parent = get_tree().current_scene
	if parent:
		for i in range(20):
			var debris = DebrisScene.instantiate()
			parent.add_child(debris)
			
			# Random Position within wall bounds (approx +/- 2 wide, +/- 1 high)
			# Wall is at local 0,0,0
			# Global transform handles the wall's position/rotation
			var offset = Vector3(
				randf_range(-1.8, 1.8),
				randf_range(-0.8, 0.8),
				randf_range(-0.2, 0.2)
			)
			debris.global_position = to_global(offset)
			
			# Random Impulse
			# Explode outwards slightly
			var impulse = Vector3(
				randf_range(-2, 2),
				randf_range(2, 5), # Upwards bias
				randf_range(-2, 2)
			)
			debris.apply_central_impulse(impulse)
			
			# Random rotation
			debris.angular_velocity = Vector3(
				randf_range(-10, 10),
				randf_range(-10, 10),
				randf_range(-10, 10)
			)

	# Wait for sound to finish before deleting
	await $AudioStreamPlayer3D.finished
	queue_free()
