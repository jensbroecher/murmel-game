extends Area3D

signal switch_activated

@export var one_shot: bool = true
var is_pressed: bool = false

@onready var mesh = $MeshInstance3D
@onready var audio = $AudioStreamPlayer3D

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if is_pressed: return
	
	if body is RigidBody3D:
		is_pressed = true
		emit_signal("switch_activated")
		# print("Switch activated by: ", body.name)
		
		# Visual feedback
		var tween = create_tween()
		tween.tween_property(mesh, "position:y", -0.05, 0.2)
		
		if audio:
			# Always check for SoundGenerator to ensure we get the melody
			var sg = get_node_or_null("/root/Game/SoundGenerator")
			if sg and sg.has_method("generate_switch_melody"):
				audio.stream = sg.generate_switch_melody()
				
			audio.play()
