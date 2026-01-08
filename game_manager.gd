extends Node3D

@export var marble_scene: PackedScene
@export var ripple_scene: PackedScene

const ScreenFaderScene = preload("res://screen_fader.tscn")
const PauseMenuScene = preload("res://pause_menu.tscn")

@onready var win_label = $HUD/WinLabel
@onready var lives_label = $HUD/LivesLabel
@onready var start_point = $StartPoint
@onready var spawn_particles = $StartPoint/SpawnParticles
@onready var camera_rig = $CameraRig
@onready var sound_gen = $SoundGenerator
@onready var level_pivot = $LevelPivot

var screen_fader
var last_hit_time: int = 0
var total_diamonds: int = 0
var collected_diamonds: int = 0
var last_velocity = Vector3.ZERO

func _physics_process(delta):
	if camera_rig and camera_rig.target_node:
		var marble = camera_rig.target_node
		if marble is RigidBody3D:
			var current_velocity = marble.linear_velocity
			
			# Calculate change in velocity (Impulse/Shock)
			# This detects sudden stops or bounces (walls/floor) but ignores smooth rolling
			var velocity_change = (current_velocity - last_velocity).length()
			
			# Threshold for impact sound
			# Normal gravity accel per frame (at 60fps) is ~0.16
			# A collision usually causes a change > 1.0 depending on speed
			# Using 2.0 filters out small bumps and rail transitions
			if velocity_change > 2.0: 
				var current_time = Time.get_ticks_msec()
				if current_time - last_hit_time > 100: # Short debounce
					var intensity = clamp(velocity_change / 15.0, 0.0, 1.0)
					if sound_gen:
						sound_gen.play_hit(intensity)
					last_hit_time = current_time
			
			last_velocity = current_velocity

func _ready():
	randomize()
	
	# Start timer if this is the first load of the level (start time is 0)
	# If start time is not 0, it means we respawned (reload scene), so timer continues
	if GlobalGameState.level_start_time == 0:
		GlobalGameState.start_level_timer()
	
	call_deferred("count_diamonds")
	
	# Update count based on already collected
	call_deferred("restore_collected_count")
	
	# Instantiate Screen Fader if not present
	if ScreenFaderScene:
		screen_fader = ScreenFaderScene.instantiate()
		add_child(screen_fader)
		# Start with fade in (White -> Transparent)
		screen_fader.fade_in(2.0)
	
	# Instantiate Pause Menu
	if PauseMenuScene:
		var pause_menu = PauseMenuScene.instantiate()
		add_child(pause_menu)
		# Ensure mouse is captured for gameplay
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if win_label:
		win_label.visible = false
	
	update_lives_display()
	
	if has_node("TutorialOverlay"):
		var tutorial = get_node("TutorialOverlay")
		if tutorial.has_signal("tutorial_completed"):
			tutorial.tutorial_completed.connect(spawn_marble)
	else:
		spawn_marble()

func update_lives_display():
	if lives_label:
		if GlobalGameState.difficulty == GlobalGameState.Difficulty.EASY:
			lives_label.text = "Lives: Unlimited"
		else:
			lives_label.text = "Lives: %d" % GlobalGameState.lives

