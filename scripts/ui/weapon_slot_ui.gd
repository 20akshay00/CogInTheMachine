@tool
extends Control

@export var slot_label: String = "L-ARM"
@export var max_durability: int = 3
@export var lightbulb_scene: PackedScene

func _ready() -> void:
	$DataPanels/DescriptionLabel.text = slot_label
