extends Control

func _ready():
	# Iterate through the sequence of images in the JABRO folder
	var anim_layer = $AnimationLayer
	# Fade in Godot logo
	var logo = $GodotLogo
	var logo_tween = get_tree().create_tween()
	logo_tween.tween_interval(1.0)
	logo_tween.tween_property(logo, "modulate:a", 1.0, 1.0)
	
	var folder_path = "res://JABRO/"
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var frames = []
		
		# Collect valid png files
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".png") and !file_name.ends_with(".import"):
				frames.append(file_name)
			file_name = dir.get_next()
		
		# Sort alphabetically to ensure correct sequence order (frame-001, frame-002, etc.)
		frames.sort()
		
		# Play sequence
		for frame_file in frames:
			# Load image directly to avoid caching all textures in VRAM at once
			var image = Image.load_from_file(folder_path + frame_file)
			if image:
				var texture = ImageTexture.create_from_image(image)
				anim_layer.texture = texture
				
				# Wait for approximately 60 FPS (0.016s)
				# Adjust this delay to change playback speed
				await get_tree().create_timer(0.016).timeout
	else:
		print("Error: Could not open JABRO directory")
		# Fallback delay if folder not found
		await get_tree().create_timer(2.0).timeout

	var iris = $Iris
	var tween = get_tree().create_tween()
	tween.tween_property(iris.material, "shader_parameter/radius", -0.5, 1.0)
	await tween.finished
	
	get_tree().change_scene_to_file("res://main_menu.tscn")

