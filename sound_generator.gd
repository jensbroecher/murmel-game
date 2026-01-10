extends Node

var spawn_player: AudioStreamPlayer
var win_player: AudioStreamPlayer
var roll_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var hit_player: AudioStreamPlayer
var splash_player: AudioStreamPlayer

var marble_body: RigidBody3D
var is_dampened: bool = false
var time_accumulator: float = 0.0

func _ready():
	# Create players
	spawn_player = AudioStreamPlayer.new()
	add_child(spawn_player)
	
	win_player = AudioStreamPlayer.new()
	add_child(win_player)
	
	roll_player = AudioStreamPlayer.new()
	add_child(roll_player)
	
	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	
	hit_player = AudioStreamPlayer.new()
	add_child(hit_player)
	
	splash_player = AudioStreamPlayer.new()
	add_child(splash_player)
	
	# Generate sounds
	var spawn_sound = load("res://sounds/teleport-whoosh-453276.mp3")
	if spawn_sound:
		spawn_player.stream = spawn_sound
	else:
		spawn_player.stream = generate_sine_sweep(400, 1000, 1.0)
	
	win_player.stream = load("res://sounds/success-videogame-sfx-423626.mp3")
	if not win_player.stream:
		win_player.stream = generate_win_sound()
		
	# Rolling sound: New generator for marble
	roll_player.stream = load("res://sounds/marble.mp3")
	if not roll_player.stream:
		roll_player.stream = generate_rolling_sound()
	if roll_player.stream is AudioStreamMP3:
		roll_player.stream.loop = true
	
	# Ambient sound: Old noise loop for waves/wind
	ambient_player.stream = generate_noise_loop()
	
	hit_player.stream = generate_hit_sound()
	
	splash_player.stream = load("res://sounds/water-splash-02-352021.mp3")
	
	# Start sounds
	roll_player.volume_db = -35.0
	roll_player.play()
	
	ambient_player.volume_db = -30.0
	ambient_player.play()
	
	print("SoundGenerator: Sounds initialized")

func _process(delta):
	time_accumulator += delta
	
	# Ambient Wave Sound Logic
	if not ambient_player.playing:
		ambient_player.play()
	
	# Modulate ambient sound to simulate waves (slow sine wave)
	var wave_mod = sin(time_accumulator * 0.5) * 3.0
	ambient_player.volume_db = -33.0 + wave_mod
	ambient_player.pitch_scale = 1.0 + (sin(time_accumulator * 0.3) * 0.1)
	
	# Rolling Sound Logic
	if not roll_player.playing:
		roll_player.play()
		
	if marble_body:
		var speed = marble_body.linear_velocity.length()
		var is_touching = marble_body.get_contact_count() > 0
		
		# If dampened (inside cannon), force a low speed equivalent or dampen volume directly
		var target_vol = -80.0
		var target_pitch = 1.0
		
		if is_dampened:
			# Keep playing but muffled/quiet
			target_vol = -30.0 
			target_pitch = 0.5
		elif not is_touching:
			# In air: Silence rolling sound
			target_vol = -80.0
			# Keep pitch similar to last known speed or drop it, doesn't matter much if silent
			target_pitch = 1.0 
		elif speed > 0.02:
			# Bowling ball rolling: heavy, deep rumble
			# Volume: Boosted significantly as requested
			# Speed 5.0 -> 0dB. Speed 0.5 -> -20dB.
			target_vol = clamp(linear_to_db(speed / 5.0), -25.0, 2.0)
			
			# Pitch: Controls the rumble frequency (speed of rotation)
			# Slower ramp for pitch to avoid chipmunk effect with MP3
			target_pitch = clamp(0.6 + (speed / 15.0), 0.6, 1.2)
		
		roll_player.volume_db = lerp(roll_player.volume_db, target_vol, delta * 10.0)
		roll_player.pitch_scale = lerp(roll_player.pitch_scale, target_pitch, delta * 10.0)

	else:
		roll_player.volume_db = -80.0

func set_marble(body):
	marble_body = body
	print("SoundGenerator: Marble set")

func set_dampened(dampened: bool):
	is_dampened = dampened
	print("SoundGenerator: Dampening set to ", dampened)

func play_spawn():
	spawn_player.volume_db = 0.0
	spawn_player.play()
	print("SoundGenerator: Playing Spawn Sound")

func play_win():
	win_player.volume_db = 5.0
	win_player.play()
	print("SoundGenerator: Playing Win Sound")

func play_hit(intensity: float):
	# Reduced volume further (-15dB) to make it subtle
	hit_player.volume_db = linear_to_db(clamp(intensity, 0.1, 1.0)) - 15.0
	hit_player.pitch_scale = randf_range(0.9, 1.1)
	hit_player.play()
	print("SoundGenerator: Playing Hit Sound")

func play_splash():
	if splash_player.stream:
		splash_player.volume_db = -5.0
		splash_player.pitch_scale = randf_range(0.9, 1.1)
		splash_player.play()
		print("SoundGenerator: Playing Splash Sound")

