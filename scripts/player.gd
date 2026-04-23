extends CharacterBody2D
class_name Player

signal stats_changed(current_scrap, goal_scrap, level, L_power, R_power, health)

@export var health: int = 5
@export var L_power: int = 1
@export var R_power: int = 1
@export var scrap_count: int = 0
@export var upgrade_level: int = 0
@export var scrap_to_level: int = 20

@export var max_dashes: int = 3
@export var dash_cooldown: float = 1.5
@export var dash_speed: float = 1200.0
@export var dash_duration: float = 0.15

@export var CONTROLLER_MODE = false
@export var speed: float = 400.0
@export var rotation_speed: float = 20.0
@export var rotation_steps: int = 16

@onready var L_ARM: Node2D = $"L-ARM"
@onready var R_ARM: Node2D = $"R-ARM"
@onready var L_ARM_socket: AnimatedSprite2D = $"L-ARM Socket"
@onready var R_ARM_socket: AnimatedSprite2D = $"R-ARM Socket"
@onready var BODY: AnimatedSprite2D = $Body
@onready var HEAD: Sprite2D = $Head
@onready var pickup_area: Area2D = $PickupArea
@onready var hitbox: Area2D = $Hitbox
@onready var dash_timer: Timer = $DashTimer

var L_ARM_part: ARMPart = null
var R_ARM_part: ARMPart = null
var active_target: ARMPart = null
var is_dashing: bool = false
var current_dashes: int = 3

func _ready() -> void:
	stats_changed.emit(scrap_count, scrap_to_level, upgrade_level, L_power, R_power, health)
	current_dashes = max_dashes
	dash_timer.timeout.connect(_on_dash_cooldown_finished)

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("dash") and not is_dashing and current_dashes > 0:
		_perform_dash()

	if not is_dashing:
		velocity = Input.get_vector("left", "right", "up", "down") * speed
	
	move_and_slide()
	
	var anim = "move" if velocity.length() > 0 else "idle"
	if BODY.animation != anim:
		BODY.play(anim)
		L_ARM_socket.play(anim)
		R_ARM_socket.play(anim)

func _perform_dash() -> void:
	is_dashing = true
	current_dashes -= 1
	dash_timer.stop() 
	
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	
	var dir = Input.get_vector("left", "right", "up", "down")
	if dir == Vector2.ZERO: dir = Vector2.from_angle(HEAD.frame * (PI/4))
	velocity = dir.normalized() * dash_speed
	
	await get_tree().create_timer(dash_duration).timeout
	
	is_dashing = false
	hitbox.set_deferred("monitoring", true)
	hitbox.set_deferred("monitorable", true)
	dash_timer.start(dash_cooldown)

func _on_dash_cooldown_finished() -> void:
	current_dashes = max_dashes

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("switch_mode"): CONTROLLER_MODE = not CONTROLLER_MODE
	_handle_aiming(delta)
	
	if velocity.length() > 0:
		HEAD.frame = posmod(int(round(velocity.angle() / (PI / 4))), 8)

	if L_ARM_part and Input.is_action_pressed("attack_left_arm"):
		L_ARM_part.attack()
	if R_ARM_part and Input.is_action_pressed("attack_right_arm"):
		R_ARM_part.attack()

	var new_target = _get_best_target()
	if new_target != active_target:
		if active_target: active_target.set_sprite_highlight(false)
		active_target = new_target
		if active_target: active_target.set_sprite_highlight(true)

	if active_target:
		var slot = request_arm_equip(active_target)
		if slot: active_target._on_equip_success(slot)

	if Input.is_action_pressed("eject") and Input.is_action_pressed("attack_left_arm") and L_ARM_part:
		AudioManager.play_effect(AudioManager.part_unequip_sfx)
		L_ARM_part.eject()
		EventManager.left_arm_unequipped.emit(L_ARM_part)
		L_ARM_part = null
	if Input.is_action_pressed("eject") and Input.is_action_pressed("attack_right_arm") and R_ARM_part:
		AudioManager.play_effect(AudioManager.part_unequip_sfx)
		R_ARM_part.eject()
		EventManager.right_arm_unequipped.emit(R_ARM_part)
		R_ARM_part = null

func request_arm_equip(part: ARMPart) -> Node2D:
	var l_req := Input.is_action_just_pressed("equip_left_arm")
	var r_req := Input.is_action_just_pressed("equip_right_arm")
	if not (l_req or r_req): return null

	if l_req and not L_ARM_part:
		AudioManager.play_effect(AudioManager.part_equip_sfx)
		L_ARM_part = part
		EventManager.left_arm_equipped.emit(L_ARM_part)
		L_ARM_part.set_collision_masks([3])
		return L_ARM
	if r_req and not R_ARM_part:
		AudioManager.play_effect(AudioManager.part_equip_sfx)
		R_ARM_part = part
		EventManager.right_arm_equipped.emit(R_ARM_part)
		R_ARM_part.set_collision_masks([3])
		return R_ARM
	part._on_equip_fail()
	return null

func _get_best_target() -> ARMPart:
	var items = pickup_area.get_overlapping_areas().filter(func(a): return a is ARMPart and not a.is_equipped)
	if items.is_empty(): return null
	if CONTROLLER_MODE:
		items.sort_custom(func(a, b): 
			return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
		)
		return items[0]
	else:
		for item in items:
			if item.is_mouse_hover: return item
		return null

func _handle_aiming(delta: float) -> void:
	var joy_dir = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var l_target = (get_global_mouse_position() - L_ARM.global_position).angle()
	var r_target = (get_global_mouse_position() - R_ARM.global_position).angle()
	if joy_dir.length() > 0.1:
		l_target = joy_dir.angle()
		r_target = l_target
	L_ARM.rotation = lerp_angle(L_ARM.rotation, l_target, rotation_speed * delta)
	R_ARM.rotation = lerp_angle(R_ARM.rotation, r_target, rotation_speed * delta)

func collect_scrap(amount: int) -> void:
	scrap_count += amount
	if scrap_count >= scrap_to_level: _level_up()
	stats_changed.emit(scrap_count, scrap_to_level, upgrade_level, L_power, R_power, health)

func _level_up() -> void:
	scrap_count -= scrap_to_level
	upgrade_level += 1
	scrap_to_level = int(scrap_to_level * 1.2)

func _on_pickup_area_area_entered(area: Area2D) -> void:
	if area is ARMPart: area.on_entered_pickup_range()

func _on_pickup_area_area_exited(area: Area2D) -> void:
	if area is ARMPart: area.on_exited_pickup_range()

func take_damage(amount: int) -> void:
	health -= amount
	stats_changed.emit(scrap_count, scrap_to_level, upgrade_level, L_power, R_power, health)
	_hit_animation()

func _hit_animation() -> void:
	var tween = create_tween()
	material.set_shader_parameter("flash_intensity", 1.0)
	tween.tween_property(material, "shader_parameter/flash_intensity", 0.0, 0.3)
