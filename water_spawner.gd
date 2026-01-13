extends Node3D

@export var drop_scene: PackedScene
@export var spawn_interval: float = 0.05
@export var spread: float = 0.2
@export var max_drops: int = 400
@export var fountain_force: float = 8.0

var time_since_last_spawn: float = 0.0
var active_drops: Array[Node] = []

func _ready():
	print("WaterSpawner: Ready via " + str(drop_scene))

func _process(delta):
	# Cleanup invalid drops
	for i in range(active_drops.size() - 1, -1, -1):
		if not is_instance_valid(active_drops[i]):
			active_drops.remove_at(i)

	time_since_last_spawn += delta
	while time_since_last_spawn >= spawn_interval:
		if active_drops.size() < max_drops:
			spawn_drop()
		time_since_last_spawn -= spawn_interval

func spawn_drop():
	if drop_scene:
		var drop = drop_scene.instantiate()
		get_tree().current_scene.add_child(drop)
		active_drops.append(drop)
		
		# Fountain start position (center)
		drop.global_position = global_position
		
		# Fountain velocity
		if drop is RigidBody3D:
			# Upward force with some random spread
			var random_dir = Vector3(randf_range(-spread, spread), 1.0, randf_range(-spread, spread)).normalized()
			drop.linear_velocity = random_dir * fountain_force

