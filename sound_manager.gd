extends Node

var num_players = 8
var available = []  # The available players.

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # Keep running during pause
	# Create the pool of AudioStreamPlayers.
	for i in num_players:
		var p = AudioStreamPlayer.new()
		add_child(p)
		available.append(p)
		p.finished.connect(_on_stream_finished.bind(p))
		p.bus = "Master"

func _on_stream_finished(stream):
	# When finished playing a stream, make the player available again.
	available.append(stream)

func play_sound(sound_path: String, volume_db: float = 0.0):
	var stream = load(sound_path)
	if stream:
		_play_stream(stream, volume_db)
	else:
		print("SoundManager: Could not load sound: ", sound_path)

func play_ui_hover():
	# Using the requested file for hover
	play_sound("res://sounds/click-buttons-ui-menu-sounds-effects-button-7-203601.mp3", -5.0)

func play_ui_click():
	# Using the requested file for click
	play_sound("res://sounds/beep-313342.mp3", -5.0)

func _play_stream(stream, volume_db):
	if available.size() > 0:
		var p = available.pop_front()
		p.stream = stream
		p.volume_db = volume_db
		p.play()
		# print("SoundManager: Playing sound")
	else:
		print("SoundManager: No available players")
