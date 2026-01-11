extends CanvasLayer

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect signals
	var resume_btn = $Control/CenterContainer/Card/ContentMargin/VBoxContainer/ResumeButton
	var restart_btn = $Control/CenterContainer/Card/ContentMargin/VBoxContainer/RestartButton
	var menu_btn = $Control/CenterContainer/Card/ContentMargin/VBoxContainer/MenuButton
	
	if resume_btn:
		if not resume_btn.pressed.is_connected(resume):
			resume_btn.pressed.connect(resume)

	if restart_btn:
		if not restart_btn.pressed.is_connected(restart_level):
			restart_btn.pressed.connect(restart_level)

	if menu_btn:
		if not menu_btn.pressed.is_connected(go_to_menu):
			menu_btn.pressed.connect(go_to_menu)

func _input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if visible:
			resume()
		else:
			pause()

func pause():
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Animate card
	var card = $Control/CenterContainer/Card
	if card:
		card.scale = Vector2(0.8, 0.8)
		card.modulate.a = 0.0
		var tween = create_tween().set_parallel(true)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func resume():
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func restart_level():
	resume() # Unpause
	get_tree().reload_current_scene()
	# Reset level specific state if needed
	GlobalGameState.start_level_timer()
	GlobalGameState.clear_collected()

func go_to_menu():
	resume() # Unpause before changing scene
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Ensure visible for menu
	get_tree().change_scene_to_file("res://main_menu.tscn")
