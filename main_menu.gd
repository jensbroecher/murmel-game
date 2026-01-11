extends Control

@onready var main_menu = $VBoxContainer
@onready var level_select = $LevelSelectContainer
@onready var level_grid = $LevelSelectContainer/Content/Stack/LevelList/LevelButtonsBox
@onready var settings_container = $SettingsContainer

@onready var difficulty_label = $SettingsContainer/Content/Stack/SettingsList/DifficultyContainer/DifficultyInfo/DifficultyValue
@onready var tilt_stick_toggle = $SettingsContainer/Content/Stack/SettingsList/ControlsContainer/TiltStickToggle
@onready var invert_tilt_check = $SettingsContainer/Content/Stack/SettingsList/InvertTiltCheck
@onready var music_check = $SettingsContainer/Content/Stack/SettingsList/MusicContainer/MusicCheck

# Button styles
var btn_normal_style
var btn_hover_style
var btn_pressed_style
var btn_focus_style
var play_btn: Button

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
	
	# Get button styles from the Play button first
	play_btn = main_menu.get_node_or_null("PlayButton")
	if play_btn:
		btn_normal_style = play_btn.get_theme_stylebox("normal")
		btn_hover_style = play_btn.get_theme_stylebox("hover")
		btn_pressed_style = play_btn.get_theme_stylebox("pressed")
		btn_focus_style = play_btn.get_theme_stylebox("focus")
	
	update_difficulty_display()
	
	# Resize checkbox icons
	resize_checkbox_icons()
	
	setup_level_buttons()
	setup_controls_menu()

func resize_checkbox_icons():
	# Manually resize the checkbox and toggle textures to be larger by loading SVGs with scale
	
	# Helper to load SVG with scale and color injection
	var load_svg_custom = func(path: String, scale: float) -> ImageTexture:
		if not FileAccess.file_exists(path):
			return null
			
		var file = FileAccess.open(path, FileAccess.READ)
		var svg_text = file.get_as_text()
		file.close()
		
		# Inject white fill if missing (simple heuristic)
		if not "fill=" in svg_text:
			svg_text = svg_text.replace("<path", "<path fill=\"white\"")
		
		var img = Image.new()
		var err = img.load_svg_from_string(svg_text, scale)
		if err != OK:
			return null
			
		return ImageTexture.create_from_image(img)
	
	# 1. Resize Checkboxes (Scale 2.0 -> 48x48)
	var new_checked = load_svg_custom.call("res://images/checkbox-marked-circle.svg", 2.0)
	var new_unchecked = load_svg_custom.call("res://images/checkbox-blank-circle.svg", 2.0)
	
	if new_checked and new_unchecked:
		if music_check:
			music_check.add_theme_icon_override("checked", new_checked)
			music_check.add_theme_icon_override("unchecked", new_unchecked)
		if invert_tilt_check:
			invert_tilt_check.add_theme_icon_override("checked", new_checked)
			invert_tilt_check.add_theme_icon_override("unchecked", new_unchecked)

	# 2. Resize Toggle Switch (Scale 3.0 -> 72x72, keeps it crisp)
	var new_toggle_on = load_svg_custom.call("res://images/toggle-switch.svg", 3.0)
	var new_toggle_off = load_svg_custom.call("res://images/toggle-switch-off.svg", 3.0)
	
	if tilt_stick_toggle and new_toggle_on and new_toggle_off:
		tilt_stick_toggle.add_theme_icon_override("checked", new_toggle_on)
		tilt_stick_toggle.add_theme_icon_override("unchecked", new_toggle_off)
	
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
	
	# Helper to style a button
	var style_btn = func(btn: Button):
		if not btn: return
		if btn_normal_style: btn.add_theme_stylebox_override("normal", btn_normal_style)
		if btn_hover_style: btn.add_theme_stylebox_override("hover", btn_hover_style)
		if btn_pressed_style: btn.add_theme_stylebox_override("pressed", btn_pressed_style)
		if btn_focus_style: btn.add_theme_stylebox_override("focus", btn_focus_style)
		# Copy other theme properties if needed
		if play_btn:
			btn.add_theme_color_override("font_color", play_btn.get_theme_color("font_color"))
			btn.add_theme_color_override("font_hover_color", play_btn.get_theme_color("font_hover_color"))
			btn.add_theme_font_size_override("font_size", play_btn.get_theme_font_size("font_size"))
	
	# Style Settings buttons
	var settings_back_btn = settings_container.get_node_or_null("Content/Stack/SettingsList/BackFromSettingsButton")
	style_btn.call(settings_back_btn)
	
	# Style the Change button
	var change_diff_btn = settings_container.get_node_or_null("Content/Stack/SettingsList/DifficultyContainer/ChangeButton")
	style_btn.call(change_diff_btn)
	
	# Style Level Select Back button
	var level_back_btn = level_select.get_node_or_null("Content/Stack/LevelList/BackButton")
	style_btn.call(level_back_btn)
	
	# Setup hover animations for main menu buttons
	for child in main_menu.get_children():
		if child is Button:
			setup_hover_anim(child)
	
	# Setup hover anims for other buttons
	if settings_back_btn: setup_hover_anim(settings_back_btn)
	if level_back_btn: setup_hover_anim(level_back_btn)
	if change_diff_btn: setup_hover_anim(change_diff_btn)

	# Screen Transition (Iris Open)
	if ScreenFaderScene:
		screen_fader = ScreenFaderScene.instantiate()
		add_child(screen_fader)
		screen_fader.fade_in_iris(1.5)
		
	# Zoom Fade In Animation for Main Menu buttons
	animate_buttons_intro()

