extends ARMPart
class_name GunPart

@export var flameball_scene: PackedScene
@export var projectile_speed: float = 800.0
@export var projectile_duration: float = 0.75
@export var fire_rate: float = 0.5
@export var barrel_length: float = 50.0

@onready var fire_timer: Timer = $Timer

func _ready() -> void:
	_pre_ready()
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true

func _process(delta: float) -> void:
	_pre_process(delta)

func attack() -> void:
	if not fire_timer.is_stopped(): return
	if just_equipped: return
	
	fire_timer.start()
	
	var projectile = flameball_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	var spawn_offset = Vector2.RIGHT.rotated(global_rotation) * barrel_length
	projectile.global_position = global_position + spawn_offset
	projectile.global_rotation = global_rotation
	
	projectile.scale = Vector2(1., 1.)
	
	if "speed" in projectile:
		projectile.speed = projectile_speed
		
	var p_timer = projectile.get_node_or_null("Timer")
	if p_timer:
		p_timer.wait_time = projectile_duration
		p_timer.one_shot = true
		p_timer.start()
