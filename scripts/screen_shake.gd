extends CanvasLayer

@onready var screen_shake_rect = $ColorRect

func _ready() -> void:
	EventManager.screen_shake.connect(apply_shake)

func apply_shake(amount: float, duration: float):
	var mat = screen_shake_rect.material
	var tween = create_tween()
	mat.set_shader_parameter("shake_intensity", amount)
	tween.tween_property(mat, "shader_parameter/shake_intensity", 0.0, duration)
