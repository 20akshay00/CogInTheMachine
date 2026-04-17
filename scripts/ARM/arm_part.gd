extends Area2D
class_name ARMPart

var select_tween: Tween

@export var DEFAULT_COLOR := Color.WHITE
@export var INVALID_COLOR := Color.RED

@onready var sprite: Sprite2D = $Sprite2D
# assumes sprite has highlight shader!

@onready var base_sprite_scale := sprite.scale
@onready var base_sprite_rot := sprite.rotation

@export var pivot_offset: float = 10.

@export var power: int = 1
@export var damage: int = 1
@export var max_durability: int = 5:
	set(value):
		max_durability = value
		durability = value

var durability: int = max_durability:
	set(value):
		durability = clamp(value, 0, max_durability)
		if durability <= 0:
			_destroy_part()

var is_equipped: bool = false
var in_pickup_range: bool = false;
var is_selected: bool = false;
var is_mouse_hover: bool = false;

var just_equipped: bool = false; # I hate this but its the quickest fix

func _pre_ready() -> void:
	if sprite.material: sprite.material = sprite.material.duplicate()
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	set_collision_layer_value(2, true)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _pre_process(delta: float) -> void:
	if is_selected and not is_equipped:
		if Input.is_action_just_pressed("equip_left_arm"):
			var player = get_tree().get_first_node_in_group("Player") as Player
			var equip_slot = player.request_arm_equip(self)
			if equip_slot:
				_on_equip_success(equip_slot)
			else:
				_on_equip_fail()

func _take_damage(val: int) -> void:
	durability -= val

func _destroy_part():
	pass

func _toggle_state():
	# 1. Disable/Enable the Pickup Area
	set_collision_layer_value(2, false)
	set_collision_layer_value(1, true)
	# 2. Disable/Enable the Weapon Hitboxes
	# 3. Change Collision Layers (Player Layer vs Item Layer)
	# 4. Stop/Start "Glow" animations for items on ground
	set_process(is_equipped) # Only run weapon logic if equipped

func on_entered_pickup_range() -> void:
	if is_equipped: return
	in_pickup_range = true
	if is_mouse_hover: _on_mouse_entered()

	if select_tween: select_tween.kill()
	select_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	select_tween.tween_property(sprite, "scale", base_sprite_scale * 1.1, 0.4)
	select_tween.parallel().tween_property(sprite, "rotation", base_sprite_rot + 0.1, 0.4)
	
	select_tween.tween_property(sprite, "scale", base_sprite_scale, 0.4)
	select_tween.parallel().tween_property(sprite, "rotation", base_sprite_rot - 0.1, 0.4)

func on_exited_pickup_range() -> void:
	if is_equipped: return
	in_pickup_range = false
	_on_mouse_exited()
	if select_tween: select_tween.kill()
	select_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	select_tween.tween_property(sprite, "scale", base_sprite_scale, 0.2)
	select_tween.parallel().tween_property(sprite, "rotation", base_sprite_rot, 0.2)

func set_sprite_highlight(state: bool, color: Color = DEFAULT_COLOR) -> void:
	sprite.material.set_shader_parameter("line_color", color)
	sprite.material.set_shader_parameter("active", state)

func _on_mouse_entered() -> void:
	if is_equipped: return
	is_mouse_hover = true
	if in_pickup_range:
		set_sprite_highlight(true)
		is_selected = true

func _on_mouse_exited() -> void:
	if is_equipped: return
	is_mouse_hover = false
	is_selected = false
	set_sprite_highlight(false)

func _on_equip_fail() -> void:
	is_equipped = false
	var mat = sprite.material
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "shader_parameter/line_color", INVALID_COLOR, 0.15)
	tween.tween_property(mat, "shader_parameter/line_color", DEFAULT_COLOR, 0.15)

func _on_equip_success(slot: Node2D) -> void:
	is_equipped = true
	just_equipped = true
	
	if select_tween: select_tween.kill()
	# capture current global state before reparenting
	var current_global_pos = global_position
	var current_global_rot = global_rotation
	
	# reset states
	is_mouse_hover = false
	is_selected = false
	set_sprite_highlight(false)
	
	# move to the new parent
	get_parent().remove_child(self)
	slot.add_child(self)
	
	# reset global transform so it doesn't "jump" visually
	sprite.scale = Vector2(1., 1.)
	global_position = current_global_pos
	global_position.y += pivot_offset
	global_rotation = current_global_rot
	
	# tween to local zero
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	var target_pivot = Vector2(pivot_offset, 0)
	tween.tween_property(self, "position", target_pivot, 0.45)
	tween.tween_property(self, "rotation", 0, 0.45)
	tween.tween_property(self, "scale", base_sprite_scale, 0.45)
	tween.tween_callback(func(): just_equipped = false)