func spawn_marble():
	# Pre-position camera
	# if camera_rig and start_point:
	# 	camera_rig.global_position = start_point.global_position
	
	# Disable input during spawn
	if level_pivot and "input_enabled" in level_pivot:
		level_pivot.input_enabled = false
	
	if spawn_particles:
		spawn_particles.emitting = true
		if sound_gen:
			sound_gen.play_spawn()
	
	# Wait for effect
	await get_tree().create_timer(1.0).timeout
	
	if marble_scene:
		var marble = marble_scene.instantiate()
		marble.name = "Marble" # Ensure name matches for win condition
		marble.reset_threshold = -9999.0 # Disable marble's internal reset
		add_child(marble)
		marble.global_position = start_point.global_position
		marble.freeze = true # Hold in place initially
		
		# Animate Marble Spawn (Transparent -> White Glow -> Metallic)
		var mesh_instance = marble.get_node("MeshInstance3D")
		if mesh_instance:
			# Duplicate material to modify it uniquely
			var mat = mesh_instance.mesh.surface_get_material(0).duplicate()
			mesh_instance.material_override = mat
			
			# Initial State: Transparent & Glowing White
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.0
			mat.emission_enabled = true
			mat.emission = Color.WHITE
			mat.emission_energy_multiplier = 16.0
			
			# Tween Animation
			var tween = get_tree().create_tween()
			# 1. Fade in (Transparent -> Opaque White)
			tween.tween_property(mat, "albedo_color:a", 1.0, 0.2)
			# 2. Hold for 1 second (White Glowing Orb)
			tween.tween_interval(1.0)
			# 3. Quick Transition (White -> Metallic) & Unfreeze
			tween.tween_property(mat, "emission_energy_multiplier", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tween.parallel().tween_callback(func(): 
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				marble.freeze = false
				
				# Enable input when marble is ready
				if level_pivot and "input_enabled" in level_pivot:
					level_pivot.input_enabled = true
			).set_delay(0.1) # Small delay to ensure transparency is off during fade
		
		if sound_gen:
			sound_gen.set_marble(marble)
		
		# Pass marble to LevelController for custom physics (acceleration)
		if level_pivot and level_pivot.has_method("set_marble"):
			level_pivot.set_marble(marble)
		
		# Pass camera to LevelController
		if level_pivot and level_pivot.has_method("set_camera") and camera_rig:
			level_pivot.set_camera(camera_rig)
		
		# Assign camera target
		if camera_rig:
			camera_rig.target_node = marble
		
		# Connect collision for sound
		marble.contact_monitor = true
		marble.max_contacts_reported = 3
		marble.body_entered.connect(_on_marble_collision)

func _on_marble_collision(body):
	# Sound logic is now handled in _physics_process based on velocity change (impulse)
	pass

func count_diamonds():
	# Total is the sum of currently active diamonds + already collected ones
	var active_diamonds = get_tree().get_nodes_in_group("diamonds")
	total_diamonds = active_diamonds.size() + GlobalGameState.collected_diamond_ids.size()
	print("Total diamonds: ", total_diamonds)

func restore_collected_count():
	collected_diamonds = GlobalGameState.collected_diamond_ids.size()
	print("Restored collected count: ", collected_diamonds)

func collect_diamond():
	collected_diamonds += 1
	print("Collected: ", collected_diamonds, "/", total_diamonds)
	
	if collected_diamonds >= total_diamonds:
		show_message("Ready to Launch!", 3.0)

func show_message(text: String, duration: float = 2.0):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.anchors_preset = Control.PRESET_CENTER
	# Center on screen
	label.anchor_left = 0.5
	label.anchor_top = 0.3 # Slightly above center to not overlap with win label potentially
	label.anchor_right = 0.5
	label.anchor_bottom = 0.3
	
	if $HUD:
		$HUD.add_child(label)
	else:
		add_child(label) # Fallback
	
	var tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func _on_finish_trigger_body_entered(body):
	if body.name == "Marble":
		if collected_diamonds < total_diamonds:
			show_message("Collect all diamonds first!")
			return

		win_label.visible = true
		win_label.text = "YOU WIN!\nTime: " + GlobalGameState.get_elapsed_time()
		if sound_gen:
			sound_gen.play_win()
		print("You Won!")
		GlobalGameState.complete_level(GlobalGameState.current_level_index, GlobalGameState.get_elapsed_time(), GlobalGameState.lives)
		
		# Launch Rocket
		var rocket = level_pivot.get_node_or_null("Rocket")
		if rocket and rocket.has_method("launch"):
			rocket.launch()
		
		# Despawn Effect
		_play_despawn_effect(body)
		
		# Return to Menu after delay
		await get_tree().create_timer(4.0).timeout
		GlobalGameState.reset_lives()
		GlobalGameState.clear_collected()
		GlobalGameState.show_level_selection_on_load = true
		get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_water_entered(body):
	if body.name == "Marble":
		# Spawn ripple
		if ripple_scene:
			# Spawn main ripple (Big)
			var ripple = ripple_scene.instantiate()
			ripple.target_scale_size = 2.5
			add_child(ripple)
			ripple.global_position = Vector3(body.global_position.x, -20.0, body.global_position.z)
			ripple.rotation = Vector3.ZERO
			
			# Spawn extra smaller ripples
			for i in range(4):
				var extra_ripple = ripple_scene.instantiate()
				extra_ripple.target_scale_size = randf_range(0.2, 0.8)
				add_child(extra_ripple)
				var offset = Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
				extra_ripple.global_position = Vector3(body.global_position.x, -20.0, body.global_position.z) + offset
				extra_ripple.rotation = Vector3.ZERO
		
		# Play splash sound
		if sound_gen: sound_gen.play_splash()
		
		# Dampen velocity to simulate water drag
		body.linear_velocity *= 0.1
		body.angular_velocity *= 0.1
		
		# Fade to white and reset
		if screen_fader:
			screen_fader.fade_out(1.0)
			await screen_fader.fade_out_completed
			handle_respawn()
		else:
			# Fallback if fader missing
			await get_tree().create_timer(1.0).timeout
			handle_respawn()

func handle_respawn():
	# In Hard Mode, diamonds reset on respawn
	if GlobalGameState.difficulty == GlobalGameState.Difficulty.HARD:
		GlobalGameState.clear_collected()

	if GlobalGameState.lose_life():
		# Still have lives
		get_tree().reload_current_scene()
	else:
		# Game Over
		show_game_over()

func show_game_over():
	show_message("GAME OVER", 5.0)
	if win_label:
		win_label.text = "GAME OVER"
		win_label.visible = true
	
	# Reset game state after delay
	await get_tree().create_timer(5.0).timeout
	GlobalGameState.reset_lives()
	GlobalGameState.clear_collected()
	GlobalGameState.show_level_selection_on_load = true
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _play_despawn_effect(marble):
	# Disable physics
	marble.freeze = true
	marble.linear_velocity = Vector3.ZERO
	marble.angular_velocity = Vector3.ZERO
	
	# Disable collision to prevent weird interactions
	var collider = marble.get_node("CollisionShape3D")
	if collider: collider.disabled = true
	
	# Animate into the portal
	var tween = get_tree().create_tween()
	# Assuming the portal is at the same location as the finish trigger
	var portal_pos = $LevelPivot/FinishTrigger.global_position
	# Move to center
	tween.tween_property(marble, "global_position", portal_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Scale down and rotate
	tween.parallel().tween_property(marble, "scale", Vector3.ZERO, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(marble, "rotation", Vector3(0, 10, 0), 0.5)
	
	# Remove after animation
	tween.tween_callback(marble.queue_free)

func respawn_marble():
	if screen_fader:
		screen_fader.fade_out(1.0)
		await screen_fader.fade_out_completed
		get_tree().reload_current_scene()
		screen_fader.fade_in(1.0)
	else:
		get_tree().reload_current_scene()
