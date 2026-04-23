extends Area2D
class_name Scrap

var value: int = 1
var _consumed: bool = false

func _ready() -> void:
	$Sprite2D.frame = randi_range(0, 4)

func consume() -> int:
	if _consumed: return 0
	_consumed = true
	
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
	
	return value

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.collect_scrap(value)
		consume()
