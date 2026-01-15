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
		if not resume_btn.pressed.is_connected(resume):
			resume_btn.pressed.connect(resume)
		setup_button_signals(resume_btn)

	if restart_btn:
		if not restart_btn.pressed.is_connected(restart_level):
			restart_btn.pressed.connect(restart_level)
		if not restart_btn.pressed.is_connected(restart_level):
			restart_btn.pressed.connect(restart_level)
		setup_button_signals(restart_btn)

	if menu_btn:
		if not menu_btn.pressed.is_connected(go_to_menu):
			menu_btn.pressed.connect(go_to_menu)
	if menu_btn:
		if not menu_btn.pressed.is_connected(go_to_menu):
			menu_btn.pressed.connect(go_to_menu)
		setup_button_signals(menu_btn)

func setup_button_signals(btn: Button):
	if not btn.mouse_entered.is_connected(_play_hover_sound):
		btn.mouse_entered.connect(_play_hover_sound)
	if not btn.pressed.is_connected(_play_click_sound):
		btn.pressed.connect(_play_click_sound)
	if not btn.focus_entered.is_connected(_on_button_focus_entered.bind(btn)):
		btn.focus_entered.connect(_on_button_focus_entered.bind(btn))
	if not btn.focus_exited.is_connected(_on_button_focus_exited.bind(btn)):
		btn.focus_exited.connect(_on_button_focus_exited.bind(btn))

func _play_hover_sound():
	if SoundManager:
		SoundManager.play_ui_hover()

func _play_click_sound():
	if SoundManager:
		SoundManager.play_ui_click()

var focus_tweens = {}
var original_focus_styles = {}

func _on_button_focus_entered(button: Button):
	var style = button.get_theme_stylebox("focus")
	if style:
		original_focus_styles[button] = style
		
		var style_dup = style.duplicate()
		button.add_theme_stylebox_override("focus", style_dup)
		
		var tween = create_tween().set_loops()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(style_dup, "border_color:a", 0.4, 0.8)
		tween.tween_property(style_dup, "border_color:a", 1.0, 0.8)
		
		focus_tweens[button] = tween

func _on_button_focus_exited(button: Button):
	if focus_tweens.has(button):
		var tween = focus_tweens[button]
		if tween:
			tween.kill()
		focus_tweens.erase(button)
	
	if original_focus_styles.has(button):
		var original = original_focus_styles[button]
		button.add_theme_stylebox_override("focus", original)
		original_focus_styles.erase(button)

func _input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if visible:
			resume()
		else:
			pause()
	
	# Lazy focus logic
	if visible and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion) and not get_viewport().gui_get_focus_owner():
		var resume_btn = $Control/CenterContainer/Card/ContentMargin/VBoxContainer/ResumeButton
		if resume_btn:
			resume_btn.grab_focus()
			get_viewport().set_input_as_handled()

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
	GlobalGameState.reset_level_timer()
	GlobalGameState.clear_collected()

func go_to_menu():
	resume() # Unpause before changing scene
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Ensure visible for menu
	get_tree().change_scene_to_file("res://main_menu.tscn")
