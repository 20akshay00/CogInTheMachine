extends ARMPart
class_name GenericBlasterPart

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 800.0
@export var projectile_duration: float = 0.75
@export var fire_rate: float = 0.5
@export var barrel_length: float = 50.0
@export var damage: int = 1

@onready var fire_timer: Timer = $Timer

func _ready() -> void:
	super()
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true

func attack() -> void:
	if not fire_timer.is_stopped() or not can_fire: return
	
	if is_equipped_by_player: durability -= 1.
	fire_timer.start()
	var p = projectile_scene.instantiate()
	p.damage = damage
	p.collision_mask = projectile_collision_mask
	get_tree().current_scene.add_child(p)
	
	p.global_transform = global_transform
	p.global_position += Vector2.RIGHT.rotated(global_rotation) * barrel_length
	
	if "speed" in p: p.speed = projectile_speed
	if p.has_node("Timer"):
		p.get_node("Timer").start(projectile_duration)
