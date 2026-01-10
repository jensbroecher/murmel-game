extends RigidBody3D

@export var reset_threshold: float = -50.0
@onready var start_position: Vector3 = global_position
@onready var original_mass: float = mass

var original_mesh_scale: Vector3
var original_collision_scale: Vector3

var is_super_marble: bool = false
var powerup_timer: Timer

func _ready() -> void:
	# Enable Continuous Collision Detection (CCD) to prevent tunneling
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 3
	
	# Store original values
	original_mass = mass
	
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		original_mesh_scale = mesh.scale
	else:
		original_mesh_scale = Vector3.ONE
		
	var col = get_node_or_null("CollisionShape3D")
	if col:
		original_collision_scale = col.scale
	else:
		original_collision_scale = Vector3.ONE
	
	# Setup timer
	powerup_timer = Timer.new()
	powerup_timer.one_shot = true
	add_child(powerup_timer)
	powerup_timer.timeout.connect(_on_powerup_timer_timeout)

func _process(delta: float) -> void:
	if global_position.y < reset_threshold:
		reset_game()

func change_size_and_mass(size_multiplier: float, mass_multiplier: float, duration: float) -> void:
	print("PowerUp activated! Duration: ", duration, " Size Mult: ", size_multiplier)
	
	# Always refresh state and timer
	is_super_marble = true
	
	# Apply changes
	var tween = create_tween()
	
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		tween.parallel().tween_property(mesh, "scale", original_mesh_scale * size_multiplier, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		# Color change
		# Use material_override if set, otherwise surface material
		var mat = mesh.material_override if mesh.material_override else mesh.mesh.surface_get_material(0)
		if mat:
			tween.parallel().tween_property(mat, "albedo_color", Color(0, 1, 0), 0.5)

	var col = get_node_or_null("CollisionShape3D")
	if col:
		tween.parallel().tween_property(col, "scale", original_collision_scale * size_multiplier, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			
	mass = original_mass * mass_multiplier
	
	# Play grow sound
	var zoom1 = get_node_or_null("Zoom1Player")
	if zoom1:
		zoom1.play()
	
	# Start timer
	print("Starting timer for ", duration, " seconds...")
	powerup_timer.start(duration)

func _on_powerup_timer_timeout() -> void:
	print("PowerUp finished, reverting...")
	
	# Play shrink sound
	var zoom2 = get_node_or_null("Zoom2Player")
	if zoom2:
		zoom2.play()
	
	# Revert changes
	var revert_tween = create_tween()
	
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		revert_tween.parallel().tween_property(mesh, "scale", original_mesh_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		var mat = mesh.material_override if mesh.material_override else mesh.mesh.surface_get_material(0)
		if mat:
			# Revert to white (assuming original was white/default)
			revert_tween.parallel().tween_property(mat, "albedo_color", Color(1, 1, 1), 0.5)

	var col = get_node_or_null("CollisionShape3D")
	if col:
		revert_tween.parallel().tween_property(col, "scale", original_collision_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	mass = original_mass
	is_super_marble = false

func reset_game() -> void:
	# Reload the current scene
	get_tree().reload_current_scene()
