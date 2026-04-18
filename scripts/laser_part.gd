extends ARMPart
class_name LaserPart

@export_group("Laser Settings")
@export var durability: float = 5.0
@export var time_to_damage: float = 0.5
@export var energy_drain_rate: float = 0.2
@export var barrel_length: float = 23.0
@export var max_length: float = 500.0
@export var damage: int = 2

@onready var ray_cast: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D

var contact_timer: float = 0.0
var last_target: Object = null
var is_attacking_this_frame: bool = false
@onready var base_width: float = line.width

func _ready() -> void:
	super()
	line.points = [Vector2.ZERO, Vector2.ZERO]
	_set_visuals_active(false)
	
	ray_cast.target_position = Vector2(max_length, 0)
	ray_cast.position = Vector2(barrel_length, 0)

func attack() -> void:
	if durability <= 0 or not can_fire: 
		return
	
	is_attacking_this_frame = true
	durability -= energy_drain_rate * get_process_delta_time()
	
	ray_cast.force_raycast_update()
	var beam_end_local = Vector2(barrel_length + max_length, 0)
	
	if ray_cast.is_colliding():
		var collider = ray_cast.get_collider()
		beam_end_local = to_local(ray_cast.get_collision_point())
		
		if collider.has_method("take_damage"):
			if collider == last_target:
				contact_timer += get_process_delta_time()
				if contact_timer >= time_to_damage:
					collider.take_damage(1)
					contact_timer = 0.0
			else:
				contact_timer = 0.0
				last_target = collider
		else:
			contact_timer = 0.0
			last_target = null
	else:
		contact_timer = 0.0
		last_target = null
		
	_update_visuals(beam_end_local)

func _process(_delta: float) -> void:
	if not is_attacking_this_frame:
		_set_visuals_active(false)
		contact_timer = 0.0
		last_target = null
	
	is_attacking_this_frame = false

func _set_visuals_active(state: bool) -> void:
	line.visible = state

func _update_visuals(end_point: Vector2) -> void:
	_set_visuals_active(true)
	
	line.points[0] = Vector2(barrel_length, 0)
	line.points[1] = end_point
	
	line.width = base_width * lerp(1.0, 1.15, contact_timer / time_to_damage)
