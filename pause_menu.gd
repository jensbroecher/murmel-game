extends CanvasLayer

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect signals
	var resume_btn = $Control/CenterContainer/VBoxContainer/ResumeButton
	var menu_btn = $Control/CenterContainer/VBoxContainer/MenuButton
	
	if resume_btn:
		if not resume_btn.pressed.is_connected(resume):
			resume_btn.pressed.connect(resume)

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

func resume():
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func go_to_menu():
	resume() # Unpause before changing scene
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Ensure visible for menu
	get_tree().change_scene_to_file("res://main_menu.tscn")
