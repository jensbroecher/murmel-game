extends RigidBody3D

@export var reset_threshold: float = -50.0
@onready var start_position: Vector3 = global_position
@onready var original_mass: float = mass

var original_collision_scale: Vector3
var visual_root: Node3D
var original_visual_scale: Vector3

var is_super_marble: bool = false
var powerup_timer: Timer
var wind_tween: Tween
var wind_active: bool = false

func _ready() -> void:
	# Enable Continuous Collision Detection (CCD) to prevent tunneling
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 3
	
	# Store original values
	original_mass = mass
	
	visual_root = get_node_or_null("Model")
	if not visual_root:
		visual_root = get_node_or_null("MeshInstance3D")
	if visual_root:
		original_visual_scale = visual_root.scale
	else:
		original_visual_scale = Vector3.ONE
		
	var col = get_node_or_null("CollisionShape3D")
	if col:
		original_collision_scale = col.scale
	else:
		original_collision_scale = Vector3.ONE
	
	_align_and_scale_visual_to_collision()
	
	# Setup timer
	powerup_timer = Timer.new()
	powerup_timer.one_shot = true
	add_child(powerup_timer)
	powerup_timer.timeout.connect(_on_powerup_timer_timeout)

func _physics_process(delta: float) -> void:
	var is_airborne = get_contact_count() == 0
	var wind_player = get_node_or_null("WindPlayer")
	
	if wind_player:
		if is_airborne:
			if not wind_active:
				wind_active = true
				if not wind_player.playing:
					wind_player.volume_db = -80.0
					wind_player.play()
				
				if wind_tween: wind_tween.kill()
				wind_tween = create_tween()
				# Fade in over 1.0 second
				wind_tween.tween_property(wind_player, "volume_db", 0.0, 1.0)
		else:
			if wind_active:
				wind_active = false
				
				if wind_tween: wind_tween.kill()
				wind_tween = create_tween()
				# Fade out quickly
				wind_tween.tween_property(wind_player, "volume_db", -80.0, 0.2)
				wind_tween.tween_callback(wind_player.stop)

func _process(delta: float) -> void:
	if global_position.y < reset_threshold:
		reset_game()

func change_size_and_mass(size_multiplier: float, mass_multiplier: float, duration: float) -> void:
	print("PowerUp activated! Duration: ", duration, " Size Mult: ", size_multiplier)
	
	# Always refresh state and timer
	is_super_marble = true
	
	# Apply changes
	var tween = create_tween()
	
	var node_to_scale = visual_root
	if node_to_scale:
		tween.parallel().tween_property(node_to_scale, "scale", original_visual_scale * size_multiplier, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		# Color change
		# Use material_override if set, otherwise surface material
		var first_mesh = _find_first_mesh_instance(node_to_scale)
		var mat = null
		if first_mesh:
			mat = first_mesh.material_override if first_mesh.material_override else first_mesh.mesh.surface_get_material(0)
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
	
	var node_to_scale = visual_root
	if node_to_scale:
		revert_tween.parallel().tween_property(node_to_scale, "scale", original_visual_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		var first_mesh = _find_first_mesh_instance(node_to_scale)
		var mat = null
		if first_mesh:
			mat = first_mesh.material_override if first_mesh.material_override else first_mesh.mesh.surface_get_material(0)
		if mat:
			# Revert to white (assuming original was white/default)
			revert_tween.parallel().tween_property(mat, "albedo_color", Color(1, 1, 1), 0.5)

	var col = get_node_or_null("CollisionShape3D")
	if col:
		revert_tween.parallel().tween_property(col, "scale", original_collision_scale, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	mass = original_mass
	is_super_marble = false
	
func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_first_mesh_instance(child)
		if found:
			return found
	return null
	
func _align_and_scale_visual_to_collision() -> void:
	var col = get_node_or_null("CollisionShape3D")
	if not visual_root or not col:
		return
	var first_mesh = _find_first_mesh_instance(visual_root)
	if not first_mesh:
		return
	var aabb = first_mesh.get_aabb()
	var center = aabb.position + aabb.size * 0.5
	visual_root.position -= center
	var target_radius = 0.5
	var shape = col.shape
	if shape is SphereShape3D:
		target_radius = shape.radius * col.scale.x
	var current_radius = max(aabb.size.x, aabb.size.y, aabb.size.z) * 0.5
	if current_radius <= 0.0:
		return
	var scale_factor = target_radius / current_radius
	visual_root.scale = Vector3.ONE * scale_factor
	original_visual_scale = visual_root.scale

func reset_game() -> void:
	# Reload the current scene
	get_tree().reload_current_scene()
