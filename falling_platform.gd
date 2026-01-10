extends RigidBody3D

@export var delay: float = 0.5
@export var reset_delay: float = 5.0
@export var ripple_scene: PackedScene

var is_triggered: bool = false
var has_splashed: bool = false
@onready var start_transform: Transform3D = transform
@onready var respawn_particles = $RespawnParticles

func _ready():
	freeze = true
	contact_monitor = true
	max_contacts_reported = 1

func _physics_process(delta):
	if not freeze and not has_splashed:
		# Check for water level (roughly -20 in stage 3)
		if global_position.y < -19.0:
			spawn_splash()
			has_splashed = true

func spawn_splash():
	if ripple_scene:
		var ripple = ripple_scene.instantiate()
		get_parent().add_child(ripple)
		ripple.global_position = Vector3(global_position.x, -20.0, global_position.z)
		
		# Play splash sound if available
		var sg = get_node_or_null("/root/Game/SoundGenerator")
		if sg and sg.has_method("play_splash"):
			sg.play_splash()

func _on_area_3d_body_entered(body):
	if is_triggered: return
	
	if body.name == "Marble":
		is_triggered = true
		await get_tree().create_timer(delay).timeout
		freeze = false
		
		await get_tree().create_timer(reset_delay).timeout
		_reset()

func _reset():
	freeze = true
	transform = start_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	is_triggered = false
	has_splashed = false
	
	if respawn_particles:
		respawn_particles.restart()
		respawn_particles.emitting = true
