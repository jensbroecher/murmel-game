extends Control

@onready var main_menu = $VBoxContainer
@onready var level_select = $LevelSelectContainer
@onready var level_grid = $LevelSelectContainer/LevelGrid
@onready var settings_container = $SettingsContainer

@onready var difficulty_label = $SettingsContainer/DifficultyContainer/DifficultyValue
@onready var tilt_stick_option = $SettingsContainer/ControlsContainer/TiltStickOption
@onready var invert_tilt_check = $SettingsContainer/ControlsContainer/InvertTiltCheck
@onready var music_check = $SettingsContainer/MusicContainer/MusicCheck

@onready var spaceship = $BackgroundContainer/SubViewport/Background3D/Spaceship
@onready var space_girl = $BackgroundContainer/SubViewport/Background3D/SpaceGirl
@onready var robot_sphere = $BackgroundContainer/SubViewport/Background3D/RobotSphere
@onready var neptune = $BackgroundContainer/SubViewport/Background3D/Neptune
@onready var camera = $BackgroundContainer/SubViewport/Background3D/Camera3D
@onready var background_image = $BackgroundImage

const ScreenFaderScene = preload("res://screen_fader.tscn")
var screen_fader

# Parallax settings
var initial_camera_pos: Vector3
var initial_bg_pos: Vector2
var parallax_intensity_camera = 0.2
var parallax_intensity_bg = 15.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_difficulty_display()
	setup_level_buttons()
	setup_controls_menu()
	
	if camera:
		initial_camera_pos = camera.position
	
	# Setup background parallax deferred to ensure correct viewport size
	call_deferred("setup_background_parallax")
	
	# Play menu music (Track 0)
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.play_music_for_level(0)
	
	if GlobalGameState.show_level_selection_on_load:
		_on_levels_pressed()
		GlobalGameState.show_level_selection_on_load = false
	
	# Connect buttons (assuming nodes exist, otherwise will need to connect in editor or code)
	# For this implementation, I will rely on the scene structure matching this script
	
	# Setup hover animations for main menu buttons
	for child in main_menu.get_children():
		if child is Button:
			setup_hover_anim(child)

	# Screen Transition (Iris Open)
	if ScreenFaderScene:
		screen_fader = ScreenFaderScene.instantiate()
		add_child(screen_fader)
		screen_fader.fade_in_iris(1.5)

func setup_background_parallax():
	if background_image:
		# Reset anchors to top-left so we can manually control size/position without anchor constraints
		background_image.set_anchors_preset(Control.PRESET_TOP_LEFT)
		background_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		# Initial setup
		var viewport_size = get_viewport_rect().size
		background_image.size = viewport_size * 1.1
		background_image.position = (viewport_size - background_image.size) / 2
		initial_bg_pos = background_image.position

func setup_hover_anim(button: Button):
	# print("MainMenu: Setting up hover anim for ", button.name)
	button.pivot_offset = button.custom_minimum_size / 2
	if not button.mouse_entered.is_connected(_on_button_mouse_entered.bind(button)):
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	if not button.mouse_exited.is_connected(_on_button_mouse_exited.bind(button)):
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	
	# Connect click sound via SoundManager
	if not button.pressed.is_connected(_on_button_pressed):
		button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	var sound_manager = get_node_or_null("/root/SoundManager")
	if sound_manager:
		sound_manager.play_ui_click()

