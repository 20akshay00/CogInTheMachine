extends Control


@export var glow_hue: Color
@export var symbol_hue: Color
@export var symbol: Texture2D
@export var symbol_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	$Symbol.texture = symbol
	$BulbLight.modulate = glow_hue
	$Symbol.modulate = symbol_hue
	$Symbol.position += symbol_offset
