extends AnimatedSprite2D

func explode():
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.2)
	await t.finished
	play("explode")
	await animation_finished
	queue_free()
