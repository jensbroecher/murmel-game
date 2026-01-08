extends Control

@onready var main_menu = $VBoxContainer
@onready var level_select = $LevelSelectContainer
@onready var level_grid = $LevelSelectContainer/LevelGrid
@onready var settings_container = $SettingsContainer

@onready var difficulty_label = $SettingsContainer/DifficultyContainer/DifficultyValue
@onready var tilt_stick_option = $SettingsContainer/ControlsContainer/TiltStickOption
@onready var invert_tilt_check = $SettingsContainer/ControlsContainer/InvertTiltCheck
@onready var music_check = $SettingsContainer/MusicContainer/MusicCheck

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_difficulty_display()
	setup_level_buttons()
	setup_controls_menu()
	
	# Play menu music (Track 0)
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.play_music_for_level(0)
	
	if GlobalGameState.show_level_selection_on_load:
		_on_levels_pressed()
		GlobalGameState.show_level_selection_on_load = false
	
	# Connect buttons (assuming nodes exist, otherwise will need to connect in editor or code)
	# For this implementation, I will rely on the scene structure matching this script

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
		
		if is_unlocked:
			btn.pressed.connect(func(): start_level(level_id))
			
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