func animate_buttons_intro():
	# Only animate if main menu is visible (it should be on start)
	if not main_menu.visible: return
	
	var buttons = []
	for child in main_menu.get_children():
		if child is Button or child is Control: # Include spacers if any
			buttons.append(child)
			
	# Initial state
	for btn in buttons:
		btn.scale = Vector2(0.1, 0.1)
		btn.modulate.a = 0.0
		# Reset pivot to center for scaling
		if btn is Control:
			btn.pivot_offset = btn.size / 2
			
	# Animate
	var delay = 0.0
	for btn in buttons:
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.5).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(delay)
		delay += 0.1

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
	button.pivot_offset = button.size / 2
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
	fade_in_menu(level_select)

func _on_settings_pressed():
	main_menu.visible = false
	fade_in_menu(settings_container)

func _on_back_pressed():
	fade_out_menu(level_select)
	main_menu.visible = true
	# Re-run animation when returning to main menu? 
	# User said "zoom fade in the buttons when the main menu loads".
	# If we just hide/show, it might be nice to re-animate.
	animate_buttons_intro()

func _on_back_from_settings_pressed():
	fade_out_menu(settings_container)
	main_menu.visible = true
	animate_buttons_intro()

func fade_in_menu(menu_node: Control):
	menu_node.visible = true
	menu_node.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(menu_node, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func fade_out_menu(menu_node: Control):
	var tween = create_tween()
	tween.tween_property(menu_node, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func(): menu_node.visible = false)

func _on_quit_pressed():
	# Ensure iris close animation plays before quitting
	if screen_fader:
		screen_fader.fade_out_iris(1.0)
		await screen_fader.fade_out_completed
		
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
		
		# Configure Button as a container
		btn.text = "" # No default text
		btn.custom_minimum_size = Vector2(0, 100) # Slightly taller for two lines
		
		# Create VBox for labels
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE # Let clicks pass to button
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.anchors_preset = Control.PRESET_FULL_RECT
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		btn.add_child(vbox)
		
		var is_unlocked = GlobalGameState.is_level_unlocked(level_id)
		
		# 1. Level Name Label (Large, Bold)
		var name_label = Label.new()
		name_label.text = level_data["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 32)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Make level name bold
		var bold_font = FontVariation.new()
		var sys_font = SystemFont.new()
		sys_font.font_names = PackedStringArray(["Sans-Serif"])
		bold_font.set_base_font(sys_font)
		bold_font.variation_embolden = 1.0
		name_label.add_theme_font_override("font", bold_font)
		
		vbox.add_child(name_label)
		
		# 2. Info Label (Small, Regular)
		var info_label = Label.new()
		info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_label.add_theme_font_size_override("font_size", 18)
		info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Use a lighter color or default
		info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		
		var info_text = ""
		
		if not is_unlocked:
			info_text = "[LOCKED]"
			btn.disabled = true
			info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
		else:
			var best_diff = GlobalGameState.get_best_completed_difficulty(level_id)
			if best_diff != -1:
				var stats = GlobalGameState.get_stats_for_difficulty(level_id, best_diff)
				var diff_name = GlobalGameState.get_difficulty_label(best_diff)
				if stats.has("time") and stats.has("lives"):
					info_text = "Completed (%s) - Time: %s | Lives: %d" % [diff_name, stats["time"], stats["lives"]]
				else:
					info_text = "Completed (%s)" % diff_name
		
		info_label.text = info_text
		vbox.add_child(info_label)
		
		# Apply styles with extra padding
		var padding_v = 20
		
		if btn_normal_style: 
			var s = btn_normal_style.duplicate()
			if s is StyleBoxFlat:
				s.content_margin_top = padding_v
				s.content_margin_bottom = padding_v
			btn.add_theme_stylebox_override("normal", s)
			
		if btn_hover_style: 
			var s = btn_hover_style.duplicate()
			if s is StyleBoxFlat:
				s.content_margin_top = padding_v
				s.content_margin_bottom = padding_v
			btn.add_theme_stylebox_override("hover", s)
			
		if btn_pressed_style: 
			var s = btn_pressed_style.duplicate()
			if s is StyleBoxFlat:
				s.content_margin_top = padding_v
				s.content_margin_bottom = padding_v
			btn.add_theme_stylebox_override("pressed", s)
			
		if btn_focus_style: 
			var s = btn_focus_style.duplicate()
			if s is StyleBoxFlat:
				s.content_margin_top = padding_v
				s.content_margin_bottom = padding_v
			btn.add_theme_stylebox_override("focus", s)
		
		# Apply colors from play button if available (we need to get play_btn again or store it)
		# For simplicity, we can assume hardcoded colors or re-fetch
		# btn.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1)) # Handled by labels now
		
		if is_unlocked:
			btn.pressed.connect(func(): start_level(level_id))
		
		# setup_hover_anim(btn) # Disabled as requested
			
		level_grid.add_child(btn)

func setup_controls_menu():
	if tilt_stick_toggle:
		var is_right = not GlobalGameState.tilt_uses_left_stick
		tilt_stick_toggle.button_pressed = is_right
		_update_tilt_toggle_text(is_right)
		
	if invert_tilt_check:
		invert_tilt_check.button_pressed = GlobalGameState.tilt_inverted
	if music_check:
		music_check.button_pressed = GlobalGameState.music_enabled

func _on_tilt_stick_toggled(pressed):
	# pressed = true -> Right Stick (1), false -> Left Stick (0)
	GlobalGameState.set_tilt_stick(not pressed)
	_update_tilt_toggle_text(pressed)

func _update_tilt_toggle_text(is_right: bool):
	if tilt_stick_toggle:
		tilt_stick_toggle.text = "Right Stick" if is_right else "Left Stick"

func _on_invert_tilt_toggled(pressed):
	GlobalGameState.set_tilt_inverted(pressed)

func _on_music_toggled(pressed):
	GlobalGameState.set_music_enabled(pressed)

func start_level(level_id: int):
	# Optional: Fade out with Iris before starting
	if screen_fader:
		screen_fader.fade_out_iris(2.0)
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
