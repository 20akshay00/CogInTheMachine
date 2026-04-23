extends ARMPart
class_name LightsaberPart

@export_category("Melee Stats")
@export var damage: int = 2
@export var swing_duration: float = 0.15
@export var swing_angle: float = 130.0 
@export var cooldown_time: float = 0.2

@onready var cooldown_timer: Timer = $Timer
@onready var swing_pivot: Node2D = $Pivot
@onready var hurtbox_shape: CollisionShape2D = $Pivot/Hurtbox/CollisionShape2D

var is_attacking: bool = false
var swing_direction: float = 1.0 

func _ready() -> void:
	super()
	cooldown_timer.wait_time = cooldown_time
	cooldown_timer.one_shot = true
	hurtbox_shape.disabled = true

func attack() -> void:
	if is_attacking or not cooldown_timer.is_stopped() or not can_fire: 
		return
	
	is_attacking = true
	hurtbox_shape.disabled = false 
	if is_equipped_by_player: 
		durability -= 1.
		AudioManager.play_effect(AudioManager.sword_shoot_sfx)
		
	var half_angle = deg_to_rad(swing_angle / 2.0)
	var start_angle = -half_angle * swing_direction
	var end_angle = half_angle * swing_direction
	
	swing_pivot.rotation = start_angle
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(swing_pivot, "rotation", end_angle, swing_duration)
	
	await tween.finished
	
	hurtbox_shape.disabled = true
	is_attacking = false
	cooldown_timer.start()
	
	swing_direction *= -1.0
	
	var reset_tween = create_tween()
	reset_tween.tween_property(swing_pivot, "rotation", 0.0, 0.1)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if not is_attacking: return
	
	if area is Flameball or area is ProjectileVariant1 or area is ProjectileVariant2:
		reflect_projectile(area)
		return
		
	if area is Hitbox:
		AudioManager.play_effect(AudioManager.sword_hit_sfx)
		area.take_damage(damage)

func reflect_projectile(proj: Area2D) -> void:
	if "velocity" in proj:
		proj.velocity = -proj.velocity * 1.25
	elif "direction" in proj:
		proj.direction = -proj.direction
	
	if "timer" in proj:
		proj.timer.start()
	proj.rotation += PI 
	
	proj.set_collision_mask_value(6, false)
	proj.set_collision_mask_value(3, true)
