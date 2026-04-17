extends Area2D

var speed: float = 0.0
var dying: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var timer: Timer = $Timer

func _ready() -> void:
	anim.play("default")
	timer.timeout.connect(_on_timeout)
	anim.animation_finished.connect(_on_anim_finished)

func _process(delta: float) -> void:
	if dying: return
	global_position += Vector2.RIGHT.rotated(global_rotation) * speed * delta

func _on_timeout() -> void:
	dying = true
	anim.play("death")

func _on_anim_finished() -> void:
	if anim.animation == "death":
		queue_free()
