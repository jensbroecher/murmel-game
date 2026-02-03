extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var material: ShaderMaterial

func _ready():
	if mesh_instance:
		# duplicate material to allow unique pulsing per instance
		material = mesh_instance.get_active_material(0).duplicate() as ShaderMaterial
		mesh_instance.set_surface_override_material(0, material)

func pulse():
	if not material: return
	
	var tween = create_tween()
	tween.tween_method(set_pulse_intensity, 0.0, 1.0, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(set_pulse_intensity, 1.0, 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func set_pulse_intensity(value: float):
	material.set_shader_parameter("pulse_intensity", value)
