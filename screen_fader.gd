extends CanvasLayer

signal fade_in_completed
signal fade_out_completed

@onready var color_rect = $ColorRect

const IRIS_SHADER = preload("res://iris_wipe.gdshader")
var iris_material: ShaderMaterial

func _ready():
	iris_material = ShaderMaterial.new()
	iris_material.shader = IRIS_SHADER

func fade_in(duration: float = 1.0):
	color_rect.material = null
	color_rect.visible = true
	color_rect.color.a = 1.0
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): 
		color_rect.visible = false
		fade_in_completed.emit()
	)

func fade_out(duration: float = 1.0):
	color_rect.material = null
	color_rect.visible = true
	color_rect.color.a = 0.0
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): 
		fade_out_completed.emit()
	)

func fade_in_iris(duration: float = 1.0):
	color_rect.material = iris_material
	color_rect.visible = true
	# Ensure alpha is 1 so the rect is drawn (the shader handles transparency)
	color_rect.color.a = 1.0
	
	# Start with radius -0.25 (fully closed/black considering blur)
	iris_material.set_shader_parameter("radius", -0.25)
	
	var tween = create_tween()
	# Expand radius to 1.5 (open/transparent)
	tween.tween_method(func(val): iris_material.set_shader_parameter("radius", val), -0.25, 1.5, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): 
		color_rect.visible = false
		fade_in_completed.emit()
	)

func fade_out_iris(duration: float = 1.0):
	color_rect.material = iris_material
	color_rect.visible = true
	color_rect.color.a = 1.0
	
	# Start with radius 1.5 (open/transparent)
	iris_material.set_shader_parameter("radius", 1.5)
	
	var tween = create_tween()
	# Shrink radius to -0.25 (fully closed/black considering blur)
	tween.tween_method(func(val): iris_material.set_shader_parameter("radius", val), 1.5, -0.25, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func(): 
		fade_out_completed.emit()
	)