func generate_hit_sound():
	var sample_rate = 44100
	var duration = 0.2
	var frames = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	for i in range(frames):
		var t = float(i) / frames
		var sample = randf_range(-1.0, 1.0)
		
		# Envelope: Fast decay
		var envelope = exp(-20.0 * t)
		sample *= envelope
		
		var sample_16 = int(sample * 32000.0)
		buffer.encode_s16(i * 2, sample_16)
		
	stream.data = buffer
	return stream

func generate_switch_melody():
	var sample_rate = 44100
	var duration = 1.0
	var frames = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	# Simple arpeggio: C5, E5, G5, C6
	var notes = [523.25, 659.25, 783.99, 1046.50]
	var note_duration = frames / 4
	var phase = 0.0
	
	for i in range(frames):
		var note_idx = int(i / note_duration)
		if note_idx >= notes.size(): note_idx = notes.size() - 1
		
		var freq = notes[note_idx]
		var increment = (freq * 2.0 * PI) / sample_rate
		phase += increment
		
		var sample = sin(phase)
		
		# Envelope per note
		var local_t = float(i % note_duration) / note_duration
		var envelope = 1.0
		if local_t < 0.1: envelope = local_t / 0.1
		else: envelope = exp(-5.0 * (local_t - 0.1))
		
		sample *= envelope * 0.3
		
		var sample_16 = int(sample * 32767.0)
		buffer.encode_s16(i * 2, sample_16)
		
	stream.data = buffer
	return stream

# Generators
func generate_sine_sweep(start_hz, end_hz, duration):
	var sample_rate = 44100
	var frames = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2) # 2 bytes per sample
	
	var phase = 0.0
	
	for i in range(frames):
		var t = float(i) / frames
		var freq = lerp(float(start_hz), float(end_hz), t)
		var increment = (freq * 2.0 * PI) / sample_rate
		phase += increment
		
		var sample = sin(phase)
		# Apply envelope (fade in/out)
		var envelope = 1.0
		if t < 0.1: envelope = t / 0.1
		elif t > 0.9: envelope = (1.0 - t) / 0.1
		
		sample *= envelope * 0.5 # 0.5 amplitude
		
		var sample_16 = int(sample * 32767.0)
		buffer.encode_s16(i * 2, sample_16)
		
	stream.data = buffer
	return stream

func generate_rolling_sound():
	var sample_rate = 44100
	# Loop length determines the fundamental "wobble" frequency
	# 8820 samples = 0.2 seconds = 5Hz fundamental at pitch 1.0
	var frames = 8820
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frames
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	var last_val = 0.0
	
	for i in range(frames):
		# 1. Base Texture (Grit)
		var target = randf_range(-1.0, 1.0)
		last_val = lerp(last_val, target, 0.2) # Moderate smoothing for stone texture
		
		# 2. Modulation (The "Rum-ble" effect)
		# Reduced modulation depth to avoid "ticking" sound in fallback
		var angle = (float(i) / frames) * 2.0 * PI
		var mod = 0.8 + 0.2 * sin(angle) # Smoother
		
		# 3. Low Frequency Hum (The heavy mass)
		var hum = sin(angle) * 0.2
		
		# Mix: Modulated noise + Hum
		var final = (last_val * mod * 0.6) + hum
		
		# Soft clip
		final = clamp(final, -1.0, 1.0)
		
		var sample_16 = int(final * 32000.0)
		buffer.encode_s16(i * 2, sample_16)
		
	stream.data = buffer
	return stream

func generate_noise_loop():
	var sample_rate = 44100
	var duration = 2.0
	var frames = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frames
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	var last_val = 0.0
	var last_val2 = 0.0
	
	for i in range(frames):
		# Double smoothed noise for deeper rumble (Low-pass filter)
		var target = randf_range(-1.0, 1.0)
		last_val = lerp(last_val, target, 0.15)
		last_val2 = lerp(last_val2, last_val, 0.15)
		
		var sample_16 = int(last_val2 * 32000.0 * 1.0)
		buffer.encode_s16(i * 2, sample_16)
		
	stream.data = buffer
	return stream

func generate_win_sound():
	var sample_rate = 44100
	var duration = 2.0
	var frames = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	
	var buffer = PackedByteArray()
	buffer.resize(frames * 2)
	
	# C Major Chord: C4 (261.6), E4 (329.6), G4 (392.0)
	var freqs = [261.63, 329.63, 392.00, 523.25] # C4, E4, G4, C5
	var phases = [0.0, 0.0, 0.0, 0.0]
	
	for i in range(frames):
		var sample = 0.0
		for j in range(freqs.size()):
			var increment = (freqs[j] * 2.0 * PI) / sample_rate
			phases[j] += increment
			sample += sin(phases[j])
		
		sample /= freqs.size() # Normalize
		
		# Envelope: Fast attack, slow decay
		var t = float(i) / frames
		var envelope = 1.0
		if t < 0.05: envelope = t / 0.05
		else: envelope = exp(-3.0 * (t - 0.05))
		
		sample *= envelope * 0.5
		
		var sample_16 = int(sample * 32767.0)
		buffer.encode_s16(i * 2, sample_16)
		
	stream.data = buffer
	return stream
