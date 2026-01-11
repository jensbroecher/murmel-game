extends Node

enum Difficulty { NORMAL, HARD, EASY }

const SAVE_FILE_PATH = "user://savegame.save"

var difficulty: Difficulty = Difficulty.NORMAL
var collected_diamond_ids: Array = []
var lives: int = 7
var tilt_uses_left_stick: bool = true
var tilt_inverted: bool = false
var music_enabled: bool = true

# Level Management
var current_level_index: int = 0
var level_start_time: int = 0
var timer_active: bool = false
var show_level_selection_on_load: bool = false
var level_progress: Dictionary = {}
var levels: Dictionary = {
	0: { "name": "Tutorial", "path": "res://stage_0.tscn", "concept_by": "Klaus Bröcher" },
	1: { "name": "Loops & Cannons", "path": "res://stage_1.tscn", "concept_by": "Jens Bröcher" },
	2: { "name": "Bumpy", "path": "res://stage_2.tscn", "concept_by": "Jens Bröcher" },
	3: { "name": "Mechanisms", "path": "res://stage_3.tscn", "concept_by": "Jens Bröcher" }
}

func _ready():
	load_game()

func register_collected(diamond_id: String):
	if not collected_diamond_ids.has(diamond_id):
		collected_diamond_ids.append(diamond_id)

func is_collected(diamond_id: String) -> bool:
	return collected_diamond_ids.has(diamond_id)

func clear_collected():
	collected_diamond_ids.clear()

func reset_lives():
	lives = 7

func lose_life() -> bool:
	if difficulty == Difficulty.EASY:
		return true # Unlimited lives
		
	lives -= 1
	return lives > 0

func start_level_timer():
	level_start_time = Time.get_ticks_msec()
	timer_active = true

func reset_level_timer():
	level_start_time = 0
	timer_active = false

func get_elapsed_time() -> String:
	if not timer_active:
		return "00:00"
		
	var current_time = Time.get_ticks_msec()
	var elapsed = current_time - level_start_time
	var seconds = (elapsed / 1000) % 60
	var minutes = (elapsed / 1000) / 60
	return "%02d:%02d" % [minutes, seconds]

func set_difficulty(new_difficulty: Difficulty):
	difficulty = new_difficulty
	save_game()
func set_tilt_stick(use_left: bool):
	tilt_uses_left_stick = use_left
	save_game()
func set_tilt_inverted(inverted: bool):
	tilt_inverted = inverted
	save_game()

func set_music_enabled(enabled: bool):
	music_enabled = enabled
	save_game()
	# Notify MusicManager if it exists
	var music_manager = get_node_or_null("/root/MusicManager")
	if music_manager:
		music_manager.update_music_state()

func get_difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY: return "Easy"
		Difficulty.NORMAL: return "Normal"
		Difficulty.HARD: return "Hard"
	return "Normal"

func get_difficulty_description() -> String:
	match difficulty:
		Difficulty.EASY: return "Unlimited Tries"
		Difficulty.NORMAL: return "7 Tries"
		Difficulty.HARD: return "7 Tries + Reset on Fail"
	return ""

func complete_level(level_id: int, time_str: String, lives_left: int):
	print("Level %d Completed! Time: %s, Lives: %d" % [level_id, time_str, lives_left])
	
	if not level_progress.has(level_id):
		level_progress[level_id] = {}
	
	# Save progress for specific difficulty
	level_progress[level_id][difficulty] = {
		"completed": true,
		"time": time_str,
		"lives": lives_left
	}
	
	save_game()

func is_level_unlocked(level_id: int) -> bool:
	if level_id == 0 or level_id == 1:
		return true
	
	# Check if previous level is completed on ANY difficulty
	var prev_id = level_id - 1
	if level_progress.has(prev_id) and not level_progress[prev_id].is_empty():
		return true
		
	return false

func get_level_stats(level_id: int) -> Dictionary:
	if level_progress.has(level_id):
		# Return stats for current difficulty if available
		if level_progress[level_id].has(difficulty):
			return level_progress[level_id][difficulty]
	return {}

func get_best_completed_difficulty(level_id: int) -> int:
	if not level_progress.has(level_id):
		return -1
	
	if level_progress[level_id].has(Difficulty.HARD):
		return Difficulty.HARD
	if level_progress[level_id].has(Difficulty.NORMAL):
		return Difficulty.NORMAL
	if level_progress[level_id].has(Difficulty.EASY):
		return Difficulty.EASY
		
	return -1

func get_stats_for_difficulty(level_id: int, diff: int) -> Dictionary:
	if level_progress.has(level_id) and level_progress[level_id].has(diff):
		return level_progress[level_id][diff]
	return {}

func get_difficulty_label(diff: int) -> String:
	match diff:
		Difficulty.EASY: return "Easy"
		Difficulty.NORMAL: return "Normal"
		Difficulty.HARD: return "Hard"
	return "Unknown"

func save_game():
	var save_data = {
		"difficulty": difficulty,
		"level_progress": level_progress,
		"tilt_uses_left_stick": tilt_uses_left_stick,
		"tilt_inverted": tilt_inverted,
		"music_enabled": music_enabled
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		print("Game saved.")
	else:
		print("Failed to save game.")

func load_game():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found.")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.get_data()
			if data.has("difficulty"):
				difficulty = int(data["difficulty"])
			if data.has("level_progress"):
				var raw_progress = data["level_progress"]
				level_progress = {}
				for key in raw_progress:
					var level_id = int(key)
					var stats = raw_progress[key]
					
					# Migration check: If stats has "completed" directly, it's old format
					if stats.has("completed") and not stats.has(str(Difficulty.NORMAL)):
						# Convert to new format (assume Normal difficulty for old saves)
						level_progress[level_id] = {
							Difficulty.NORMAL: stats
						}
					else:
						# New format: keys are difficulty enum ints (stored as strings in JSON)
						level_progress[level_id] = {}
						for diff_key in stats:
							level_progress[level_id][int(diff_key)] = stats[diff_key]
			
			if data.has("tilt_uses_left_stick"):
				tilt_uses_left_stick = bool(data["tilt_uses_left_stick"])
			if data.has("tilt_inverted"):
				tilt_inverted = bool(data["tilt_inverted"])
			if data.has("music_enabled"):
				music_enabled = bool(data["music_enabled"])
			print("Game loaded.")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
