extends Node

var audio_player: AudioStreamPlayer
var playlist: Array = []
var current_track_index: int = -1

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep running during pause
	
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master" # Or "Music" if we had buses
	add_child(audio_player)
	
	audio_player.finished.connect(_on_track_finished)
	
	load_music()
	
	# Start music if enabled
	update_music_state()

func load_music():
	var dir = DirAccess.open("res://music")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(".mp3"):
				playlist.append("res://music/" + file_name)
			file_name = dir.get_next()
		
		# Sort playlist to ensure consistent ordering across runs
		playlist.sort()
		print("MusicManager: Loaded %d tracks" % playlist.size())

func update_music_state():
	if GlobalGameState.music_enabled:
		if not audio_player.playing:
			# If a level is loaded, play its music, otherwise play menu music (index 0 or random)
			play_music_for_level(GlobalGameState.current_level_index)
	else:
		audio_player.stop()

func play_music_for_level(level_index: int):
	if playlist.is_empty():
		return
		
	if not GlobalGameState.music_enabled:
		return
		
	# Map level index to a track index. Use modulo if we have fewer tracks than levels.
	# We can reserve track 0 for menu if we want, but simple mapping is fine for now.
	var track_index = level_index % playlist.size()
	
	# If different from current track, switch
	if current_track_index != track_index or not audio_player.playing:
		current_track_index = track_index
		var stream = load(playlist[current_track_index])
		
		if stream:
			audio_player.stream = stream
			audio_player.volume_db = -15.0 # Background level
			audio_player.play()
			print("MusicManager: Playing track for level %d: %s" % [level_index, playlist[current_track_index]])

func play_next_track():
	# Legacy fallback or for menu shuffling if desired
	play_music_for_level(current_track_index + 1)


func _on_track_finished():
	play_next_track()
