extends CharacterBody2D
class_name Player

@export var speed: float = 300.0
@export var rotation_speed: float = 20.0
@export var rotation_steps: int = 8 # Set to 8 for 45-degree snaps, 4 for 90-degree, etc.

## stuff for visuals
@onready var L_ARM: Node2D = $"L-ARM"
@onready var R_ARM: Node2D = $"R-ARM"
@onready var L_ARM_socket: AnimatedSprite2D = $"L-ARM Socket"
@onready var R_ARM_socket: AnimatedSprite2D = $"R-ARM Socket"
@onready var BODY: AnimatedSprite2D = $Body
@onready var HEAD: Sprite2D = $Head

@onready var pickup_area: Area2D = $PickupArea

### equipped parts
var L_ARM_part: ARMPart = null
var R_ARM_part: ARMPart = null
var P_MODULE_part: MODULEPart = null

### stats
@export var power: int = 10
@export var durability: int = 5

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	velocity = direction * speed
	move_and_slide()

	var target_anim = "move" if velocity.length() > 0 else "idle"
	
	if BODY.animation != target_anim:
		BODY.play(target_anim)
		L_ARM_socket.play(target_anim)
		R_ARM_socket.play(target_anim)

	if velocity.length() > 0:
		var angle = velocity.angle()
		var frame_index = posmod(int(round(angle / (PI / 4))), 8)
		if HEAD.frame != frame_index:
			HEAD.frame = frame_index

func _process(delta: float) -> void:
	var joy_dir := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var step_size := TAU / rotation_steps
	
	var l_target: float
	var r_target: float
	
	if joy_dir.length() > 0.1:
		l_target = joy_dir.angle()
		r_target = l_target
	else:
		l_target = (get_global_mouse_position() - L_ARM.global_position).angle()
		r_target = (get_global_mouse_position() - R_ARM.global_position).angle()

	# swnap target angles to the defined increments
	l_target = round(l_target / step_size) * step_size
	r_target = round(r_target / step_size) * step_size

	L_ARM.rotation = lerp_angle(L_ARM.rotation, l_target, rotation_speed * delta)
	R_ARM.rotation = lerp_angle(R_ARM.rotation, r_target, rotation_speed * delta)

	## attack logic
	if Input.is_action_pressed("attack_left_arm") and L_ARM_part:
		L_ARM_part.attack()
	if Input.is_action_pressed("attack_right_arm") and R_ARM_part:
		R_ARM_part.attack()

func request_arm_equip(part: ARMPart) -> Node2D:
	# no over-clocking for now!
	if part.power <= get_available_power():
		return get_free_arm_slot(part)
	else:
		return null

func get_free_arm_slot(part: ARMPart) -> Node2D:
	if R_ARM_part:
		if L_ARM_part:
			return null
		else:
			L_ARM_part = part
			return L_ARM
	else:
		R_ARM_part = part
		return R_ARM

func get_available_power() -> int:
	var used: int = 0
	if L_ARM_part: used += L_ARM_part.power
	if R_ARM_part: used += R_ARM_part.power
	if P_MODULE_part: used += P_MODULE_part.power
	return power - used

func _on_pickup_area_area_entered(area: Area2D) -> void:
	if area is ARMPart:
		area.on_entered_pickup_range()
	else:
		print("Non ARMPart triggered pickup area! Shouldn't happen.")

func _on_pickup_area_area_exited(area: Area2D) -> void:
	if area is ARMPart:
		area.on_exited_pickup_range()
	else:
		print("Non ARMPart triggered pickup area! Shouldn't happen.")
	
