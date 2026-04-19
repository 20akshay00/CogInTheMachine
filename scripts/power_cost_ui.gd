extends Node2D
class_name PowerCostUI

@export var power_symbol: Texture2D
@export var spacing: float = 16.0
@export var fade_duration: float = 0.2
var _fade_tween: Tween

@export var symbol_scale: Vector2 = Vector2(2.0, 2.0)
@export var symbol_hue: Color = Color.WHITE

func _ready() -> void:
	modulate.a = 0.0
	if not get_parent() or !("power" in get_parent()):
		return
		
	var count = get_parent().power
	for i in range(count):
		var s = Sprite2D.new()
		s.texture = power_symbol
		s.position.x = i * spacing
		s.scale = symbol_scale
		s.modulate = symbol_hue
		add_child(s)

func set_state(state: bool) -> void:
	if _fade_tween: _fade_tween.kill()
	_fade_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_alpha = 1.0 if state else 0.0
	_fade_tween.tween_property(self, "modulate:a", target_alpha, fade_duration)
