extends Area2D
class_name ARMPart

var select_tween: Tween
@export var DEFAULT_COLOR := Color.WHITE
@export var INVALID_COLOR := Color.RED
@export var pivot_offset: float = 10.0
@export var power: int = 1

@export var sprite: Sprite2D
@onready var base_root_scale: Vector2 = scale
var base_sprite_scale: Vector2
var base_sprite_rot: float

@onready var power_cost_ui: PowerCostUI = $PowerCostUI

@export var is_equipped: bool = false
var can_fire: bool = false
var in_pickup_range: bool = false
var is_mouse_hover: bool = false
var is_selected: bool = false 

@export var eject_distance: float = 400.0
@export var eject_rotation_offset: float = 2 * PI
@export var eject_duration: float = 0.8
@export var damage_on_eject: int = 1
@export var damage_on_eject_overloaded: int = 3

@export var drop_base_duration: float = 0.6
@export var drop_min_dist: float = 50.
@export var drop_max_dist: float = 70.
@export var drop_min_rot: float = 0.8
@export var drop_max_rot: float = 2.0

@export var explosion_scene: PackedScene

var _is_ejecting: bool = false
var _eject_tween: Tween

var projectile_collision_mask = 0

@export var max_durability: float = 10.
@export var durability: float = max_durability
var is_overloaded: bool = false

var is_equipped_by_player: bool = false

func _ready() -> void:
	if not sprite: sprite = $Sprite2D
	base_sprite_scale = sprite.scale
	base_sprite_rot = sprite.rotation

	if sprite.material: sprite.material = sprite.material.duplicate()
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(2, true)
	input_pickable = true 
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(_delta: float) -> void:
	if is_equipped and durability <= 0 and not is_overloaded:
		_trigger_overload()

func on_entered_pickup_range() -> void:
	if is_equipped: return
	in_pickup_range = true
	_update_state()
	_play_wobble(true)

func on_exited_pickup_range() -> void:
	if is_equipped: return
	in_pickup_range = false
	_update_state()
	_play_wobble(false)

func _on_mouse_entered() -> void:
	if is_equipped: return
	is_mouse_hover = true
	_update_state()

func _on_mouse_exited() -> void:
	if is_equipped: return
	is_mouse_hover = false
	_update_state()

func _update_state() -> void:
	is_selected = in_pickup_range and is_mouse_hover and not is_equipped
	set_sprite_highlight(is_selected)

func _play_wobble(active: bool) -> void:
	if select_tween: select_tween.kill()
	select_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if active:
		select_tween.set_loops()
		select_tween.tween_property(sprite, "scale", base_sprite_scale * 1.1, 0.4)
		select_tween.parallel().tween_property(sprite, "rotation", base_sprite_rot + 0.1, 0.4)
		select_tween.tween_property(sprite, "scale", base_sprite_scale, 0.4)
		select_tween.parallel().tween_property(sprite, "rotation", base_sprite_rot - 0.1, 0.4)
	else:
		select_tween.tween_property(sprite, "scale", base_sprite_scale, 0.2)
		select_tween.parallel().tween_property(sprite, "rotation", base_sprite_rot, 0.2)

func _on_equip_fail() -> void:
	var t = create_tween()
	t.tween_property(sprite.material, "shader_parameter/line_color", INVALID_COLOR, 0.1)
	t.tween_property(sprite.material, "shader_parameter/line_color", DEFAULT_COLOR, 0.1)

func _on_equip_success(slot: Node2D) -> void:
	is_equipped_by_player = true
	is_equipped = true
	can_fire = false 
	if select_tween: select_tween.kill()
	
	_update_state()
	set_collision_layer_value(2, false)
	
	var cur_pos = global_position
	var cur_rot = global_rotation
	reparent(slot)
	
	global_position = cur_pos
	global_rotation = cur_rot
	sprite.scale = base_sprite_scale 
	sprite.rotation = base_sprite_rot
	
	var dur = 0.3
	var t = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "position", Vector2(pivot_offset, 0), dur)
	t.tween_property(self, "rotation", 0, dur)
	t.tween_property(self, "scale", base_root_scale, dur)
	t.chain().tween_callback(func(): can_fire = true)

