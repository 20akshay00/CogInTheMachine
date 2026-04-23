extends CharacterBody2D
class_name ScrapBot

enum AttackPattern { STRAIGHT, FAN, BURST, CIRCLE }

@export_group("Bot Settings")
@export_range(0, 3) var variant: int = 0
@export var pattern: AttackPattern = AttackPattern.STRAIGHT
@export var health: int = 3
@export var speed: float = 120.0
@export var stop_distance: float = 250.0
@export var walk_animation_speed: float = 10.0

@export_group("Combat")
@export var projectile_scene: PackedScene
@export var scrap_scene: PackedScene
@export var projectile_speed: float = 600.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var player: Player = get_tree().get_first_node_in_group("Player")

var _walk_anim_timer: float = 0.0
var _step_timer: float = 0.0
var _fire_timer: float = 2.0
var _is_stepping: bool = false
var _scurry_dir: Vector2 = Vector2.ZERO
var _is_dying: bool = false
var projectile_collision_mask: int = 0

func _ready() -> void:
	if sprite.material: sprite.material = sprite.material.duplicate()
	projectile_collision_mask |= (1 << 5)
	variant = randi_range(0, 3)
	pattern = AttackPattern.values().pick_random()
	sprite.frame = variant * 9
	
	_fire_timer = randf_range(0.5, 4.0)
	_step_timer = randf_range(0.0, 1.0)

func _physics_process(delta: float) -> void:
	if not player or _is_dying: return
	_handle_robotic_movement(delta)
	_handle_shooting(delta)
	_play_walk_animation(delta)

func _handle_robotic_movement(delta: float) -> void:
	_step_timer -= delta
	var dist = global_position.distance_to(player.global_position)
	if _step_timer <= 0:
		_is_stepping = !_is_stepping
		_step_timer = randf_range(0.5, 1.2) if _is_stepping else randf_range(0.2, 0.5)
		if _is_stepping and dist <= stop_distance:
			var to_player = global_position.direction_to(player.global_position)
			_scurry_dir = to_player.rotated(randf_range(PI/3, PI) * (1 if randf() > 0.5 else -1))
	if _is_stepping:
		velocity = (global_position.direction_to(player.global_position) if dist > stop_distance else _scurry_dir) * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * 6 * delta)
	move_and_slide()

func _handle_shooting(delta: float) -> void:
	_fire_timer -= delta
	if _fire_timer <= 0:
		_fire_timer = randf_range(2.0, 5.0)
		_shoot()

func _shoot() -> void:
	if not projectile_scene or not player: return
	match pattern:
		AttackPattern.STRAIGHT: _spawn_projectile(0)
		AttackPattern.FAN:
			for angle in [-25, 0, 25]: _spawn_projectile(deg_to_rad(angle))
		AttackPattern.BURST:
			for i in range(3):
				if _is_dying: break
				_spawn_projectile(randf_range(-0.1, 0.1))
				await get_tree().create_timer(0.12).timeout
		AttackPattern.CIRCLE:
			for i in range(8): _spawn_projectile(i * (TAU / 8))

func _spawn_projectile(angle_offset: float) -> void:
	var p = projectile_scene.instantiate()
	p.collision_mask = projectile_collision_mask
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	var to_player = global_position.direction_to(player.global_position).angle()
	p.global_rotation = to_player + angle_offset
	if "speed" in p: p.speed = projectile_speed

func _play_walk_animation(delta: float) -> void:
	var col = 0
	if velocity.length() > 10.0:
		_walk_anim_timer += delta * walk_animation_speed
		col = int(_walk_anim_timer) % 3
	else:
		col = 0
		_walk_anim_timer = 0.0
	sprite.frame = (variant * 9) + col	

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
	$Hitbox.set_deferred("monitorable", false)
	await _play_death_animation()
	if scrap_scene:
		var s = scrap_scene.instantiate()
		get_tree().current_scene.get_node("Scraps").add_child(s)
		s.global_position = global_position
	queue_free()

func _play_death_animation() -> void:
	for i in range(3, 9):
		sprite.frame = (variant * 9) + i
		await get_tree().create_timer(0.1).timeout
