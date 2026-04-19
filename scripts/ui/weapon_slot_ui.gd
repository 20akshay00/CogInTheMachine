@tool
extends Control

@export var slot_label: String = "L-ARM"
@onready var bulbs_node: HBoxContainer = $EnergyDisplay/Bulbs
@onready var bulbs: Array = bulbs_node.get_children().filter(func(node): return node is LightBulbUI)

@onready var player: Player = get_tree().get_first_node_in_group("Player")
var part: ARMPart = null

func _ready() -> void:
	$DataPanels/DescriptionLabel.text = slot_label
	if slot_label == "L-ARM":
		EventManager.left_arm_equipped.connect(_on_arm_equipped)
		EventManager.left_arm_unequipped.connect(_on_arm_unequipped)
	if slot_label == "R-ARM":
		EventManager.right_arm_equipped.connect(_on_arm_equipped)
		EventManager.right_arm_unequipped.connect(_on_arm_unequipped)

	init_visuals()

func init_visuals() -> void:
	if not player: return
	
	var pwr: int = get_player_power()
				
	for i in range(bulbs.size()):
		var bulb = bulbs[i]
		bulb.set_symbol_active(false).finished
		bulb.set_light_active(i < pwr).finished

func _on_arm_equipped(p: ARMPart) -> void:
	part = p
	$WeaponDisplay.update_state(p)
	_update_display(get_player_power(), p.power)

func _on_arm_unequipped(p: ARMPart) -> void:
	part = null
	$WeaponDisplay.update_state(null)
	_update_display(get_player_power(), 0)

func _update_display(src_pwr: int, part_pwr: int) -> void:
	for i in range(bulbs.size()):
		var bulb = bulbs[i]
		
		var sym_on = i < part_pwr
		var light_on = i < src_pwr or (part_pwr > src_pwr and i < part_pwr)
		var unstable = part_pwr > src_pwr and i >= src_pwr and i < part_pwr
		bulb.set_symbol_active(sym_on).finished
		await bulb.set_light_active(light_on).finished
		await bulb.set_unstable(unstable).finished
		
func get_player_power() -> int:
	var pwr: int = 0
	
	if slot_label == "L-ARM":
		pwr = player.L_power
	if slot_label == "R-ARM":
		pwr = player.R_power
	return pwr
