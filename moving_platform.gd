extends AnimatableBody3D

@export var move_offset: Vector3 = Vector3(0, 0, 5)
@export var duration: float = 3.0
@export var delay: float = 0.0

func _ready():
	call_deferred("start_movement")

func start_movement():
	var start_pos = position
	var target_pos = start_pos + move_offset
	
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	if delay > 0:
		tween.tween_interval(delay)
	
	tween.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", start_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
