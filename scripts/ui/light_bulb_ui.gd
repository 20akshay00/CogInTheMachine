extends Control
class_name LightBulbUI

@export var glow_hue: Color
@export var symbol_hue: Color
@export var glow_unstable_hue: Color
@export var symbol_unstable_hue: Color

@export var symbol: Texture2D
@export var symbol_offset: Vector2 = Vector2.ZERO
@export var transition_duration: float = 0.25

@export var wobble_speed: float = 20.0
@export var wobble_intensity: float = 0.01
@export var wobble_scale_intensity: float = 0.02

var _is_unstable: bool = false
var _random_phase: float = randf() * 10.0
var _wobble_tween: Tween

var state = true

func _ready() -> void:
	$Symbol.texture = symbol
	$BulbLight.modulate = glow_hue
	$Symbol.modulate = symbol_hue
	$Symbol.position += symbol_offset

func _process(_delta: float) -> void:
	if not _is_unstable: return
	
	var t = (Time.get_ticks_msec() / 1000.0) * wobble_speed + _random_phase
	
	pivot_offset = size / 2
	
	rotation = (sin(t) * cos(t * 0.7) + sin(t * 1.4)) * wobble_intensity
	
	var s = 1.0 + (cos(t * 1.2) * sin(t * 0.5)) * wobble_scale_intensity
	scale = Vector2(s, 2.0 - s)

func set_unstable_colors(state: bool) -> Tween:
	var target_glow = glow_unstable_hue if state else glow_hue
	var target_symbol = symbol_unstable_hue if state else symbol_hue
	
	var t = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	
	t.tween_property($BulbLight, "modulate:r", target_glow.r, transition_duration)
	t.tween_property($BulbLight, "modulate:g", target_glow.g, transition_duration)
	t.tween_property($BulbLight, "modulate:b", target_glow.b, transition_duration)
	
	t.tween_property($Symbol, "modulate:r", target_symbol.r, transition_duration)
	t.tween_property($Symbol, "modulate:g", target_symbol.g, transition_duration)
	t.tween_property($Symbol, "modulate:b", target_symbol.b, transition_duration)
	return t
	

func set_unstable(active: bool) -> Tween:
	_is_unstable = active
	var t = set_unstable_colors(active)
	
	if not active:
		rotation = 0
		scale = Vector2.ONE
		
	return t

# for health bulbs	
func set_active(val: bool) -> Tween:
	if state == val: return
	state = val
	var target_alpha = 1.0 if state else 0.0
	var t = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	t.tween_property($BulbLight, "modulate:a", target_alpha, transition_duration)
	t.tween_property($Symbol, "modulate:a", target_alpha, transition_duration)
	return t

func set_light_active(val: bool) -> Tween:
	var target_alpha = 1.0 if val else 0.0
	var t = create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property($BulbLight, "modulate:a", target_alpha, transition_duration)
	return t

func set_symbol_active(val: bool) -> Tween:
	var target_alpha = 1.0 if val else 0.0
	var t = create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property($Symbol, "modulate:a", target_alpha, transition_duration)
	return t

func get_state() -> bool:
	return state
