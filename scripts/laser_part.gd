extends ARMPart
class_name LaserPart

@export_group("Laser Settings")
@export var time_to_damage: float = 0.25
@export var energy_drain_rate: float = 2.0
@export var barrel_length: float = 23.0
@export var max_length: float = 500.0
@export var beam_thickness: float = 16.0
@export var growth_speed: float = 3500.0
@export var damage: int = 1

@onready var shape_cast: ShapeCast2D = $ShapeCast2D
@onready var line: Line2D = $Line2D

var contact_timer: float = 0.0
var last_target: Object = null
var is_attacking_this_frame: bool = false
var current_visual_length: float = 0.0
@onready var base_width: float = line.width

func _ready() -> void:
	super()
	line.points = [Vector2.ZERO, Vector2.ZERO]
	_set_visuals_active(false)
	
	var rect = RectangleShape2D.new()
	rect.size = Vector2(beam_thickness, beam_thickness)
	shape_cast.shape = rect
	shape_cast.target_position = Vector2(max_length, 0)
	shape_cast.position = Vector2(barrel_length, 0)
	shape_cast.enabled = false 

func attack() -> void:
	if durability <= 0 or not can_fire: return
	
	is_attacking_this_frame = true
	var delta = get_process_delta_time()
	if is_equipped_by_player: durability -= energy_drain_rate * delta
	
	shape_cast.force_shapecast_update()
	
	var actual_hit_dist = max_length
	var closest_collider = null
	
	if shape_cast.is_colliding():
		actual_hit_dist = shape_cast.get_closest_collision_safe_fraction() * max_length
		
		for i in shape_cast.get_collision_count():
			var collider = shape_cast.get_collider(i)
			if collider.has_method("take_damage"):
				closest_collider = collider
				break

	if closest_collider:
		if closest_collider == last_target:
			contact_timer += delta
			if contact_timer >= time_to_damage:
				closest_collider.take_damage(damage)
				contact_timer = 0.0
		else:
			contact_timer = 0.0
			last_target = closest_collider
	else:
		contact_timer = 0.0
		last_target = null

	current_visual_length = move_toward(current_visual_length, actual_hit_dist, growth_speed * delta)
	current_visual_length = min(current_visual_length, actual_hit_dist)
	
	_update_visuals(Vector2(barrel_length + current_visual_length, 0))

func _process(delta: float) -> void:
	super(delta)
	if not is_attacking_this_frame:
		_set_visuals_active(false)
		contact_timer = 0.0
		last_target = null
		current_visual_length = 0.0
	is_attacking_this_frame = false

func _set_visuals_active(state: bool) -> void:
	line.visible = state

func _update_visuals(end_point: Vector2) -> void:
	_set_visuals_active(true)
	line.points[0] = Vector2(barrel_length, 0)
	line.points[1] = end_point
	line.width = base_width * lerp(1.0, 1.15, contact_timer / time_to_damage)
