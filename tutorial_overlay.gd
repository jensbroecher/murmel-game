extends CanvasLayer

signal tutorial_completed

@onready var label = $Control/Panel/Label
@onready var button = $Control/Panel/Button

var steps = [
	"Welcome to HardTilt - Marble Run Challenge!\n\nYour goal is to navigate the Marblebot to the spaceship and collect all the diamonds in a stage.\nAvoid falling off the edge.",
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

func _on_button_pressed():
	current_step += 1
	update_text()

func finish_tutorial():
	tutorial_active = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var level = get_level_controller()
	if level and level.has_method("set_input_enabled"):
		level.set_input_enabled(true)
	emit_signal("tutorial_completed")
	queue_free()
