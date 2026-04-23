extends ARMPart
class_name FlamethrowerPart

@export var flameball_scene: PackedScene
@export var fire_rate: float = 0.09
@export var spread: float = 10.0
@export var barrel_length: float = 40.0
@export var durability_drain: float = 0.5
@export var projectile_speed: float = 1000.
@export var projectile_duration: float = 0.5

@onready var timer: Timer = $Timer

func _ready() -> void:
	super()
	timer.wait_time = fire_rate
	timer.one_shot = true

func attack() -> void:
	if not timer.is_stopped() or not can_fire: return
	
	if is_equipped_by_player: 
		durability -= durability_drain
		if Engine.get_frames_drawn() % 5 == 0:
			AudioManager.play_effect(AudioManager.fireball_shoot_sfx)

	timer.start()
	var p = flameball_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.timer.wait_time = projectile_duration
	p.timer.start()
	var random_angle = deg_to_rad(randf_range(-spread, spread))
	p.global_rotation = global_rotation + random_angle
	p.global_position = global_position + Vector2.RIGHT.rotated(p.global_rotation) * barrel_length
	
	if "damage" in p: p.damage = 1 
	if "speed" in p: p.speed = projectile_speed
	p.collision_mask = projectile_collision_mask
