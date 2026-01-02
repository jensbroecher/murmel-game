extends CanvasLayer

signal fade_in_completed
signal fade_out_completed

@onready var color_rect = $ColorRect

func _ready():
	# Default state: Visible (White) if we want to fade in on start
	# Or user might call fade_in() manually.
	# We'll ensure it's white to start with if it's visible.
	pass

func fade_in(duration: float = 1.0):
	color_rect.visible = true
	color_rect.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): 
		color_rect.visible = false
		fade_in_completed.emit()
	)

func fade_out(duration: float = 1.0):
	color_rect.visible = true
	color_rect.color.a = 0.0
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): 
		fade_out_completed.emit()
	)
