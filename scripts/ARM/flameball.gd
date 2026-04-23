extends Area2D
class_name Flameball

@export var drag: float = 0.5
@export var growth_rate: float = 0.7

var speed: float = 0.0
var dying: bool = false
var damage: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	anim.play("default")
	timer.timeout.connect(_on_timeout)
	anim.animation_finished.connect(_on_anim_finished)
	scale = scale * 0.75

func _process(delta: float) -> void:
	if dying: return
	
	speed = move_toward(speed, 0.0, speed * drag * delta)
	scale += Vector2.ONE * growth_rate * delta
	
	global_position += Vector2.RIGHT.rotated(global_rotation) * speed * delta

func _on_timeout() -> void:
	if dying: return
	dying = true
	anim.play("death")

func _on_anim_finished() -> void:
	if anim.animation == "death":
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox and not dying:
		AudioManager.play_effect(AudioManager.fireball_hit_sfx)
		area.take_damage(damage)
		timer.stop()
		_on_timeout()
