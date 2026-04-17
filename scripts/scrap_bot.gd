extends CharacterBody2D
class_name ScrapBot

@export_range(0, 2) var variant: int = 0
@export var speed: float = 120.0
@export var stop_distance: float = 250.0
@export var walk_animation_speed: float = 10.0
@export var health: int = 3

@export var projectile_scene: PackedScene
@export var scrap_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var player: Player = get_tree().get_first_node_in_group("Player")

var _walk_anim_timer: float = 0.0
var _step_timer: float = 0.0
var _fire_timer: float = 2.0
var _is_stepping: bool = false
var _scurry_dir: Vector2 = Vector2.ZERO
var _is_dying: bool = false # FIXED: Was true in your snippet

func _physics_process(delta: float) -> void:
	if not player or _is_dying: return # FIXED: Guard added
	
	_handle_robotic_movement(delta)
	_handle_shooting(delta)
	_play_walk_animation(delta)

func _handle_robotic_movement(delta: float) -> void:
	_step_timer -= delta
	var dist = global_position.distance_to(player.global_position)
	
	if _step_timer <= 0:
		_is_stepping = !_is_stepping
		_step_timer = randf_range(0.5, 1.0) if _is_stepping else 0.3
		
		if _is_stepping and dist <= stop_distance:
			var to_player = global_position.direction_to(player.global_position)
			var angle_offset = randf_range(PI/3, PI) * (1 if randf() > 0.5 else -1)
			_scurry_dir = to_player.rotated(angle_offset)

	if _is_stepping:
		if dist > stop_distance:
			velocity = global_position.direction_to(player.global_position) * speed
		else:
			velocity = _scurry_dir * (speed * 0.8)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 6 * delta)
		
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0:
		_fire_timer = randf_range(2.0, 4.0)
		_shoot()

func _shoot() -> void:
	if not projectile_scene: return
	var p = projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	p.global_rotation = global_position.direction_to(player.global_position).angle()
	if "speed" in p: p.speed = 350.0

func _play_walk_animation(delta: float) -> void:
	var col: int = 0
	if velocity.length() > 10.0:
		_walk_anim_timer += delta * walk_animation_speed
		col = 1 + (int(_walk_anim_timer) % 3)
	else:
		col = 0
		_walk_anim_timer = 0.0

	sprite.frame = (variant * sprite.hframes) + col

func take_damage(amount: int) -> void:
	if _is_dying: return
	health -= amount
	_hit_animation()
	if health <= 0: _die()

func _hit_animation() -> void:
	var tween = create_tween()
	sprite.material.set_shader_parameter("flash_intensity", 1.0)
	tween.tween_property(sprite.material, "shader_parameter/flash_intensity", 0.0, 0.3)

func _die() -> void:
	_is_dying = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	
	await _play_death_animation()
	
	if scrap_scene:
		var s = scrap_scene.instantiate()
		get_tree().current_scene.get_node("Scraps").add_child(s)
		s.global_position = global_position
		
	queue_free()

func _play_death_animation() -> void:
	for i in range(3, 9):
		sprite.frame = (variant * sprite.hframes) + i
		await get_tree().create_timer(0.2).timeout
