extends ARMPart
class_name BurstBlasterPart

@export_group("Burst Settings")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 1200.0
@export var projectile_duration: float = 0.75
@export var fire_rate: float = 0.8
@export var burst_count: int = 7
@export var burst_delay: float = 0.04
@export var spread_arc: float = 20.0
@export var barrel_length: float = 50.0
@export var damage: float = 1

@onready var fire_timer: Timer = $Timer
var is_bursting: bool = false

func _ready() -> void:
	super()
	fire_timer.one_shot = true

func attack() -> void:
	#EventManager.screen_shake.emit(0.25, 0.15)
	if is_bursting or not fire_timer.is_stopped() or not can_fire: return
	
	is_bursting = true
	fire_timer.start(fire_rate)
	
	for i in range(burst_count):
		if durability <= 0: break
		_fire_single_shot()
		if i < burst_count - 1:
			await get_tree().create_timer(burst_delay).timeout
	
	is_bursting = false

func _fire_single_shot() -> void:
	if is_equipped_by_player: durability -= 0.2
	
	var p = projectile_scene.instantiate()
	p.damage = damage
	p.collision_mask = projectile_collision_mask
	get_tree().current_scene.add_child(p)
	
	var random_rad = deg_to_rad(randf_range(-spread_arc/2.0, spread_arc/2.0))
	var final_rot = global_rotation + random_rad
	
	p.global_rotation = final_rot
	p.global_position = global_position + Vector2.RIGHT.rotated(final_rot) * barrel_length
	
	if "speed" in p: p.speed = projectile_speed
	if p.has_node("Timer"):
		p.get_node("Timer").start(projectile_duration)
