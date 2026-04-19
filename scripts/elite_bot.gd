extends CharacterBody2D
class_name EliteBot

@export var health: int = 3
@export var speed: float = 150.0
@export var rotation_speed: float = 5.0
@export var change_dir_time: float = 1.0

@onready var L_ARM: Node2D = $"L-ARM"
@onready var R_ARM: Node2D = $"R-ARM"
@onready var HEAD: Sprite2D = $Head
@onready var BODY: AnimatedSprite2D = $Body
@onready var L_ARM_socket: AnimatedSprite2D = $"L-ARM Socket"
@onready var R_ARM_socket: AnimatedSprite2D = $"R-ARM Socket"

var L_ARM_part: ARMPart = null
var R_ARM_part: ARMPart = null
var is_dead: bool = false
var move_dir: Vector2 = Vector2.ZERO
var dir_timer: float = 0.0

@export var explosion_scene: PackedScene

func _ready() -> void:
	_initialize_arms()

func _initialize_arms() -> void:
	for child in L_ARM.get_children():
		if child is ARMPart:
			L_ARM_part = child
			L_ARM_part.is_equipped = true
			L_ARM_part.can_fire = true
			L_ARM_part.set_collision_masks([6])

	for child in R_ARM.get_children():
		if child is ARMPart:
			R_ARM_part = child
			R_ARM_part.is_equipped = true
			R_ARM_part.can_fire = true
			R_ARM_part.set_collision_masks([6])

func _physics_process(delta: float) -> void:
	if is_dead: return
	
	dir_timer -= delta
	if dir_timer <= 0:
		move_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		dir_timer = randf_range(0.5, change_dir_time)
	
	velocity = move_dir * speed
	move_and_slide()
	
	if velocity.length() > 0:
		HEAD.frame = posmod(int(round(velocity.angle() / (PI / 4))), 8)
		
	var anim = "move" if velocity.length() > 0 else "idle"
	if BODY.animation != anim:
		BODY.play(anim)
		L_ARM_socket.play(anim)
		R_ARM_socket.play(anim)

func _process(delta: float) -> void:
	if is_dead: return
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.is_empty(): return
	
	var target_player = players[0]
	var to_player = (target_player.global_position - global_position).angle()
	
	L_ARM.rotation = lerp_angle(L_ARM.rotation, to_player, rotation_speed * delta)
	R_ARM.rotation = lerp_angle(R_ARM.rotation, to_player, rotation_speed * delta)
	
	if L_ARM_part: L_ARM_part.attack()
	if R_ARM_part: R_ARM_part.attack()

func take_damage(amount: int) -> void:
	if is_dead: return
	health -= amount
	_hit_animation()
	if health <= 0:
		die()

func _hit_animation() -> void:
	var tween = create_tween()
	material.set_shader_parameter("flash_intensity", 1.0)
	tween.tween_property(material, "shader_parameter/flash_intensity", 0.0, 0.3)

func die() -> void:
	is_dead = true
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	var explosion = explosion_scene.instantiate()
	add_sibling(explosion)
	explosion.z_index = 100
	explosion.global_position = global_position
	explosion.explode()
	
	if L_ARM_part: 
		L_ARM_part.drop()
		L_ARM_part = null
	if R_ARM_part: 
		R_ARM_part.drop()
		R_ARM_part = null
		
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)
