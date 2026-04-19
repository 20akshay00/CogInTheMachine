extends Control

@onready var weapon: Sprite2D = $Weapon
@onready var fill_bg = $LargeCircleFG
var part: ARMPart = null

var weapon_tween: Tween
var fill_tween: Tween
var target_durability: float = -1.0

func _ready():
	if part:
		target_durability = get_durability()
	else:
		target_durability = 0.
	
	fill_bg.material.set_shader_parameter("fill_level", target_durability)

func _process(_delta: float) -> void:
	if not part: return
	
	var actual_durability = get_durability()
	
	if actual_durability != target_durability:
		target_durability = actual_durability
		_animate_to(target_durability, 0.25)

func get_durability() -> float:
	if not part or part.max_durability == 0: 
		return 0.0
	return float(part.durability) / float(part.max_durability)

func update_state(p: ARMPart, duration: float = 0.75) -> void:
	part = p
	if p: 
		weapon.texture = p.sprite.texture
		weapon.region_rect = p.sprite.region_rect
		show_weapon_sprite(true)
	else:
		show_weapon_sprite(false)
	
	target_durability = get_durability()
	_animate_to(target_durability, duration)

func _animate_to(target: float, duration: float) -> void:
	if fill_tween and fill_tween.is_valid(): 
		fill_tween.kill()
		
	fill_tween = create_tween()
	fill_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fill_tween.tween_property(fill_bg.material, "shader_parameter/fill_level", target, duration)

func show_weapon_sprite(is_visible: bool, duration: float = 0.5) -> void:
	if weapon_tween and weapon_tween.is_valid():
		weapon_tween.kill()
		
	weapon_tween = create_tween()
	var target_alpha: float = 1.0 if is_visible else 0.0
	weapon_tween.tween_property(weapon, "modulate:a", target_alpha, duration)