func _on_button_mouse_entered(button: Button):
	var sound_manager = get_node_or_null("/root/SoundManager")
	if sound_manager:
		sound_manager.play_ui_hover()

	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_mouse_exited(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _process(delta):
	# Parallax effect
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Calculate normalized mouse position (-1 to 1)
	var norm_mouse_x = (mouse_pos.x / viewport_size.x) * 2.0 - 1.0
	var norm_mouse_y = (mouse_pos.y / viewport_size.y) * 2.0 - 1.0
	
	if camera:
		var target_pos = initial_camera_pos + Vector3(norm_mouse_x * parallax_intensity_camera, -norm_mouse_y * parallax_intensity_camera, 0)
		camera.position = camera.position.lerp(target_pos, 5.0 * delta)
		
	if background_image:
		# Continuously update size to handle window resizing
		var target_size = viewport_size * 1.1
		background_image.size = target_size
		
		# Base position is centered relative to viewport
		var base_pos = (viewport_size - target_size) / 2
		
		# Add parallax offset
		var parallax_offset = Vector2(-norm_mouse_x * parallax_intensity_bg, -norm_mouse_y * parallax_intensity_bg)
		
		# Smoothly interpolate position
		var target_pos = base_pos + parallax_offset
		background_image.position = background_image.position.lerp(target_pos, 5.0 * delta)

	if spaceship:
		spaceship.rotate_y(0.05 * delta)
		# Add some floating motion
		spaceship.position.y = 1.5 + sin(Time.get_ticks_msec() * 0.0002) * 0.1
	
	if space_girl:
		# Random-like rotation (using sin waves with different frequencies)
		# Face camera (approx PI rotation) plus some sway
		var rot_y = -PI * 0.5 + sin(Time.get_ticks_msec() * 0.0005) * 0.5
		space_girl.rotation.y = rot_y
		
		# Floating motion (offset from spaceship for variety)
		var float_y = sin(Time.get_ticks_msec() * 0.0008 + 2.0) * 0.15
		# Keep original base Y position of 0.5 (raised from -1.0), add float offset
		space_girl.position.y = 0.5 + float_y
		
	if robot_sphere:
		var rot_y = 3.8 + sin(Time.get_ticks_msec() * 0.0005) * 0.2
		robot_sphere.rotation.y = rot_y
		var float_y = sin(Time.get_ticks_msec() * 0.0015 + 1.0) * 0.08
		robot_sphere.position.y = 0.5 + float_y
		
	# Neptune rotation handled above
	if neptune:
		neptune.rotate_y(0.001 * delta)

func _on_play_pressed():
	start_level(GlobalGameState.current_level_index)

func _on_difficulty_toggle_pressed():
	var new_diff
	match GlobalGameState.difficulty:
		GlobalGameState.Difficulty.EASY:
			new_diff = GlobalGameState.Difficulty.NORMAL
		GlobalGameState.Difficulty.NORMAL:
			new_diff = GlobalGameState.Difficulty.HARD
		GlobalGameState.Difficulty.HARD:
			new_diff = GlobalGameState.Difficulty.EASY
	
	GlobalGameState.set_difficulty(new_diff)
	update_difficulty_display()

func update_difficulty_display():
	if difficulty_label:
		var diff_name = GlobalGameState.get_difficulty_name()
		var diff_desc = GlobalGameState.get_difficulty_description()
		difficulty_label.text = "%s (%s)" % [diff_name, diff_desc]

func _on_levels_pressed():
	main_menu.visible = false
	level_select.visible = true

func _on_settings_pressed():
	main_menu.visible = false
	settings_container.visible = true

func _on_back_pressed():
	level_select.visible = false
	main_menu.visible = true

func _on_back_from_settings_pressed():
	settings_container.visible = false
	main_menu.visible = true

func _on_quit_pressed():
	get_tree().quit()

func setup_level_buttons():
	# Clear existing children if any
	for child in level_grid.get_children():
		child.queue_free()
		
	var sorted_levels = GlobalGameState.levels.keys()
	sorted_levels.sort()
	
	for level_id in sorted_levels:
		var level_data = GlobalGameState.levels[level_id]
		var btn = Button.new()
		
		var is_unlocked = GlobalGameState.is_level_unlocked(level_id)
		
		var btn_text = level_data["name"]
		
		if not is_unlocked:
			btn_text += "\n[LOCKED]"
			btn.disabled = true
		else:
			var best_diff = GlobalGameState.get_best_completed_difficulty(level_id)
			if best_diff != -1:
				var stats = GlobalGameState.get_stats_for_difficulty(level_id, best_diff)
				var diff_name = GlobalGameState.get_difficulty_label(best_diff)
				if stats.has("time") and stats.has("lives"):
					btn_text += "\nCompleted (%s)\nTime: %s | Lives: %d" % [diff_name, stats["time"], stats["lives"]]
				else:
					# Fallback for legacy or partial data
					btn_text += "\nCompleted (%s)" % diff_name
		
		btn.text = btn_text
		btn.custom_minimum_size = Vector2(200, 80)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		
		if is_unlocked:
			btn.pressed.connect(func(): start_level(level_id))
		
		setup_hover_anim(btn)
			
		level_grid.add_child(btn)

func setup_controls_menu():
	if tilt_stick_option:
		tilt_stick_option.clear()
		tilt_stick_option.add_item("Left Stick", 0)
		tilt_stick_option.add_item("Right Stick", 1)
		tilt_stick_option.selected = 0 if GlobalGameState.tilt_uses_left_stick else 1
	if invert_tilt_check:
		invert_tilt_check.button_pressed = GlobalGameState.tilt_inverted
	if music_check:
		music_check.button_pressed = GlobalGameState.music_enabled

func _on_tilt_stick_selected(index):
	var use_left = index == 0
	GlobalGameState.set_tilt_stick(use_left)

func _on_invert_tilt_toggled(pressed):
	GlobalGameState.set_tilt_inverted(pressed)

func _on_music_toggled(pressed):
	GlobalGameState.set_music_enabled(pressed)

func start_level(level_id: int):
	# Optional: Fade out with Iris before starting
	if screen_fader:
		screen_fader.fade_out_iris(1.0)
		await screen_fader.fade_out_completed
	
	GlobalGameState.current_level_index = level_id
	GlobalGameState.reset_lives()
	GlobalGameState.clear_collected()
	GlobalGameState.start_level_timer() # Reset timer for new game
	
	# Play level music (Offset by 1 so Menu gets track 0)
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.play_music_for_level(level_id + 1)
	
	var level_path = GlobalGameState.levels[level_id]["path"]
	get_tree().change_scene_to_file(level_path)
