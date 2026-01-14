extends CSGCombiner3D

@export var move_height: float = 1.0
@export var up_duration: float = 5.0
@export var down_duration: float = 10.0
@export var transition_time: float = 2.0
@export var initial_delay: float = 10.0

@onready var wall_poly: CSGPolygon3D = $WallPoly

var original_y: float

func _ready() -> void:
	if wall_poly:
		original_y = wall_poly.position.y
		start_cycle()

func start_cycle() -> void:
	# Initial delay with slight randomness to desynchronize platforms
	var random_delay = randf_range(0.0, 2.0)
	await get_tree().create_timer(initial_delay + random_delay).timeout
	
	while true:
		# Move Up
		var tween_up = create_tween()
		tween_up.set_trans(Tween.TRANS_SINE)
		tween_up.set_ease(Tween.EASE_IN_OUT)
		tween_up.tween_property(wall_poly, "position:y", original_y + move_height, transition_time)
		await tween_up.finished
		
		# Stay Up
		await get_tree().create_timer(up_duration).timeout
		
		# Move Down
		var tween_down = create_tween()
		tween_down.set_trans(Tween.TRANS_SINE)
		tween_down.set_ease(Tween.EASE_IN_OUT)
		tween_down.tween_property(wall_poly, "position:y", original_y, transition_time)
		await tween_down.finished
		
		# Stay Down
		await get_tree().create_timer(down_duration).timeout
