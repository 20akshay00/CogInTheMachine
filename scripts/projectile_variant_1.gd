extends Area2D

var speed: float = 0.0
var dying: bool = false
var damage: int = 1

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_on_timeout)

func _process(delta: float) -> void:
	if dying: return
	global_position += Vector2.RIGHT.rotated(global_rotation) * speed * delta

func _on_timeout() -> void:
	if dying: return
	dying = true
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		area.take_damage(damage)
		timer.stop()
		_on_timeout()
