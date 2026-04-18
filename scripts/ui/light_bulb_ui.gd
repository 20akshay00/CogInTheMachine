extends Control
class_name LightBulbUI

@export var glow_hue: Color
@export var symbol_hue: Color
@export var symbol: Texture2D
@export var symbol_offset: Vector2 = Vector2.ZERO
@export var transition_duration: float = 0.75

var state = true

func _ready() -> void:
	$Symbol.texture = symbol
	$BulbLight.modulate = glow_hue
	$Symbol.modulate = symbol_hue
	$Symbol.position += symbol_offset

func set_active(val: bool) -> Tween:
	if state == val: return
	state = val
	var target_alpha = 1.0 if state else 0.0
	var t = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_property($BulbLight, "modulate:a", target_alpha, transition_duration)
	t.tween_property($Symbol, "modulate:a", target_alpha, transition_duration)
	return t

func get_state() -> bool:
	return state
