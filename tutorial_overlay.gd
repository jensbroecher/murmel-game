extends CanvasLayer

signal tutorial_completed

@onready var label = $Control/CardContainer/Card/ContentMargin/VBoxContainer/Label
@onready var button = $Control/CardContainer/Card/ContentMargin/VBoxContainer/Button

var steps = [
	"Welcome to HardTilt - Marble Run Challenge!\n\nYour goal is to navigate the Marblebot to the spaceship and collect all the diamonds in a stage.\n\nAvoid falling off the edge!",
	"Controls:\n\nUse the Left Stick (or touch/drag) to tilt the floor.\nThe marble will roll due to gravity. Good luck!"
]

var current_step = 0
var tutorial_active = true

func _ready():
	# Ensure UI processes even when game is paused (though we aren't using pause mode here, just disabling input)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Make mouse visible for tutorial
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	update_text()
	
	# Disable input on the level controller
	# We defer this slightly to ensure the level is fully ready
	call_deferred("disable_level_input")
	
	# Animate intro
	animate_intro()

func animate_intro():
	# Initial state
	var bg = $Control/ColorRect
	var card = $Control/CardContainer/Card
	
	bg.modulate.a = 0.0
	card.scale = Vector2(0.8, 0.8)
	card.modulate.a = 0.0
	
	# Animate
	var tween = create_tween().set_parallel(true)
	tween.tween_property(bg, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(card, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func animate_outro():
	var bg = $Control/ColorRect
	var card = $Control/CardContainer/Card
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(bg, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	tween.tween_property(card, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	
	await tween.finished

func _process(delta):
	# Force disable input if tutorial is active, because GameManager might re-enable it after spawn
	if tutorial_active:
		# Ensure mouse stays visible
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			
		var level = get_level_controller()
		if level and "input_enabled" in level and level.input_enabled:
			level.set_input_enabled(false)

func get_level_controller():
	var game_manager = get_parent()
	if game_manager.has_node("LevelPivot"):
		return game_manager.get_node("LevelPivot")
	return null

func disable_level_input():
	var level = get_level_controller()
	if level and level.has_method("set_input_enabled"):
		level.set_input_enabled(false)

func update_text():
	if current_step < steps.size():
		label.text = steps[current_step]
		if current_step == steps.size() - 1:
			button.text = "Start"
		else:
			button.text = "Next"
	else:
		finish_tutorial()
	
	# Setup button sounds
	if button:
		setup_button_signals(button)

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
	var sm = get_node_or_null("/root/SoundManager")
	if sm: sm.play_ui_hover()

func _play_click_sound():
	var sm = get_node_or_null("/root/SoundManager")
	if sm: sm.play_ui_click()

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
	# Lazy focus logic
	if tutorial_active and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion) and not get_viewport().gui_get_focus_owner():
		if button:
			button.grab_focus()
			get_viewport().set_input_as_handled()

func _on_button_pressed():
	current_step += 1
	update_text()

func finish_tutorial():
	tutorial_active = false
	
	# Play outro animation and wait for it
	await animate_outro()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var level = get_level_controller()
	if level and level.has_method("set_input_enabled"):
		level.set_input_enabled(true)
	emit_signal("tutorial_completed")
	queue_free()
