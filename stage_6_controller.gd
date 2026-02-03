extends "res://game_manager.gd"

# Array to hold all level pivots in the scene
var level_pivots: Array[Node3D] = []
var active_pivot_index: int = 0
var pivots_configured: bool = false

func _ready():
	# Find all LevelPivot nodes
	for child in get_children():
		if "LevelPivot" in child.name and child.has_method("set_marble"):
			if not level_pivots.has(child):
				level_pivots.append(child)
			
	# Sort by name
	level_pivots.sort_custom(func(a, b): return a.name.naturalnocasecmp_to(b.name) < 0)
	
	print("Stage 6 DEBUG: Found pivots: ", level_pivots.map(func(n): return n.name))

	if level_pivots.size() > 0:
		set_active_pivot(0)

	super._ready() # This calls spawn_marble which calls set_marble on pivots

func spawn_marble():
	# Parent's spawn_marble is async (waits 1s), so we can't configure immediately.
	# We rely on _process to detect when the marble arrives.
	super.spawn_marble()
	pivots_configured = false

func _process(delta):
	super._process(delta)
	
	if not pivots_configured:
		var marble = get_node_or_null("Marble")
		if marble:
			print("Stage 6: Configuring pivots for marble")
			for pivot in level_pivots:
				if pivot.has_method("set_marble"):
					pivot.set_marble(marble)
				if pivot.has_method("set_camera"):
					if camera_rig:
						pivot.set_camera(camera_rig)
			
			update_camera_target()
			pivots_configured = true
	


func _physics_process(delta):
	super._physics_process(delta)
	
	# Continuous distance check
	var marble = get_node_or_null("Marble")
	if marble and level_pivots.size() > 1:
		var closest_index = -1
		var min_dist_sq = INF
		
		for i in range(level_pivots.size()):
			var pivot = level_pivots[i]
			# Calculate global distance. Pivot origin is the center of rotation/activity usually.
			var dist_sq = marble.global_position.distance_squared_to(pivot.global_position)
			
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest_index = i
		
		# Only switch if we are clearly closer to another pivot (Hysteresis)
		# Just checking closest is fine for now, or add a buffer.
		if closest_index != -1 and closest_index != active_pivot_index:
			set_active_pivot(closest_index)
	
	# Enforce locks (inactive pivots should stay locked even if tunnel unlocks them)
	for i in range(level_pivots.size()):
		if i != active_pivot_index:
			var pivot = level_pivots[i]
			if "input_enabled" in pivot and pivot.input_enabled:
				if pivot.has_method("neutralize_and_lock"):
					pivot.neutralize_and_lock()
				elif pivot.has_method("set_input_enabled"):
					pivot.set_input_enabled(false)

func set_active_pivot(index: int):
	if index < 0 or index >= level_pivots.size():
		return
		
	active_pivot_index = index
	# print("Switching to Pivot Index: ", index)
	
	for i in range(level_pivots.size()):
		var pivot = level_pivots[i]
		if i == index:
			if pivot.has_method("unlock"):
				pivot.unlock()
			# Also ensure input is enabled if unlock doesn't do it (fallback)
			elif pivot.has_method("set_input_enabled"):
				pivot.set_input_enabled(true)
		else:
			if pivot.has_method("neutralize_and_lock"):
				pivot.neutralize_and_lock()
			elif pivot.has_method("set_input_enabled"):
				pivot.set_input_enabled(false)
	
	update_camera_target()

func update_camera_target():
	if camera_rig:
		camera_rig.target_node = get_node_or_null("Marble")

func _on_finish_trigger_body_entered(body):
	if body.name == "Marble":
		if collected_diamonds < total_diamonds:
			show_message("Collect all diamonds first!")
			return

		win_label.visible = true
		win_label.text = "STAGE CLEARED\nTime: " + GlobalGameState.get_elapsed_time()
		if sound_gen:
			sound_gen.play_win()
		print("You Won!")
		GlobalGameState.complete_level(GlobalGameState.current_level_index, GlobalGameState.get_elapsed_time(), GlobalGameState.lives)
		
		# Launch Rocket - Search in all pivots
		var rocket = null
		for pivot in level_pivots:
			rocket = pivot.get_node_or_null("Rocket")
			if rocket:
				break
		
		# Also check direct children of the stage (just in case it's not in a pivot)
		if not rocket:
			rocket = get_node_or_null("Rocket")

		if rocket and rocket.has_method("launch"):
			rocket.launch(body)
			return
		
		# Fallback if rocket not found (should not happen in Stage 6)
		# We must avoid calling _play_despawn_effect in parent unless we override it too,
		# because it looks for LevelPivot/FinishTrigger.
		
		# Simple fallback exit
		await get_tree().create_timer(4.0).timeout
		GlobalGameState.reset_lives()
		GlobalGameState.clear_collected()
		GlobalGameState.show_level_selection_on_load = true
		get_tree().change_scene_to_file("res://main_menu.tscn")
