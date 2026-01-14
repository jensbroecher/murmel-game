extends CSGCombiner3D

@export var launch_force: float = 30.0
@export var erupt_duration: float = 2.0
@export var normal_scale: Vector3 = Vector3(1, 1, 1)
@export var erupt_scale: Vector3 = Vector3(2, 2, 2)

@onready var water_source = $WaterSource
@onready var eruption_area = $EruptionArea

var is_erupting = false

func _ready() -> void:
    if eruption_area:
        eruption_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if body is RigidBody3D and not is_erupting:
        erupt(body)

func erupt(body: RigidBody3D) -> void:
    is_erupting = true
    
    # Launch the marble
    body.linear_velocity.y = 0  # Reset vertical velocity for consistent launch
    body.apply_central_impulse(Vector3.UP * launch_force)
    
    # Visual effect (Scale up water source/particles)
    if water_source:
        var tween = create_tween()
        tween.tween_property(water_source, "scale", erupt_scale, 0.2)
        tween.tween_interval(erupt_duration)
        tween.tween_property(water_source, "scale", normal_scale, 0.5)
        tween.tween_callback(func(): is_erupting = false)
    else:
        await get_tree().create_timer(erupt_duration).timeout
        is_erupting = false
