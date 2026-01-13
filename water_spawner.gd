extends Node3D

@export var drop_scene: PackedScene
@export var spawn_interval: float = 0.1
@export var spread: float = 1.0

var time_since_last_spawn: float = 0.0

func _ready():
	print("WaterSpawner: Ready via " + str(drop_scene))

func _process(delta):
	time_since_last_spawn += delta
	while time_since_last_spawn >= spawn_interval:
		spawn_drop()
		time_since_last_spawn -= spawn_interval

func spawn_drop():
	if drop_scene:
		var drop = drop_scene.instantiate()
		get_tree().current_scene.add_child(drop)
		
		# Random position within spread
		var offset = Vector3(randf_range(-spread, spread), randf_range(0, spread), randf_range(-spread, spread))
		drop.global_position = global_position + offset
		
		# Initial small velocity?
		if drop is RigidBody3D:
			drop.linear_velocity = Vector3(0, 2, 0) # Pop up slightly
