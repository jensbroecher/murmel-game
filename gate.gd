extends StaticBody3D

@export var open_offset: Vector3 = Vector3(0, -1.9, 0)
@export var duration: float = 1.0

var is_open: bool = false

func _ready():
	# print("Gate _ready. Position: ", global_position, " Is open: ", is_open)
	# Also reset local scale just in case
	scale = Vector3.ONE

func open():
	if is_open: return
	is_open = true
	
	var tween = create_tween()
	# IMPORTANT: Sync tween with physics to prevent collision issues during movement
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# Move down using the exported offset
	tween.tween_property(self, "position", position + open_offset, duration).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
