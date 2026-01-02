extends Control

@onready var difficulty_label = $VBoxContainer/DifficultyContainer/DifficultyValue
@onready var main_menu = $VBoxContainer
@onready var level_select = $LevelSelectContainer
@onready var level_grid = $LevelSelectContainer/LevelGrid

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_difficulty_display()
	setup_level_buttons()
	
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

func _on_back_pressed():
	level_select.visible = false
	main_menu.visible = true

func _on_quit_pressed():
	get_tree().quit()

func setup_level_buttons():
	# Clear existing children if any
	for child in level_grid.get_children():
		child.queue_free()
		
	for level_id in GlobalGameState.levels:
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

func start_level(level_id: int):
	GlobalGameState.current_level_index = level_id
	GlobalGameState.reset_lives()
	GlobalGameState.clear_collected()
	GlobalGameState.start_level_timer() # Reset timer for new game
	
	var level_path = GlobalGameState.levels[level_id]["path"]
	get_tree().change_scene_to_file(level_path)