func set_sprite_highlight(state: bool) -> void:
	if state: sprite.material.set_shader_parameter("line_color", DEFAULT_COLOR)
	sprite.material.set_shader_parameter("active", state)
	if power_cost_ui: power_cost_ui.set_state(state)

func eject() -> void:
	is_equipped = false
	can_fire = false
	input_pickable = false
	_is_ejecting = true
	
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(3, true)
	
	if not area_entered.is_connected(_on_eject_hit):
		area_entered.connect(_on_eject_hit)
	
	if select_tween: select_tween.kill()
	
	var direction = Vector2.RIGHT.rotated(global_rotation)
	var target_pos = global_position + (direction * eject_distance)
	var target_rot = sprite.rotation + eject_rotation_offset
	
	call_deferred("_reparent_to_parts_node")
	
	_eject_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_eject_tween.tween_property(self, "global_position", target_pos, eject_duration)
	_eject_tween.tween_property(sprite, "rotation", target_rot, eject_duration)
	
	_eject_tween.chain().tween_property(sprite.material, "shader_parameter/tint_color", Color(1., 1., 1., 0.), 0.2)
	_eject_tween.chain().tween_callback(queue_free)

func _on_eject_hit(area: Area2D) -> void:
	if not _is_ejecting: return
	
	if area is Hitbox:
		var dmg = damage_on_eject_overloaded if is_overloaded else damage_on_eject
		area.take_damage(dmg)
		_is_ejecting = false 
		
		if _eject_tween: _eject_tween.kill()
		
		if is_overloaded:
			var explosion = explosion_scene.instantiate()
			add_sibling(explosion)
			explosion.z_index = 100
			explosion.global_position = global_position
			explosion.explode()
			
		var t = create_tween()
		t.tween_property(sprite, "scale", base_sprite_scale * 1.2, 0.05)
		t.parallel().tween_property(sprite.material, "shader_parameter/tint_color", Color(1., 1., 1., 0.), 0.1)
		t.tween_callback(queue_free)

func drop() -> void:
	_is_ejecting = false
	if area_entered.is_connected(_on_eject_hit):
		area_entered.disconnect(_on_eject_hit)
	
	is_equipped = false
	can_fire = false
	input_pickable = true
	
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(2, true) 
	
	var target_pos = global_position + Vector2.from_angle(randf() * TAU) * randf_range(drop_min_dist, drop_max_dist)
	var rot_sign = -1.0 if randf() > 0.5 else 1.0
	var target_rot = sprite.rotation + (randf_range(drop_min_rot, drop_max_rot) * rot_sign)
	
	call_deferred("_reparent_to_parts_node")
	
	var t = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "global_position", target_pos, drop_base_duration)
	t.tween_property(sprite, "rotation", target_rot, drop_base_duration)
	
	t.tween_property(sprite, "position:y", -20.0, drop_base_duration * 0.5)
	t.chain().tween_property(sprite, "position:y", 0.0, drop_base_duration * 0.5).set_ease(Tween.EASE_IN)
	
	t.chain().tween_property(sprite, "scale", Vector2(base_sprite_scale.x * 1.3, base_sprite_scale.y * 0.7), drop_base_duration * 0.125)
	t.tween_property(sprite, "scale", base_sprite_scale, drop_base_duration * 0.25)
	t.finished.connect(_update_state)

func _reparent_to_parts_node() -> void:
	var parts_node = get_tree().current_scene.get_node_or_null("Parts")
	if parts_node:
		var cur_pos = global_position
		reparent(parts_node)
		global_position = cur_pos
		rotation = 0

func _trigger_overload() -> void:
	is_overloaded = true
	can_fire = false
	var t = create_tween().set_loops()
	t.tween_property(sprite.material, "shader_parameter/tint_color", INVALID_COLOR, 0.2)
	t.tween_property(sprite.material, "shader_parameter/tint_color", DEFAULT_COLOR, 0.2)

func attack() -> void:
	pass

func set_collision_masks(arr: Array[int]) -> void:
	var mask = 0
	for layer in arr:
		mask |= (1 << (layer - 1))
		
	projectile_collision_mask = mask
