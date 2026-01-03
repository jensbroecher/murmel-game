extends AnimatableBody3D

@export var open_offset: Vector3 = Vector3(0, -3, 0)
@export var duration: float = 1.0

var is_open: bool = false

func open():
	if is_open: return
	is_open = true
	
	var tween = create_tween()
	tween.tween_property(self, "position", position + open_offset, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
