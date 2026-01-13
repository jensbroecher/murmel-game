extends AnimatableBody3D

@export var move_offset: Vector3 = Vector3(0, 10, 0)
@export var duration: float = 3.0
@export var stay_time: float = 2.0

var start_pos: Vector3
var target_pos: Vector3
var is_moving: bool = false
var is_at_top: bool = false

func _ready():
	start_pos = position
	target_pos = start_pos + move_offset
	
@export var ejection_force: float = 15.0
var passenger: RigidBody3D

func _on_trigger_body_entered(body):
	if body.name == "Marble" and not is_moving and not is_at_top:
		passenger = body
		start_elevator()

@onready var door = $Door

func start_elevator():
	is_moving = true
	var tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# Close Door (Move Up)
	tween.tween_property(door, "position:y", 1.5, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	
	# Move Up
	tween.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(func():
		print("Elevator: Reached top, opening and tilting")
		is_at_top = true
		is_moving = false
		_open_and_tilt()
	)

func _open_and_tilt():
	print("Elevator: _open_and_tilt called")
	var tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# Open Door (Move Down) & Tilt
	tween.tween_property(door, "position:y", -0.5, 1.0)
	
	# Tilt towards door (Door is at -X, so rotate +Z to lower -X)
	# Using 25 degrees for more visibility. Using rotation_degrees for clarity.
	tween.parallel().tween_property(self, "rotation_degrees:z", 25.0, 1.0)
	
	tween.tween_callback(func():
		# Eject Passenger
		print("Elevator: Ejecting passenger")
		if passenger and is_instance_valid(passenger):
			# Door is at local -X. Eject in Global -X direction relative to rotated elevator
			# Rotation is +Z, so -X becomes slightly -X + -Y. 
			# Basically just push it "Left" (-X) in local space.
			var push_dir = -global_transform.basis.x.normalized()
			passenger.apply_central_impulse(push_dir * ejection_force)
	)
	
	tween.tween_interval(stay_time)
	tween.tween_callback(return_elevator)

func return_elevator():
	print("Elevator: return_elevator called. Current End Rotation: " + str(rotation_degrees))
	is_moving = true
	var tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# Reset Tilt gradually over the descent (90% of duration to ensure it's flat before landing)
	# Reset Tilt gradually over the descent
	tween.tween_property(self, "rotation_degrees:z", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "position", start_pos, duration).set_trans(Tween.TRANS_LINEAR)
	
	tween.tween_callback(func():
		print("Elevator: Returned to start. Force resetting rotation.")
		rotation_degrees = Vector3.ZERO
		is_at_top = false
		is_moving = false
	)
