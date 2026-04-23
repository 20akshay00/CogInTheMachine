extends Camera2D

@export var decay: float = 0.8
@export var max_offset: Vector2 = Vector2(100, 75)
@export var max_roll: float = 0.1

var trauma: float = 0.0
var trauma_pwr: int = 2
var is_shaking: bool = false 

func _ready() -> void:
	EventManager.screen_shake.connect(_on_shake_requested)

func _process(delta: float) -> void:
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		_shake()
	elif is_shaking:
		offset = Vector2.ZERO
		rotation = 0.0
		is_shaking = false

func _on_shake_requested(amount: float, duration: float) -> void:
	if is_shaking: return 
	add_trauma(amount)
	is_shaking = true
	
	await get_tree().create_timer(duration).timeout

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func _shake() -> void:
	var amount = pow(trauma, trauma_pwr)
	rotation = max_roll * amount * randf_range(-1, 1)
	offset.x = max_offset.x * amount * randf_range(-1, 1)
	offset.y = max_offset.y * amount * randf_range(-1, 1)
